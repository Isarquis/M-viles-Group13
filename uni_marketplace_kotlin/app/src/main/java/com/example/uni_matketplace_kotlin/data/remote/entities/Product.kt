package com.example.uni_matketplace_kotlin.data.remote.entities

import com.example.uni_matketplace_kotlin.data.local.entities.LocalProductEntity
import com.example.uni_matketplace_kotlin.data.local.entities.LocalUserEntity
import java.util.Date

data class Product (
    val id: String="",
    val baseBid: Int=0,
    val category: String="",
    val createdAt: Date= Date(0),
    val description: String="",
    val image: String="",
    val ownerId: String="",
    val price: Int=0,
    val status: String="",
    val title: String="",
    var type: List<String> = listOf(),
    )

fun Product.toLocal(): LocalProductEntity {
    return LocalProductEntity(
        id = this.id,
        title = this.title,
        price = this.price,
        description = this.description,
        image = this.image,
        userId = this.ownerId,
        status = this.status,
        category = this.category
    )
}


