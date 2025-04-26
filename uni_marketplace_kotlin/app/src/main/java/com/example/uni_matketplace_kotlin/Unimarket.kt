package com.example.uni_matketplace_kotlin

import android.app.Application
import dagger.hilt.android.HiltAndroidApp
import io.realm.kotlin.Realm

@HiltAndroidApp()
class Unimarket : Application() {
    override fun onCreate() {
        super.onCreate()
    }
}