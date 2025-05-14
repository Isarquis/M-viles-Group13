package com.example.uni_matketplace_kotlin.data.repositories

import android.content.Context
import android.location.Location
import android.util.Log
import com.example.uni_matketplace_kotlin.data.local.dao.ProductDao
import com.example.uni_matketplace_kotlin.data.local.entities.toDomain
import com.example.uni_matketplace_kotlin.data.remote.entities.Product
import com.example.uni_matketplace_kotlin.data.remote.entities.toLocal
import com.example.uni_matketplace_kotlin.utils.NetworkUtils.isOnline
import com.google.android.gms.maps.model.LatLng
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.tasks.await
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
        if (isOnline(context)) {
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
            userLocation?.let {
                val productLatLng = LatLng(it.latitude, it.longitude)
                val distance = calculateDistance(currentLocation, productLatLng)
                if (distance <= 400f) Pair(product, distance) else null
            }
        }

        return nearbyProducts.minByOrNull { it.second }?.first
    }

    private fun calculateDistance(start: LatLng, end: LatLng): Float {
        val results = FloatArray(1)
        Location.distanceBetween(
            start.latitude, start.longitude,
            end.latitude, end.longitude,
            results
        )
        return results[0]
    }

    suspend fun getAllProducts(): List<Product> {
        return if (isOnline(context)) {
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

    suspend fun getAllProductsForClosestSearch(): List<Product> {
        return getAllProducts()
    }

    suspend fun getFirstProducts(): List<Product> {
        return if (isOnline(context)) {
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

    suspend fun getFilteredProducts(type: String?, category: String?): List<Product> {
        val products = getAllProducts()

        Log.d("ProductRepository", "Total productos obtenidos: ${products.size}")

        saveProductsToLocal(products)

        val filtered = products.filter {
            (type == null || it.type.contains(type)) &&
                    (category == null || it.category.contains(category))
        }

        Log.d("ProductRepository", "Productos filtrados: ${filtered.size}")
        return filtered
    }

    suspend fun saveProductsToLocal(products: List<Product>) {
        Log.d("ProductRepository", "Guardando productos en la base local: ${products.size}")

        val localProducts = products.map { it.toLocal() }

        productDao.insertAll(localProducts)
        Log.d("ProductRepository", "Productos insertados/actualizados en la base local.")
    }

    suspend fun getLocalProducts(): List<Product> {
        return productDao.getAll().map { it.toDomain() }
    }

    suspend fun incrementClickCounter(productId: String, attribute: String) {
        val docRef = db.collection("products").document(productId)
        db.runTransaction { transaction ->
            val snapshot = transaction.get(docRef)
            val currentCount = snapshot.getLong("clicks.$attribute") ?: 0
            transaction.update(docRef, "clicks.$attribute", currentCount + 1)
        }.await()
    }

    suspend fun getFilteredLocalProducts(type: String?): List<Product> {
        val localProducts = productDao.getAllProducts().map { it.toDomain() }

        val result = when (type) {
            "Buy" -> localProducts.filter { it.toLocal().isBuy }
            "Rent" -> localProducts.filter { it.toLocal().isRent }
            "Earn" -> localProducts.filter { it.toLocal().isEarn }
            "Bidding" -> localProducts.filter { it.toLocal().isBidding }
            else -> localProducts
        }

        return result
    }

}
