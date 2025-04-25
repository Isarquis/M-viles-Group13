package com.example.uni_matketplace_kotlin.ui.createproduct

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.google.firebase.firestore.FirebaseFirestore

class CreateProductViewModelFactory(
    private val db: FirebaseFirestore
) : ViewModelProvider.Factory {

    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        if (modelClass.isAssignableFrom(CreateProductViewModel::class.java)) {
            return CreateProductViewModel(db) as T
        }
        throw IllegalArgumentException("Unknown ViewModel class")
    }
}
