package com.example.uni_matketplace_kotlin.viewmodel

import android.location.Location
import androidx.lifecycle.*
import com.example.uni_matketplace_kotlin.data.model.Product
import com.example.uni_matketplace_kotlin.data.model.User
import com.example.uni_matketplace_kotlin.data.repositories.ProductRepository
import com.example.uni_matketplace_kotlin.data.repositories.UserRepository
import com.google.android.gms.maps.model.LatLng
import kotlinx.coroutines.launch

class MapsViewModel(
    private val userRepository: UserRepository = UserRepository(),
    private val productRepository: ProductRepository = ProductRepository()
) : ViewModel() {

    private val _closestProduct = MutableLiveData<Product?>()
    val closestProduct: LiveData<Product?> = _closestProduct

    private val _closestUser = MutableLiveData<User?>()
    val closestUser: LiveData<User?> = _closestUser

    private val _nearbyUsers = MutableLiveData<List<User>>()
    val nearbyUsers: LiveData<List<User>> = _nearbyUsers

    private val _distanceToClosestUser = MutableLiveData<Float>()
    val distanceToClosestUser: LiveData<Float> = _distanceToClosestUser


    fun loadClosestProduct(currentLocation: LatLng, maxDistance: Float = 2000f) {
        viewModelScope.launch {
            val users = userRepository.getAllUsers()

            val closestUserWithDistance = users
                .filter { it.location?.latitude != null && it.location.longitude != null }
                .mapNotNull { user ->
                    val distance = calculateDistance(currentLocation, LatLng(user.location.latitude!!, user.location.longitude!!))
                    if (distance <= maxDistance) user to distance else null
                }
                .minByOrNull { it.second }

            val closestUser = closestUserWithDistance?.first
            val distance = closestUserWithDistance?.second ?: 0f

            _closestUser.value = closestUser
            _distanceToClosestUser.value = distance


            if (closestUser != null) {
                val products = productRepository.getProductsByUserId(closestUser.id)
                _closestProduct.value = products.firstOrNull()
            } else {
                _closestProduct.value = null
            }
        }
    }

    fun loadNearbyUsers(currentLocation: LatLng, maxDistance: Float = 2000f) {
        viewModelScope.launch {
            val users = userRepository.getAllUsers()
            val nearby = users.filter { user ->
                user.location != null &&
                        calculateDistance(currentLocation, LatLng(user.location.latitude!!, user.location.longitude!!)) <= maxDistance
            }
            _nearbyUsers.postValue(nearby)
        }
    }

    private fun calculateDistance(start: LatLng, end: LatLng): Float {
        val results = FloatArray(1)
        Location.distanceBetween(start.latitude, start.longitude, end.latitude, end.longitude, results)
        return results[0]
    }
}