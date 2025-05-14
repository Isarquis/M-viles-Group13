package com.example.uni_matketplace_kotlin.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.viewModelScope
import com.example.uni_matketplace_kotlin.data.remote.entities.Product
import com.example.uni_matketplace_kotlin.data.repositories.ProductRepository
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import javax.inject.Inject

@HiltViewModel
class SearchViewModel @Inject constructor(
    application: Application,
    private val productRepository: ProductRepository
) : AndroidViewModel(application) {

    private val firestore = FirebaseFirestore.getInstance()

    private val _products = MutableLiveData<List<Product>>()
    val products: LiveData<List<Product>> = _products

    private val _loading = MutableLiveData<Boolean>()
    val loading: LiveData<Boolean> = _loading

    private val _error = MutableLiveData<String?>()
    val error: LiveData<String?> = _error

    private val _firstProducts = MutableLiveData<List<Product>>()
    val firstProducts: LiveData<List<Product>> = _firstProducts

    fun loadProductsByType(type: String) {
        viewModelScope.launch {
            _loading.value = true
            _error.value = null
            try {
                val result = if (InternetHelper.isInternetAvailable(getApplication())) {
                    productRepository.getFilteredProducts(type, null) // Firebase
                } else {
                    productRepository.getFilteredLocalProducts(type)  // Local Room con flags
                }
                _products.value = result
            } catch (e: Exception) {
                _error.value = "Error al cargar productos: ${e.message}"
                _products.value = emptyList()
            } finally {
                _loading.value = false
            }
        }
    }


    fun loadFirstProducts() {
        viewModelScope.launch {
            _loading.value = true
            try {
                val result = if (InternetHelper.isInternetAvailable(getApplication())) {
                    productRepository.getFirstProducts()
                } else {
                    productRepository.getLocalProducts()
                }
                _products.postValue(result)
            } catch (e: Exception) {
                _error.value = "Error al cargar productos: ${e.message}"
            } finally {
                _loading.value = false
            }
        }
    }

    fun loadLocalProducts() {
        viewModelScope.launch {
            _loading.value = true
            try {
                val localProducts = withContext(Dispatchers.IO) {
                    productRepository.getLocalProducts() // Obtener productos de Room
                }
                _products.postValue(localProducts)
            } catch (e: Exception) {
                _error.postValue("Error al cargar productos locales: ${e.message}")
                _products.postValue(emptyList())
            } finally {
                _loading.postValue(false)
            }
        }
    }


    fun incrementClickCounter(attribute: String) {
        val validAttributes = listOf("description", "image", "price", "title")
        if (attribute in validAttributes) {
            firestore.collection("Click-logs")
                .document("MainLog")
                .update(attribute, FieldValue.increment(1))
                .addOnFailureListener { e ->
                    _error.postValue("Error al registrar click: ${e.message}")
                }
        }
    }

    fun loadAndSaveProducts() {
        viewModelScope.launch {
            val firebaseProducts = withContext(Dispatchers.IO) {
                productRepository.getAllProducts()
            }
            withContext(Dispatchers.IO) {
                productRepository.saveProductsToLocal(firebaseProducts)
            }
            _products.postValue(firebaseProducts)
        }
    }

    fun clearError() {
        _error.value = null
    }
}
