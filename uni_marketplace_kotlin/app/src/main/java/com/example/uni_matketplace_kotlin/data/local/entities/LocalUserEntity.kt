package com.example.uni_matketplace_kotlin.data.local.entities

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.example.uni_matketplace_kotlin.data.remote.entities.User
import com.google.firebase.firestore.GeoPoint

@Entity(tableName = "users")
data class LocalUserEntity(
    @PrimaryKey val id: String,
    val name: String,
    val email: String,
    val phone: String,
    val latitude: Double,
    val longitude: Double)

fun LocalUserEntity.toDomain(): User {

    return User(
        id = this.id,
        name = this.name,
        email = this.email,
        location = GeoPoint(this.latitude, this.longitude),
        phone = this.phone,
    )
}

