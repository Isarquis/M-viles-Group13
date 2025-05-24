package com.example.uni_matketplace_kotlin.viewmodel

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.uni_matketplace_kotlin.data.repositories.UserRepository
import com.example.uni_matketplace_kotlin.data.remote.entities.User
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.tasks.await

class ProfileViewModel(private val userRepository: UserRepository) : ViewModel() {

    private val _userProfile = MutableStateFlow<User?>(null)
    val userProfile: StateFlow<User?> = _userProfile

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error

    fun loadUserProfile(userId: String) {
        viewModelScope.launch {
            try {
                _isLoading.value = true
                _error.value = null

                Log.d("ProfileViewModel", "Loading user profile for ID: $userId")

                // Cargar directamente desde Firestore (como se guarda en RegisterActivity)
                val user = withContext(Dispatchers.IO) {
                    loadUserFromFirestore(userId)
                }

                _userProfile.value = user

                if (user == null) {
                    _error.value = "Usuario no encontrado"
                    Log.w("ProfileViewModel", "User not found for ID: $userId")
                } else {
                    Log.d("ProfileViewModel", "User profile loaded successfully: ${user.name}")
                }

            } catch (e: Exception) {
                Log.e("ProfileViewModel", "Error loading user profile: ${e.message}", e)
                _error.value = "Error al cargar el perfil: ${e.message}"
                _userProfile.value = null
            } finally {
                _isLoading.value = false
            }
        }
    }

    private suspend fun loadUserFromFirestore(userId: String): User? {
        return try {
            // Usar Firestore directamente para obtener el usuario
            val firestore = com.google.firebase.firestore.FirebaseFirestore.getInstance()
            val document = firestore.collection("users").document(userId).get().await()

            if (document.exists()) {
                val data = document.data
                User(
                    id = data?.get("id") as? String ?: userId,
                    name = data?.get("name") as? String ?: "",
                    email = data?.get("email") as? String ?: "",
                    phone = data?.get("phone") as? String ?: ""
                )
            } else {
                Log.w("ProfileViewModel", "User document does not exist in Firestore")
                null
            }
        } catch (e: Exception) {
            Log.e("ProfileViewModel", "Error loading user from Firestore: ${e.message}", e)
            // Fallback: intentar cargar desde el repositorio local
            try {
                val allUsers = userRepository.getAllUsers()
                allUsers.find { it.id == userId }
            } catch (e2: Exception) {
                Log.e("ProfileViewModel", "Fallback also failed: ${e2.message}", e2)
                null
            }
        }
    }

    fun refreshProfile(userId: String) {
        loadUserProfile(userId)
    }

    fun clearError() {
        _error.value = null
    }
}