package com.example.uni_matketplace_kotlin.ui.auth

import SessionViewModel
import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.viewModels
import com.example.uni_matketplace_kotlin.MainActivity
import com.example.uni_matketplace_kotlin.databinding.ActivityLoginBinding
import com.google.firebase.auth.FirebaseAuth
import dagger.hilt.android.HiltAndroidApp

class LoginActivity : AppCompatActivity() {

    private lateinit var binding: ActivityLoginBinding
    private lateinit var auth: FirebaseAuth
    private val sessionViewModel: SessionViewModel by viewModels()


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityLoginBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Inicializar Firebase Auth
        auth = FirebaseAuth.getInstance()

        binding.btnLogin.setOnClickListener {
            val email = binding.etEmail.text.toString().trim()
            val password = binding.etPassword.text.toString().trim()

            if (email.isNotEmpty() && password.isNotEmpty()) {
                auth.signInWithEmailAndPassword(email, password)
                    .addOnCompleteListener { task ->
                        if (task.isSuccessful) {
                            Toast.makeText(this, "Login exitoso", Toast.LENGTH_SHORT).show()
                            // Ir al dashboard o actividad principal
                            startActivity(Intent(this, MainActivity::class.java))
                            finish()
                        } else {
                            Toast.makeText(this, "Error: ${task.exception?.message}", Toast.LENGTH_SHORT).show()
                        }
                    }
            } else {
                Toast.makeText(this, "Por favor ingresa email y contraseña", Toast.LENGTH_SHORT).show()
            }
        }

        binding.btnGoToRegister.setOnClickListener {
            // Navegar a la pantalla de registro
            startActivity(Intent(this, RegisterActivity::class.java))
        }
    }

    //Analytics Pipeline
    override fun onResume() {
        super.onResume()
        sessionViewModel.logEvent("enter", "login")
    }

    override fun onPause() {
        super.onPause()
        sessionViewModel.logEvent("exit", "login")
    }

}
