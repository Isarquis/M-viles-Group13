package com.example.uni_matketplace_kotlin.di

import FeatureTimeUsage
import android.content.Context
import androidx.room.Room
import com.example.uni_matketplace_kotlin.data.local.AppDatabase
import com.example.uni_matketplace_kotlin.data.local.dao.ProductDao
import com.example.uni_matketplace_kotlin.data.local.dao.UserDao
import com.example.uni_matketplace_kotlin.data.repositories.ProductRepository
import com.example.uni_matketplace_kotlin.data.repositories.UserRepository
import com.google.firebase.firestore.FirebaseFirestore
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import io.realm.kotlin.Realm
import io.realm.kotlin.RealmConfiguration
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    // ==================== Firebase ====================
    @Provides
    @Singleton
    fun provideFirestore(): FirebaseFirestore {
        return FirebaseFirestore.getInstance()
    }

    // ==================== Room Database ====================
    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext appContext: Context): AppDatabase {
        return Room.databaseBuilder(
            appContext,
            AppDatabase::class.java,
            "unimarket_database"  // Cambia el nombre si es necesario
        ).fallbackToDestructiveMigration()  // Opcional: Borra y recrea la DB en cambios de schema
            .build()
    }

    @Provides
    fun provideUserDao(database: AppDatabase): UserDao {
        return database.userDao()
    }

    @Provides
    fun provideProductDao(database: AppDatabase): ProductDao {
        return database.productDao()
    }

    // ==================== Realm Database ====================
    @Provides
    @Singleton
    fun provideRealm(): Realm {
        val config = RealmConfiguration.Builder(
            schema = setOf(FeatureTimeUsage::class)  // Añade aquí TODOS tus modelos Realm
        )
            .compactOnLaunch()  // Opcional: Optimiza el espacio
            .build()

        return Realm.open(config)
    }

    // ==================== Repositories ====================
    @Provides
    @Singleton
    fun provideUserRepository(
        userDao: UserDao,
        firestore: FirebaseFirestore,
        @ApplicationContext context: Context
    ): UserRepository {
        return UserRepository(userDao, firestore, context)
    }

    @Provides
    @Singleton
    fun provideProductRepository(
        productDao: ProductDao,
        firestore: FirebaseFirestore,
        @ApplicationContext context: Context,
        userRepository: UserRepository
    ): ProductRepository {
        return ProductRepository(productDao, firestore, context, userRepository)
    }
}