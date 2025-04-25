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
    suspend fun insertAll(products: List<LocalProductEntity>)  // Fixed parameter name

    @Query("DELETE FROM products")
    suspend fun deleteAll()

    @Query("SELECT * FROM products")
    suspend fun getAll(): List<LocalProductEntity>

    @Query("SELECT * FROM products")
    suspend fun getAllProducts(): List<LocalProductEntity>  // Consider removing duplicate method

    @Query("SELECT * FROM products WHERE id = :productId")
    suspend fun getProductById(productId: String): LocalProductEntity?

    @Query("SELECT * FROM products WHERE userId = :userId")
    suspend fun getProductsByOwnerId(userId: String): List<LocalProductEntity>
}