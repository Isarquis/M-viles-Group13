package com.example.uni_matketplace_kotlin.viewmodel

import android.content.Context
import android.util.Log
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
        return if (modelClass.isAssignableFrom(MapsViewModel::class.java)) {
            try {
                Log.d("MapsViewModelFactory", "Creating MapsViewModel")

                // Usar applicationContext para evitar memory leaks
                val appContext = context.applicationContext
                val db = FirebaseFirestore.getInstance()
                val database = AppDatabase.getDatabase(appContext)

                val userRepository = UserRepository(
                    userDao = database.userDao(),
                    db = db,
                    context = appContext
                )

                val productRepository = ProductRepository(
                    productDao = database.productDao(),
                    db = db,
                    context = appContext,
                    userRepository = userRepository
                )

                Log.d("MapsViewModelFactory", "MapsViewModel created successfully")
                MapsViewModel(userRepository, productRepository) as T

            } catch (e: Exception) {
                Log.e("MapsViewModelFactory", "Error creating MapsViewModel: ${e.message}", e)
                throw RuntimeException("Failed to create MapsViewModel: ${e.message}", e)
            }
        } else {
            throw IllegalArgumentException("Unknown ViewModel class: ${modelClass.name}")
        }
    }
}