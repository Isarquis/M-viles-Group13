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
import javax.inject.Inject

class ProductRepository @Inject constructor(
    private val productDao: ProductDao,
    private val db: FirebaseFirestore,
    private val context: Context,
    private val userRepository: UserRepository
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
        return try {
            getProductsByUserId(userId).isNotEmpty()
        } catch (e: Exception) {
            Log.e("ProductRepository", "Error al verificar si el usuario tiene productos $userId", e)
            false
        }
    }

    suspend fun getClosestProduct(currentLocation: LatLng): Product? {
        val products = getAllProducts()

        val nearbyProducts = products.mapNotNull { product ->
            val userLocation = userRepository.getUserLocation(product.ownerId)
            if (userLocation != null) {
                val productLatLng = LatLng(userLocation.latitude, userLocation.longitude)
                val distance = calculateDistance(currentLocation, productLatLng)
                if (distance <= 400f) {  // Filtrar por 400 metros
                    Pair(product, distance)
                } else {
                    null
                }
            } else {
                null
            }
        }

        return nearbyProducts.minByOrNull { it.second }?.first  // De los filtrados, tomar el más cercano
    }


    private fun calculateDistance(start: LatLng, end: LatLng): Float {
        val results = FloatArray(1)
        Location.distanceBetween(
            start.latitude,
            start.longitude,
            end.latitude,
            end.longitude,
            results
        )
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
                Log.e("ProductRepository", "Error obteniendo productos desde Firebase", e)
                emptyList()
            }
        } else {
            Log.e("ProductRepository", "No hay conexión a internet, obteniendo productos desde la base local")
            productDao.getAll().map { it.toDomain() }
        }
    }

    suspend fun getClosestProductProductsList(): List<Product> {
        return if (InternetHelper.isInternetAvailable(context)) {
            try {
                val snapshot = productsCollection.get().await()
                val products = snapshot.documents.mapNotNull { doc ->
                    doc.toObject(Product::class.java)?.copy(id = doc.id)
                }

                if (products.isEmpty()) {
                    Log.d("ProductRepository", "No se encontraron productos cercanos. Mostrando los primeros productos.")
                    getFirstProducts()
                } else {
                    Log.d("ProductRepository", "Productos obtenidos desde Firebase: ${products.size}")
                    products
                }
            } catch (e: Exception) {
                Log.e("ProductRepository", "Error obteniendo productos desde Firebase", e)
                emptyList()
            }
        } else {
            val localProducts = productDao.getAll().map { it.toDomain() }
            if (localProducts.isEmpty()) {
                Log.d("ProductRepository", "No hay productos cercanos en la base de datos local. Mostrando los primeros productos.")
                getFirstProducts()
            } else {
                Log.d("ProductRepository", "Productos obtenidos desde la base de datos local: ${localProducts.size}")
                localProducts
            }
        }
    }

    private suspend fun getFirstProducts(): List<Product> {
        return if (InternetHelper.isInternetAvailable(context)) {
            try {
                val snapshot = productsCollection.limit(5).get().await()
                snapshot.documents.mapNotNull { doc ->
                    doc.toObject(Product::class.java)?.copy(id = doc.id)
                }
            } catch (e: Exception) {
                Log.e("ProductRepository", "Error obteniendo productos limitados desde Firebase", e)
                emptyList()
            }
        } else {
            Log.e("ProductRepository", "No hay conexión a internet, obteniendo productos limitados desde la base local")
            productDao.getAll().take(5).map { it.toDomain() }
        }
    }

    suspend fun getFilteredProducts(filterType: String): List<Product> {
        return if (InternetHelper.isInternetAvailable(context)) {
            try {
                val snapshot = productsCollection
                    .whereEqualTo("type", filterType)
                    .get()
                    .await()

                snapshot.documents.mapNotNull { doc ->
                    doc.toObject(Product::class.java)?.copy(id = doc.id)
                }.also {
                    Log.d("ProductRepository", "Productos filtrados obtenidos desde Firebase: ${it.size}")
                }

            } catch (e: Exception) {
                Log.e("ProductRepository", "Error obteniendo productos filtrados desde Firebase", e)
                emptyList()
            }
        } else {
            Log.e("ProductRepository", "No hay conexión a internet, obteniendo productos filtrados desde la base local")
            when (filterType) {
                "buy" -> productDao.getProductsWhoBuy().map { it.toDomain() }
                "rent" -> productDao.getProductsWhoRent().map { it.toDomain() }
                "earn" -> productDao.getProductsWhoEarn().map { it.toDomain() }
                "bidding" -> productDao.getProductsWhoBid().map { it.toDomain() }
                else -> productDao.getAll().map { it.toDomain() }
            }.also {
                Log.d("ProductRepository", "Productos filtrados obtenidos desde la base local: ${it.size}")
            }
        }

    }
    suspend fun incrementClickCounter(productId: String, attribute: String) {
        val docRef = db.collection("products").document(productId)
        db.runTransaction { transaction ->
            val snapshot = transaction.get(docRef)
            val currentCount = snapshot.getLong("clicks.$attribute") ?: 0
            transaction.update(docRef, "clicks.$attribute", currentCount + 1)
        }.await()
    }

}
