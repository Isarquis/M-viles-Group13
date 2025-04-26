package com.example.uni_matketplace_kotlin.di

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
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideFirestore(): FirebaseFirestore = FirebaseFirestore.getInstance()

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext appContext: Context): AppDatabase {
        return Room.databaseBuilder(
            appContext,
            AppDatabase::class.java,
            "app_database"
        ).build()
    }

    @Provides
    fun provideProductDao(database: AppDatabase): ProductDao = database.productDao()

    @Provides
    fun provideUserDao(database: AppDatabase): UserDao = database.userDao()

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
