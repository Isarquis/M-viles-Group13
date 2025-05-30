package com.example.uni_matketplace_kotlin.data.local.entities
import  androidx.room.Entity
import androidx.room.PrimaryKey
import com.example.uni_matketplace_kotlin.data.remote.entities.Product

@Entity(tableName = "products")
class LocalProductEntity (
    @PrimaryKey val id:String,
    val title: String,
    val price: Int,
    val description: String,
    val image: String,
    val userId: String,
    val status: String,
    val category: String,
    val isBuy: Boolean,
    val isRent: Boolean,
    val isEarn: Boolean,
    val isBidding: Boolean)

fun LocalProductEntity.toDomain(): Product {
    val types = mutableListOf<String>()
    if (isBuy) types.add("buy")
    if (isRent) types.add("rent")
    if (isEarn) types.add("earn")
    if (isBidding) types.add("bidding")

    return Product(
        id = this.id,
        title = this.title,
        price = this.price,
        description = this.description,
        image = this.image,
        ownerId = this.userId,
        status = this.status,
        category = this.category,
        type = types
    )
}



