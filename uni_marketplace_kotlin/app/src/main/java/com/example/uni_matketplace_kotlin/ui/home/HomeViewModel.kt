package com.example.uni_matketplace_kotlin.ui.home

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.viewModelScope
import com.example.uni_matketplace_kotlin.data.remote.entities.Product
import com.example.uni_matketplace_kotlin.data.repositories.ProductRepository
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import javax.inject.Inject

@HiltViewModel
class HomeViewModel @Inject constructor(
    application: Application,
    private val productRepository: ProductRepository
) : AndroidViewModel(application) {

    private val firestore = FirebaseFirestore.getInstance()

    private val _allProducts = MutableLiveData<List<Product>>()
    val allProducts: LiveData<List<Product>> = _allProducts

    private val _recommendedProducts = MutableLiveData<List<Product>>()
    val recommendedProducts: LiveData<List<Product>> = _recommendedProducts

    private val _recentProducts = MutableLiveData<List<Product>>()
    val recentProducts: LiveData<List<Product>> = _recentProducts

    private val _loading = MutableLiveData<Boolean>()
    val loading: LiveData<Boolean> = _loading

    private val _error = MutableLiveData<String?>()
    val error: LiveData<String?> = _error

    private val _isOffline = MutableLiveData<Boolean>()
    val isOffline: LiveData<Boolean> = _isOffline

    fun loadProductsFromFirebase() {
        viewModelScope.launch {
            _loading.value = true
            _error.value = null
            try {
                val result = if (InternetHelper.isInternetAvailable(getApplication())) {
                    // Load from Firebase and save locally
                    val products = withContext(Dispatchers.IO) {
                        productRepository.getAllProducts()
                    }
                    // Save to local database
                    withContext(Dispatchers.IO) {
                        productRepository.saveProductsToLocal(products)
                    }
                    _isOffline.value = false
                    products
                } else {
                    // Load from local database
                    _isOffline.value = true
                    withContext(Dispatchers.IO) {
                        productRepository.getLocalProducts()
                    }
                }

                _allProducts.value = result
                updateRecommendations(result)
                updateRecentProducts(result)

            } catch (e: Exception) {
                _error.value = "Error loading products: ${e.message}"
                // Try to load local products as fallback
                loadCachedProducts()
            } finally {
                _loading.value = false
            }
        }
    }

    fun loadCachedProducts() {
        viewModelScope.launch {
            _loading.value = true
            try {
                val localProducts = withContext(Dispatchers.IO) {
                    productRepository.getLocalProducts()
                }
                _allProducts.value = localProducts
                _isOffline.value = true
                updateRecommendations(localProducts)
                updateRecentProducts(localProducts)
            } catch (e: Exception) {
                _error.value = "Error loading local products: ${e.message}"
                _allProducts.value = emptyList()
            } finally {
                _loading.value = false
            }
        }
    }

    private fun updateRecommendations(products: List<Product>) {
        // Simple recommendation logic - most recent or random products
        val recommended = products
            .shuffled()
            .take(10)
        _recommendedProducts.value = recommended
    }

    private fun updateRecentProducts(products: List<Product>) {
        val recent = products
            .sortedByDescending { it.createdAt }
            .take(10)
        _recentProducts.value = recent
    }

    fun incrementClickCounter(attribute: String) {
        val validAttributes = listOf("description", "image", "price", "title", "category")
        if (attribute in validAttributes) {
            firestore.collection("Click-logs")
                .document("MainLog")
                .update(attribute, FieldValue.increment(1))
                .addOnFailureListener { e ->
                    _error.value = "Error recording click: ${e.message}"
                }
        }
    }

    fun refreshProducts() {
        loadProductsFromFirebase()
    }

    fun clearError() {
        _error.value = null
    }
}