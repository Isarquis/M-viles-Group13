package com.example.uni_matketplace_kotlin.data.repositories

import com.example.uni_matketplace_kotlin.data.model.Product
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.tasks.await

class ProductRepository {
    private val db = FirebaseFirestore.getInstance()
    private val productsCollection = db.collection("products")

    suspend fun getProductsByUserId(userId: String): List<Product> {
        return try {
            val snapshot = productsCollection.whereEqualTo("userId", userId).get().await()
            snapshot.documents.mapNotNull { doc ->
                doc.toObject(Product::class.java)?.copy(id = doc.id)
            }
        } catch (e: Exception) {
            emptyList()
        }
    }
}
