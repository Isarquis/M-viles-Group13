package com.example.uni_matketplace_kotlin.data.local.dao
import androidx.room.Dao

import androidx.room.Query
import androidx.room.Upsert
import com.example.uni_matketplace_kotlin.data.local.entities.LocalUserEntity

@Dao
interface UserDao {
    @Upsert
    suspend fun insertUser(user: LocalUserEntity)

    @Upsert
    suspend fun insertAll(users: List<LocalUserEntity>)

    @Query("SELECT * FROM users")
    suspend fun getAll(): List<LocalUserEntity>  // Added suspend

    @Query("SELECT * FROM users WHERE id = :userId")
    suspend fun getUserById(userId: String): LocalUserEntity?  // Added suspend

    @Query("SELECT * FROM users WHERE latitude BETWEEN :minLat AND :maxLat AND longitude BETWEEN :minLon AND :maxLon")
    suspend fun getUsersNearby(minLat: Double, maxLat: Double, minLon: Double, maxLon: Double): List<LocalUserEntity>  // Added suspend
}
