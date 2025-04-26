package com.example.uni_matketplace_kotlin.viewmodel

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.example.uni_matketplace_kotlin.data.local.AppDatabase
import com.example.uni_matketplace_kotlin.data.repositories.ProductRepository
import com.example.uni_matketplace_kotlin.data.repositories.UserRepository
import com.google.firebase.firestore.FirebaseFirestore

class MapsViewModelFactory(
    private val context: Context
) : ViewModelProvider.Factory {

    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        val db = FirebaseFirestore.getInstance()
        val database = AppDatabase.getDatabase(context)

        val userRepository = UserRepository(
            userDao = database.userDao(),
            db = db,
            context = context
        )

        val productRepository = ProductRepository(
            productDao = database.productDao(),
            db = db,
            context = context,
            userRepository = userRepository
        )

        return MapsViewModel(userRepository, productRepository) as T
    }
}

