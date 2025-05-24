package com.example.uni_matketplace_kotlin.ui.profile

import com.google.firebase.auth.FirebaseAuth
import com.example.uni_matketplace_kotlin.viewmodel.ProfileViewModelFactory

import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.lifecycleScope
import com.example.uni_matketplace_kotlin.databinding.FragmentProfileBinding
import com.example.uni_matketplace_kotlin.viewmodel.ProfileViewModel
import kotlinx.coroutines.launch
import com.example.uni_matketplace_kotlin.data.repositories.UserRepository
import com.example.uni_matketplace_kotlin.data.local.AppDatabase
import com.google.firebase.firestore.FirebaseFirestore

class ProfileFragment : Fragment() {

    private var _binding: FragmentProfileBinding? = null
    private val binding get() = _binding!!

    private lateinit var userRepository: UserRepository
    private val viewModel: ProfileViewModel by viewModels {
        ProfileViewModelFactory(userRepository)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize the repository in onCreate to avoid context issues
        try {
            val db = AppDatabase.getDatabase(requireContext())
            userRepository = UserRepository(db.userDao(), FirebaseFirestore.getInstance(), requireContext())
        } catch (e: Exception) {
            Log.e("ProfileFragment", "Error initializing repository: ${e.message}")
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentProfileBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        setupObservers()
        setupClickListeners()
        loadUserData()
    }

    private fun setupObservers() {
        viewLifecycleOwner.lifecycleScope.launch {
            viewModel.userProfile.collect { user ->
                try {
                    if (user != null) {
                        binding.tvName.text = user.name ?: "Name not available"
                        binding.tvEmail.text = user.email ?: "Email not available"
                        binding.tvPhone.text = user.phone ?: "Phone not available"
                        Log.d("ProfileFragment", "User data loaded: ${user.name}")
                    } else {
                        // Show default values if no user found
                        binding.tvName.text = "User not found"
                        binding.tvEmail.text = "Email not available"
                        binding.tvPhone.text = "Phone not available"
                        Log.w("ProfileFragment", "No user data found")
                    }
                } catch (e: Exception) {
                    Log.e("ProfileFragment", "Error updating UI: ${e.message}")
                    showErrorState()
                }
            }
        }
    }

    private fun loadUserData() {
        try {
            val currentUser = FirebaseAuth.getInstance().currentUser
            if (currentUser != null) {
                val userId = currentUser.uid
                Log.d("ProfileFragment", "Loading profile for user: $userId")
                viewModel.loadUserProfile(userId)
            } else {
                Log.w("ProfileFragment", "No authenticated user found")
                showErrorState()
            }
        } catch (e: Exception) {
            Log.e("ProfileFragment", "Error loading user data: ${e.message}")
            showErrorState()
        }
    }

    private fun setupClickListeners() {
        // Sign out button
        binding.btnLogout.setOnClickListener {
            showLogoutConfirmationDialog()
        }
    }

    private fun showLogoutConfirmationDialog() {
        android.app.AlertDialog.Builder(requireContext())
            .setTitle("Sign Out")
            .setMessage("Are you sure you want to sign out?")
            .setPositiveButton("Yes") { _, _ ->
                performLogout()
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun performLogout() {
        try {
            // Sign out from Firebase
            FirebaseAuth.getInstance().signOut()

            // Clear local data if necessary
            clearLocalData()

            // Navigate to login
            navigateToLogin()

            Log.d("ProfileFragment", "User logged out successfully")
        } catch (e: Exception) {
            Log.e("ProfileFragment", "Error during logout: ${e.message}")
            android.widget.Toast.makeText(
                requireContext(),
                "Error signing out: ${e.message}",
                android.widget.Toast.LENGTH_SHORT
            ).show()
        }
    }

    private fun clearLocalData() {
        try {
            // Clear SharedPreferences (important for your persistence system)
            val sharedPref = requireActivity().getSharedPreferences("user_prefs", android.content.Context.MODE_PRIVATE)
            sharedPref.edit()
                .putBoolean("is_logged_in", false)
                .clear()
                .apply()

            // Clear local database if necessary
            val db = AppDatabase.getDatabase(requireContext())
            // Here you can add logic to clear specific data if necessary

        } catch (e: Exception) {
            Log.e("ProfileFragment", "Error clearing local data: ${e.message}")
        }
    }

    private fun navigateToLogin() {
        try {
            // Option 1: If using Navigation Component
            // findNavController().navigate(R.id.action_profile_to_login)

            // Option 2: If using direct Activity (more common for login)
            val intent = android.content.Intent(requireContext(), getLoginActivityClass())
            intent.flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK or android.content.Intent.FLAG_ACTIVITY_CLEAR_TASK
            startActivity(intent)
            requireActivity().finish()

        } catch (e: Exception) {
            Log.e("ProfileFragment", "Error navigating to login: ${e.message}")
            // Fallback: close the application
            requireActivity().finishAffinity()
        }
    }

    private fun getLoginActivityClass(): Class<*> {
        return com.example.uni_matketplace_kotlin.ui.auth.LoginActivity::class.java
    }

    private fun showErrorState() {
        binding.tvName.text = "Error loading data"
        binding.tvEmail.text = "Please try again later"
        binding.tvPhone.text = ""
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}