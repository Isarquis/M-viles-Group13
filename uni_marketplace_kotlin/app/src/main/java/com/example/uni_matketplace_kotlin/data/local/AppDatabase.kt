package com.example.uni_matketplace_kotlin.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.example.uni_matketplace_kotlin.data.local.dao.ProductDao
import com.example.uni_matketplace_kotlin.data.local.dao.UserDao
import com.example.uni_matketplace_kotlin.data.local.entities.LocalProductEntity
import com.example.uni_matketplace_kotlin.data.local.entities.LocalUserEntity

@Database(
    entities = [LocalUserEntity::class, LocalProductEntity::class],
    version = 1
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun userDao(): UserDao
    abstract fun productDao(): ProductDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                INSTANCE
                    ?:buildeDatabase(context).also { INSTANCE = it }
            }
        }

        private fun buildeDatabase(context: Context): AppDatabase {
            return Room.databaseBuilder(context, AppDatabase::class.java, "app_database").build()

        }
    }
}
