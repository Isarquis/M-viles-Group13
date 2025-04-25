package com.example.uni_matketplace_kotlin.ui.createproduct

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import com.google.firebase.firestore.FirebaseFirestore

class CreateProductViewModel(private val db: FirebaseFirestore) : ViewModel() {

    private val _isFormValid = MutableLiveData(false)
    val isFormValid: LiveData<Boolean> = _isFormValid

    fun validateForm(title: String, description: String, category: String, price: String, types: List<String>) {
        _isFormValid.value =
            title.isNotBlank() &&
                    description.isNotBlank() &&
                    category.isNotBlank() &&
                    price.toIntOrNull() != null &&
                    types.isNotEmpty()
    }

    fun createProduct(
        title: String,
        description: String,
        category: String,
        price: Int,
        types: List<String>,
        ownerId: String,
        onSuccess: () -> Unit,
        onFailure: (Exception) -> Unit
    ) {
        val product = hashMapOf(
            "title" to title,
            "description" to description,
            "category" to category,
            "price" to price,
            "types" to types,
            "ownerId" to ownerId
        )

        db.collection("products")
            .add(product)
            .addOnSuccessListener { onSuccess() }
            .addOnFailureListener { onFailure(it) }
    }
}
