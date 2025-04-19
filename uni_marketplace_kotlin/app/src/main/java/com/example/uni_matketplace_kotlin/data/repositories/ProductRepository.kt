package com.example.uni_matketplace_kotlin.data.repositories

import android.util.Log
import com.example.uni_matketplace_kotlin.data.model.Product
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.tasks.await

class ProductRepository {
    private val db = FirebaseFirestore.getInstance()
    private val productsCollection = db.collection("products")

    suspend fun getProductsByUserId(userId: String): List<Product> {
        Log.d("ProductRepository", "Buscando productos para userId: $userId")
        return try {
            val snapshot = productsCollection.whereEqualTo("ownerId", userId).get().await()
            snapshot.documents.mapNotNull { doc ->
                doc.toObject(Product::class.java)?.copy(id = doc.id)
            }
        } catch (e: Exception) {
            Log.e("ProductRepository", "Error al obtener productos del usuario $userId", e)
            emptyList()
        }
    }

    suspend fun userHasProducts(userId: String): Boolean {
        return try {
            val snapshot = productsCollection.whereEqualTo("ownerId", userId).limit(1).get().await()
            !snapshot.isEmpty
        } catch (e: Exception) {
            Log.e("ProductRepository", "Error verificando productos del usuario $userId", e)
            false
        }
    }
}
