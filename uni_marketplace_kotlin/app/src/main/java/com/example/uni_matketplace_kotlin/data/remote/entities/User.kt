package com.example.uni_matketplace_kotlin.data.remote.entities
import com.example.uni_matketplace_kotlin.data.local.entities.LocalUserEntity
import com.google.firebase.firestore.GeoPoint

data class User(
    val id: String="",
    val name: String="",
    val phone: String="",
    val image: String="",
    val email: String="",
    val location: GeoPoint= GeoPoint(0.0,0.0)
)
fun User.toLocal(): LocalUserEntity {
    return LocalUserEntity(
        id = this.id,
        name = this.name,
        email = this.email,
        phone = this.phone ?: "",
        latitude = this.location.latitude,
        longitude = this.location.longitude)
}
