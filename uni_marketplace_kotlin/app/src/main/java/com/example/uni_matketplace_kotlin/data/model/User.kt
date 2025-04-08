package com.example.uni_matketplace_kotlin.data.model
import com.google.firebase.firestore.GeoPoint

data class User(
    val id: String="",
    val name: String="",
    val phone: String="",
    val image: String="",
    val email: String="",
    val location: GeoPoint= GeoPoint(0.0,0.0)
)
