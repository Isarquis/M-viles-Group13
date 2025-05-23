package com.example.uni_matketplace_kotlin.ui.profile

import com.google.firebase.auth.FirebaseAuth
import com.example.uni_matketplace_kotlin.viewmodel.ProfileViewModelFactory

import android.os.Bundle
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

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentProfileBinding.inflate(inflater, container, false)

        val db = AppDatabase.getDatabase(requireContext())
        userRepository = UserRepository(db.userDao(), FirebaseFirestore.getInstance(), requireContext())

        val userId = FirebaseAuth.getInstance().currentUser?.uid ?: ""
        viewModel.loadUserProfile(userId)

        lifecycleScope.launch {
            viewModel.userProfile.collect { user ->
                user?.let {
                    binding.tvName.text = it.name
                    binding.tvEmail.text = it.email
                    binding.tvPhone.text = it.phone
                }
            }
        }

        return binding.root
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
