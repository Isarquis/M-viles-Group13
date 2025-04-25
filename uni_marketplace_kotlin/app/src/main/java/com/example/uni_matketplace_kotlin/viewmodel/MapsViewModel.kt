package com.example.uni_matketplace_kotlin.viewmodel

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.uni_matketplace_kotlin.data.repositories.ProductRepository
import com.example.uni_matketplace_kotlin.data.repositories.UserRepository
import com.example.uni_matketplace_kotlin.data.remote.entities.Product
import com.example.uni_matketplace_kotlin.data.remote.entities.User
import com.google.android.gms.maps.model.LatLng
import kotlinx.coroutines.launch

class MapsViewModel(
    private val userRepository: UserRepository,
    private val productRepository: ProductRepository
) : ViewModel() {

    private val _nearbyUsers = MutableLiveData<List<User>>()
    val nearbyUsers: LiveData<List<User>> get() = _nearbyUsers

    private val _closestUser = MutableLiveData<User?>()
    val closestUser: LiveData<User?> get() = _closestUser

    private val _closestProduct = MutableLiveData<Product?>()
    val closestProduct: LiveData<Product?> get() = _closestProduct

    private val _distanceToClosestUser = MutableLiveData<Double>()
    val distanceToClosestUser: LiveData<Double> get() = _distanceToClosestUser

    private val _errorMessage = MutableLiveData<String>()
    val errorMessage: LiveData<String> get() = _errorMessage

    fun loadNearbyUsers(currentLocation: LatLng) {
        viewModelScope.launch {
            try {
                val users = userRepository.getUsersNearby(currentLocation, maxDistance = 400f)
                _nearbyUsers.postValue(users)
            } catch (e: Exception) {
                _errorMessage.postValue("Error loading nearby users: ${e.message}")
            }
        }
    }

    fun loadClosestProduct(currentLocation: LatLng) {
        viewModelScope.launch {
            // Aquí va la lógica para cargar el producto más cercano
            val closestProduct = productRepository.getClosestProduct(currentLocation)
            _closestProduct.postValue(closestProduct)
        }
    }

    fun loadClosestUser(currentLocation: LatLng) {
        viewModelScope.launch {
            val closestUser = userRepository.getClosestUser(currentLocation)
            _closestUser.postValue(closestUser)
        }
    }
}
