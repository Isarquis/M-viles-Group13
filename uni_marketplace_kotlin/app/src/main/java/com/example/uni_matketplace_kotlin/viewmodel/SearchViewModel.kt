package com.example.uni_marketplace_kotlin.ui.search

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.uni_matketplace_kotlin.data.remote.entities.Product
import com.example.uni_matketplace_kotlin.data.repositories.ProductRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class SearchViewModel(
    private val productRepository: ProductRepository
) : ViewModel() {

    private val _products = MutableStateFlow<List<Product>>(emptyList())
    val products: StateFlow<List<Product>> = _products

    private val _filteredProducts = MutableStateFlow<List<Product>>(emptyList())
    val filteredProducts: StateFlow<List<Product>> = _filteredProducts

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading

    init {
        loadAllProducts()
    }

    private fun loadAllProducts() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val allProducts = productRepository.getClosestProductProductsList()
                _products.value = allProducts
                _filteredProducts.value = allProducts
            } catch (e: Exception) {
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun searchProducts(query: String) {
        val lowercaseQuery = query.trim().lowercase()
        _filteredProducts.value = if (lowercaseQuery.isEmpty()) {
            _products.value
        } else {
            _products.value.filter { product ->
                product.title?.lowercase()?.contains(lowercaseQuery) == true ||
                        product.description?.lowercase()?.contains(lowercaseQuery) == true
            }
        }
    }

    fun filterByType(type: String) {
        _filteredProducts.value = _products.value.filter { it.type.equals(type) }
    }
}
