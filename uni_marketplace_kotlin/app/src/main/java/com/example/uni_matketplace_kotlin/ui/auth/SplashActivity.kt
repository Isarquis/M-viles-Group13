package com.example.uni_matketplace_kotlin.ui.auth

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.google.firebase.auth.FirebaseAuth
import com.example.uni_matketplace_kotlin.MainActivity

class SplashActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val user = FirebaseAuth.getInstance().currentUser
        if (user != null) {
            // Usuario logueado
            startActivity(Intent(this, MainActivity::class.java))
        } else {
            // No logueado
            startActivity(Intent(this, LoginActivity::class.java))
        }
        finish()
    }
}
