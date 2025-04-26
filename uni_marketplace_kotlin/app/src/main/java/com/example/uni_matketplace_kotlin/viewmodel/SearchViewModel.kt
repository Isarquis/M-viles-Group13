package com.example.uni_matketplace_kotlin.ui.viewmodel

import android.app.Application
import androidx.lifecycle.*
import com.example.uni_matketplace_kotlin.data.remote.entities.Product
import com.example.uni_matketplace_kotlin.data.repositories.ProductRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class SearchViewModel @Inject constructor(
    application: Application,
    private val productRepository: ProductRepository
) : AndroidViewModel(application) {

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
                val result = productRepository.getFilteredProducts(type)
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
            val products = productRepository.getClosestProductProductsList()
            _firstProducts.postValue(products)
        }
    }

    fun clearError() {
        _error.value = null
    }
}
