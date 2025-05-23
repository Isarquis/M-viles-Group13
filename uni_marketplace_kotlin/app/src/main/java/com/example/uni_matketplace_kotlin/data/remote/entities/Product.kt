package com.example.uni_matketplace_kotlin.data.remote.entities

import com.example.uni_matketplace_kotlin.data.local.entities.LocalProductEntity
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.QueryDocumentSnapshot
import com.google.firebase.firestore.ServerTimestamp
import java.util.Date

data class Product (
    val id: String = "",
    val baseBid: Int = 0,
    val category: String = "",
    @ServerTimestamp val createdAt: Date? = null,
    val description: String = "",
    val image: String = "",
    val ownerId: String = "",
    val price: Int = 0,
    val status: String = "",
    val title: String = "",
    var type: List<String> = listOf(),
) {
    companion object {
        fun fromFirestore(doc: DocumentSnapshot): Product {
            return Product(
                id = doc.id,
                title = doc.getString("title") ?: "",
                description = doc.getString("description") ?: "",
                price = (doc.get("price") as? Long)?.toInt() ?: 0,
                image = doc.getString("image") ?: "",
                ownerId = doc.getString("ownerId") ?: "",
                category = doc.getString("category") ?: "",
                status = doc.getString("status") ?: "",
                type = (doc.get("type") as? List<String>) ?: listOf(),
                createdAt = doc.getTimestamp("createdAt")?.toDate() // Aquí usamos `Timestamp` de Firestore
            )
        }
    }
}
fun Product.toLocal(): LocalProductEntity {
    return LocalProductEntity(
        id = this.id,
        title = this.title,
        price = this.price,
        description = this.description,
        image = this.image,
        userId = this.ownerId,
        status = this.status,
        category = this.category,
        isBuy = this.type.contains("buy"),
        isRent = this.type.contains("rent"),
        isEarn = this.type.contains("earn"),
        isBidding = this.type.contains("bidding")
    )
}