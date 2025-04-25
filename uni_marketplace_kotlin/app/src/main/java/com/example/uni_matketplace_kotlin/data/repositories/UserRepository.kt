package com.example.uni_matketplace_kotlin.data.repositories

import android.content.Context
import android.location.Location
import android.util.Log
import com.example.uni_matketplace_kotlin.data.local.dao.UserDao
import com.example.uni_matketplace_kotlin.data.local.entities.toDomain
import com.example.uni_matketplace_kotlin.data.remote.entities.User
import com.example.uni_matketplace_kotlin.data.remote.entities.toLocal
import com.example.uni_matketplace_kotlin.data.remote.entities.Product
import com.google.android.gms.maps.model.LatLng
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.GeoPoint
import kotlinx.coroutines.tasks.await
import InternetHelper
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class UserRepository(
    private val userDao: UserDao,
    private val db: FirebaseFirestore,
    private val context: Context
) {
    private val usersCollection = db.collection("users")
    private val userLocationCache = mutableMapOf<String, GeoPoint>()

    suspend fun getAllUsers(): List<User> = withContext(Dispatchers.IO) {
        if (InternetHelper.isInternetAvailable(context)) {
            try {
                val snapshot = usersCollection.get().await()
                val remoteUsers = snapshot.documents.mapNotNull { doc ->
                    doc.toObject(User::class.java)?.copy(id = doc.id)
                }
                userDao.insertAll(remoteUsers.map { it.toLocal() })
                remoteUsers
            } catch (e: Exception) {
                Log.e("UserRepository", "Error fetching users", e)
                userDao.getAll().map { it.toDomain() }
            }
        } else {
            userDao.getAll().map { it.toDomain() }
        }
    }

    suspend fun getUserLocation(userId: String): GeoPoint? {
        if (userId.isBlank()) {
            Log.e("UserRepository", "userId es nulo o vacío.")
            return null
        }
        userLocationCache[userId]?.let {
            return it
        }

        return try {
            val snapshot = usersCollection.document(userId).get().await()

            if (snapshot.exists()) {
                val user = snapshot.toObject(User::class.java)
                user?.location?.also {
                    userLocationCache[userId] = it // Cachear para futuros accesos
                }
            } else {
                null
            }
        } catch (e: Exception) {
            Log.e("UserRepository", "Error obteniendo la ubicación del usuario con ID $userId", e)
            null
        }
    }


    suspend fun getUsersNearby(currentLocation: LatLng, maxDistance: Float): List<User> {
        val users = getAllUsers()
        return users.filter { user ->
            user.location?.latitude != null && user.location.longitude != null
        }.mapNotNull { user ->
            val userLatLng = LatLng(user.location!!.latitude!!, user.location.longitude!!)
            val distance = calculateDistance(currentLocation, userLatLng)
            if (distance <= maxDistance) user else null
        }
    }

    suspend fun getClosestUser(currentLocation: LatLng): User? {
        val nearbyUsers = getUsersNearby(currentLocation, maxDistance = 400f) // Rango de 400m
        return nearbyUsers.minByOrNull { user ->
            val userLatLng = LatLng(user.location!!.latitude!!, user.location.longitude!!)
            calculateDistance(currentLocation, userLatLng)
        }
    }

    suspend fun getClosestUserWithProduct(
        currentLocation: LatLng,
        maxDistance: Float,
        productRepository: ProductRepository
    ): Triple<User, Float, Product>? {
        val users = getAllUsers()
        return users
            .filter { it.location?.latitude != null && it.location.longitude != null }
            .mapNotNull { user ->
                val userLatLng = LatLng(user.location!!.latitude!!, user.location.longitude!!)
                val distance = calculateDistance(currentLocation, userLatLng)
                if (distance <= maxDistance) {
                    val products = productRepository.getProductsByUserId(user.id)
                    if (products.isNotEmpty()) Triple(user, distance, products.first()) else null
                } else null
            }
            .minByOrNull { it.second }
    }

    private fun calculateDistance(start: LatLng, end: LatLng): Float {
        val results = FloatArray(1)
        Location.distanceBetween(start.latitude, start.longitude, end.latitude, end.longitude, results)
        return results[0]
    }
}
