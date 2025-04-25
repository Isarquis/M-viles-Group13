package com.example.uni_matketplace_kotlin.data.repositories

import android.content.Context
import android.util.Log
import com.example.uni_matketplace_kotlin.data.local.dao.ProductDao
import com.example.uni_matketplace_kotlin.data.remote.entities.Product
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.tasks.await
import InternetHelper
import android.location.Location
import com.example.uni_matketplace_kotlin.data.local.entities.toDomain
import com.example.uni_matketplace_kotlin.data.remote.entities.toLocal
import com.google.android.gms.maps.model.LatLng
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class ProductRepository(
    private val productDao: ProductDao,
    private val db: FirebaseFirestore,
    private val context: Context,
    private val userRepository: UserRepository // <- asegurarse de pasarla al crear el repo
) {
    private val productsCollection = db.collection("products")

    suspend fun getProductsByUserId(userId: String): List<Product> = withContext(Dispatchers.IO) {
        if (InternetHelper.isInternetAvailable(context)) {
            try {
                val snapshot = productsCollection.whereEqualTo("ownerId", userId).get().await()
                val products = snapshot.documents.mapNotNull { doc ->
                    doc.toObject(Product::class.java)?.copy(id = doc.id)
                }
                productDao.insertAll(products.map { it.toLocal() })
                products
            } catch (e: Exception) {
                Log.e("ProductRepository", "Error al obtener productos del usuario $userId", e)
                productDao.getProductsByOwnerId(userId).map { it.toDomain() }
            }
        } else {
            productDao.getProductsByOwnerId(userId).map { it.toDomain() }
        }
    }

    suspend fun userHasProducts(userId: String): Boolean {
        return getProductsByUserId(userId).isNotEmpty()
    }

    suspend fun getClosestProduct(currentLocation: LatLng): Product? {
        val products = getAllProducts()

        return products.minByOrNull { product ->
            val userLocation = userRepository.getUserLocation(product.ownerId)

            if (userLocation != null) {
                val productLatLng = LatLng(userLocation.latitude, userLocation.longitude)
                calculateDistance(currentLocation, productLatLng)
            } else {
                Float.MAX_VALUE
            }
        }
    }


    private fun calculateDistance(start: LatLng, end: LatLng): Float {
        val results = FloatArray(1)
        Location.distanceBetween(start.latitude, start.longitude, end.latitude, end.longitude, results)
        return results[0]
    }

    private suspend fun getAllProducts(): List<Product> {
        return if (InternetHelper.isInternetAvailable(context)) {
            try {
                val snapshot = productsCollection.get().await()
                snapshot.documents.mapNotNull { doc ->
                    doc.toObject(Product::class.java)?.copy(id = doc.id)
                }
            } catch (e: Exception) {
                Log.e("ProductRepository", "Error obteniendo productos", e)
                emptyList()
            }
        } else {
            productDao.getAll().map { it.toDomain() }
        }
    }
}
