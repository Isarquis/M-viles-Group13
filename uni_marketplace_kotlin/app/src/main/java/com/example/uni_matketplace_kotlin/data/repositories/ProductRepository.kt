package com.example.uni_matketplace_kotlin.data.repositories

import android.util.Log
import com.example.uni_matketplace_kotlin.data.model.Product
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.tasks.await

class ProductRepository {
    private val db = FirebaseFirestore.getInstance()
    private val productsCollection = db.collection("products")

    suspend fun getProductsByUserId(userId: String): List<Product> {
        Log.d("ProductRepository", "Buscando productos para userId: $userId") // 👈 Log de entrada

        return try {
            val snapshot = productsCollection.whereEqualTo("ownerId", userId).get().await()
            val products = snapshot.documents.mapNotNull { doc ->
                val product = doc.toObject(Product::class.java)?.copy(id = doc.id)
                Log.d("ProductRepository", "Producto encontrado: ${product?.title}, ownerId: ${product?.ownerId}") // 👈 Log de cada producto
                product
            }
            Log.d("ProductRepository", "Total productos encontrados: ${products.size}")
            products
        } catch (e: Exception) {
            Log.e("ProductRepository", "Error al obtener productos del usuario $userId", e)
            emptyList()
        }
    }

}
