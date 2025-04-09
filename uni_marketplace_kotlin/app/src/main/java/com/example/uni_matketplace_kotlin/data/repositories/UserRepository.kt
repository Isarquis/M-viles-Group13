package com.example.uni_matketplace_kotlin.data.repositories

import android.util.Log
import com.example.uni_matketplace_kotlin.data.model.User
import com.google.android.gms.maps.model.LatLng
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.GeoPoint
import kotlinx.coroutines.tasks.await

class UserRepository {
    private val db = FirebaseFirestore.getInstance()
    private val usersCollection = db.collection("users")

    suspend fun getAllUsers(): List<User> {
        return try {
            val snapshot = usersCollection.get().await()
            snapshot.documents.mapNotNull { doc ->
                doc.toObject(User::class.java)?.copy(id = doc.id)
            }
        } catch (e: Exception) {
            Log.e("UserRepository", "Error obteniendo usuarios", e)
            emptyList()
        }
    }

    suspend fun getUserByEmail(email: String): User? {
        val snapshot = usersCollection.whereEqualTo("email", email).get().await()
        return if (!snapshot.isEmpty) {
            val doc = snapshot.documents[0]
            doc.toObject(User::class.java)?.copy(id = doc.id)
        } else null
    }

    suspend fun updateUserLocation(email: String, location: LatLng) {
        val user = getUserByEmail(email)
        user?.let {
            usersCollection.document(it.id).update("location", GeoPoint(location.latitude, location.longitude)).await()
        }
    }
}
