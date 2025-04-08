package com.example.uni_matketplace_kotlin.viewmodel

import android.location.Location
import android.util.Log
import androidx.lifecycle.*
import com.example.uni_matketplace_kotlin.data.model.Product
import com.example.uni_matketplace_kotlin.data.model.User
import com.example.uni_matketplace_kotlin.data.repositories.ProductRepository
import com.example.uni_matketplace_kotlin.data.repositories.UserRepository
import com.google.android.gms.maps.model.LatLng
import com.google.firebase.firestore.GeoPoint
import kotlinx.coroutines.launch

class MapsViewModel(
    private val userRepository: UserRepository = UserRepository(),
    private val productRepository: ProductRepository = ProductRepository()
) : ViewModel() {

    private val _closestProduct = MutableLiveData<Product?>()
    val closestProduct: LiveData<Product?> = _closestProduct

    private val _closestUser = MutableLiveData<User?>()
    val closestUser: LiveData<User?> = _closestUser

    fun loadClosestProduct(currentLocation: LatLng, maxDistance: Float = 400f) {
        Log.d("MapsViewModel", "Loading closest product...")
        viewModelScope.launch {
            val users = userRepository.getAllUsers()

            val closestUserWithDistance = users
                .mapNotNull { user ->
                    val userLatLng = user.location?.let { LatLng(it.latitude, it.longitude) }
                    if (userLatLng != null) {
                        val distance = calculateDistance(currentLocation, userLatLng)
                        if (distance <= maxDistance) Pair(user, distance) else null
                    } else null
                }
                .minByOrNull { it.second }

            val closestUser = closestUserWithDistance?.first
            _closestUser.value = closestUser

            if (closestUser != null) {
                val products = productRepository.getProductsByUserId(closestUser.id)
                _closestProduct.value = products.firstOrNull()
            } else {
                _closestProduct.value = null
            }
        }
    }

    private fun calculateDistance(start: LatLng, end: LatLng): Float {
        val results = FloatArray(1)
        Location.distanceBetween(
            start.latitude, start.longitude,
            end.latitude, end.longitude,
            results
        )
        return results[0]
    }
}
