package com.example.uni_matketplace_kotlin.ui.auth

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.example.uni_matketplace_kotlin.databinding.ActivityRegisterBinding
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await

class RegisterActivity : AppCompatActivity() {

    private lateinit var binding: ActivityRegisterBinding
    private lateinit var auth: FirebaseAuth
    private val firestore = FirebaseFirestore.getInstance()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityRegisterBinding.inflate(layoutInflater)
        setContentView(binding.root)

        auth = FirebaseAuth.getInstance()

        binding.btnRegister.setOnClickListener {
            val email = binding.etEmail.text.toString().trim()
            val password = binding.etPassword.text.toString().trim()
            val confirmPassword = binding.etConfirmPassword.text.toString().trim()
            val name = binding.etName.text.toString().trim()
            val phone = binding.etPhone.text.toString().trim()

            if (email.isEmpty() || password.isEmpty() || confirmPassword.isEmpty() || name.isEmpty() || phone.isEmpty()) {
                Toast.makeText(this, "Complete all the fields", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            if (password != confirmPassword) {
                Toast.makeText(this, "The passwords don't match", Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }

            registerUser(email, password, name, phone)
        }

//        binding.btnUploadPhoto.setOnClickListener {
//            // Implementar lógica para subir foto
//        }
    }

    private fun registerUser(email: String, password: String, name: String, phone: String) {
        CoroutineScope(Dispatchers.Main).launch {
            try {
                val userCredential = auth.createUserWithEmailAndPassword(email, password).await()
                val userId = userCredential.user?.uid ?: throw Exception("User ID not found")

                val user = hashMapOf(
                    "id" to userId,
                    "name" to name,
                    "phone" to phone,
                    "email" to email
                )

                firestore.collection("users").document(userId).set(user).await()

                Toast.makeText(this@RegisterActivity, "Successful Registration", Toast.LENGTH_SHORT).show()
                startActivity(Intent(this@RegisterActivity, LoginActivity::class.java))
                finish()
            } catch (e: Exception) {
                Toast.makeText(this@RegisterActivity, "Error: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        }
    }

    fun onLoginClick(view: View) {
        startActivity(Intent(this, LoginActivity::class.java))
    }
}
