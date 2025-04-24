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

    fun loadClosestProduct(currentLocation: LatLng, maxDistance: Float = 400f) {
        viewModelScope.launch {
            val result = userRepository.getClosestUserWithProduct(currentLocation, maxDistance, productRepository)

            result?.let { (user, distance, product) ->
                _closestUser.value = user
                _closestProduct.value = product
                _distanceToClosestUser.value = distance
            } ?: run {
                _closestUser.value = null
                _closestProduct.value = null
                _distanceToClosestUser.value = null
            }
        }
    }

    fun loadNearbyUsers(currentLocation: LatLng, maxDistance: Float = 400f) {
        viewModelScope.launch {
            val nearbyUsersWithProducts = userRepository.getNearbyUsersWithProducts(currentLocation, maxDistance, productRepository)
            _nearbyUsers.postValue(nearbyUsersWithProducts)
        }
    }

    private fun calculateDistance(start: LatLng, end: LatLng): Float {
        val results = FloatArray(1)
        Location.distanceBetween(start.latitude, start.longitude, end.latitude, end.longitude, results)
        return results[0]
    }
}
