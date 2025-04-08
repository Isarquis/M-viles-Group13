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

    suspend fun getUserByEmail(email: String): User? {
        return try{
            val querySnapshot = usersCollection.whereEqualTo("email", email).get().await()
            if (!querySnapshot.isEmpty) {
                val document = querySnapshot.documents[0]
                document.toObject(User::class.java)?.copy(email = document.id)
            }else{
                null
            }
        }catch (e: Exception){
            null
        }
    }

    suspend fun getUserLocation(email: String): GeoPoint? {
        return getUserByEmail(email)?.location
    }

    suspend fun updateUserLocation(email: String, location: LatLng) {
        val user = getUserByEmail(email)
        if (user != null) {
            usersCollection.document(user.id).update("location", GeoPoint(location.latitude, location.longitude)).await()
        }else{
            throw Exception("User not found")
        }
    }

    suspend fun getAllLocations(): List<Pair<String, GeoPoint>> {
        return try {
            val snapshot = usersCollection.get().await()
            snapshot.documents.mapNotNull { doc ->
                val user = doc.toObject(User::class.java)
                user?.let { Pair(it.email, it.location) }
            }
        } catch (e: Exception) {
            emptyList()
        }
    }
    suspend fun getAllUsers(): List<User> {
        return try {
            val snapshot = usersCollection.get().await()
            val users = snapshot.documents.mapNotNull { doc ->
                val user = doc.toObject(User::class.java)?.copy(id = doc.id)
                user?.let {
                    Log.d("UserRepository", "User: ${it.name}, Location: ${it.location}")
                }
                user
            }
            users
        } catch (e: Exception) {
            Log.e("UserRepository", "Error al obtener usuarios", e)
            emptyList()
        }
    }

}



