package com.example.uni_matketplace_kotlin.data.local.dao

import androidx.room.Dao
import androidx.room.Query
import androidx.room.Upsert
import com.example.uni_matketplace_kotlin.data.local.entities.LocalProductEntity
@Dao
interface ProductDao {
    @Upsert
    suspend fun insertProduct(product: LocalProductEntity)

    @Upsert
    suspend fun insertAll(products: List<LocalProductEntity>)

    @Query("DELETE FROM products")
    suspend fun deleteAll()

    @Query("SELECT * FROM products")
    suspend fun getAll(): List<LocalProductEntity>

    @Query("SELECT * FROM products")
    suspend fun getAllProducts(): List<LocalProductEntity>  // Podrías eliminar este si ya usas `getAll()`

    @Query("SELECT * FROM products WHERE id = :productId")
    suspend fun getProductById(productId: String): LocalProductEntity?

    @Query("SELECT * FROM products WHERE userId = :userId")
    suspend fun getProductsByOwnerId(userId: String): List<LocalProductEntity>

    @Query("SELECT * FROM products WHERE isBuy = 1")
    suspend fun getProductsWhoBuy(): List<LocalProductEntity>

    @Query("SELECT * FROM products WHERE isRent = 1")
    suspend fun getProductsWhoRent(): List<LocalProductEntity>

    @Query("SELECT * FROM products WHERE isEarn = 1")
    suspend fun getProductsWhoEarn(): List<LocalProductEntity>

    @Query("SELECT * FROM products WHERE isBidding = 1")
    suspend fun getProductsWhoBid(): List<LocalProductEntity>

}
