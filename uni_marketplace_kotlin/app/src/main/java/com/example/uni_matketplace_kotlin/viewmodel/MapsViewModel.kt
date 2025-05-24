package com.example.uni_matketplace_kotlin.viewmodel

import android.util.Log
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

    companion object {
        private const val TAG = "MapsViewModel"
    }

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

    private val _isLoading = MutableLiveData<Boolean>()
    val isLoading: LiveData<Boolean> get() = _isLoading

    fun loadNearbyUsers(currentLocation: LatLng) {
        viewModelScope.launch {
            try {
                Log.d(TAG, "Loading nearby users for location: ${currentLocation.latitude}, ${currentLocation.longitude}")
                _isLoading.postValue(true)

                val users = userRepository.getUsersNearby(currentLocation, maxDistance = 400f)
                _nearbyUsers.postValue(users)

                Log.d(TAG, "Found ${users.size} nearby users")

            } catch (e: Exception) {
                Log.e(TAG, "Error loading nearby users: ${e.message}", e)
                _errorMessage.postValue("Error loading nearby users: ${e.message}")
                _nearbyUsers.postValue(emptyList())
            } finally {
                _isLoading.postValue(false)
            }
        }
    }

    fun loadClosestProduct(currentLocation: LatLng) {
        viewModelScope.launch {
            try {
                Log.d(TAG, "Loading closest product for location: ${currentLocation.latitude}, ${currentLocation.longitude}")
                _isLoading.postValue(true)

                val closestProduct = productRepository.getClosestProduct(currentLocation)
                _closestProduct.postValue(closestProduct)

                if (closestProduct != null) {
                    Log.d(TAG, "Found closest product: ${closestProduct.title}")
                } else {
                    Log.d(TAG, "No closest product found")
                }

            } catch (e: Exception) {
                Log.e(TAG, "Error loading closest product: ${e.message}", e)
                _errorMessage.postValue("Error loading closest product: ${e.message}")
                _closestProduct.postValue(null)
            } finally {
                _isLoading.postValue(false)
            }
        }
    }

    fun loadClosestUser(currentLocation: LatLng) {
        viewModelScope.launch {
            try {
                Log.d(TAG, "Loading closest user for location: ${currentLocation.latitude}, ${currentLocation.longitude}")
                _isLoading.postValue(true)

                val closestUser = userRepository.getClosestUser(currentLocation)
                _closestUser.postValue(closestUser)

                if (closestUser != null) {
                    Log.d(TAG, "Found closest user: ${closestUser.name}")
                } else {
                    Log.d(TAG, "No closest user found")
                }

            } catch (e: Exception) {
                Log.e(TAG, "Error loading closest user: ${e.message}", e)
                _errorMessage.postValue("Error loading closest user: ${e.message}")
                _closestUser.postValue(null)
            } finally {
                _isLoading.postValue(false)
            }
        }
    }

    fun clearError() {
        _errorMessage.postValue("")
    }

    override fun onCleared() {
        super.onCleared()
        Log.d(TAG, "MapsViewModel cleared")
    }
}