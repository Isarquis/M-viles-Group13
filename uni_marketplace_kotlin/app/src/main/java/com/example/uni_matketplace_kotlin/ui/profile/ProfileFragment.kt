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
import android.os.SystemClock
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.concurrent.ConcurrentHashMap

class ProfileFragment : Fragment() {

    private var _binding: FragmentProfileBinding? = null
    private val binding get() = _binding!!

    private lateinit var userRepository: UserRepository
    private val viewModel: ProfileViewModel by viewModels {
        ProfileViewModelFactory(userRepository)
    }


    private val performanceMetrics = ConcurrentHashMap<String, Long>()
    private var fragmentCreateTime: Long = 0
    private var dataLoadStartTime: Long = 0


    private val stringCache = mutableMapOf<String, String>()
    private var currentUserId: String? = null


    private val firebaseAuth by lazy { FirebaseAuth.getInstance() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        fragmentCreateTime = SystemClock.elapsedRealtime()


        try {
            val repoInitStart = SystemClock.elapsedRealtime()
            val db = AppDatabase.getDatabase(requireContext())
            userRepository = UserRepository(db.userDao(), FirebaseFirestore.getInstance(), requireContext())

            val repoInitTime = SystemClock.elapsedRealtime() - repoInitStart
            logPerformanceMetric("REPOSITORY_INIT_TIME", repoInitTime)

        } catch (e: Exception) {
            Log.e("ProfileFragment", "Error initializing repository: ${e.message}")
            logError("REPOSITORY_INIT_ERROR", e)
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        val viewCreateStart = SystemClock.elapsedRealtime()

        _binding = FragmentProfileBinding.inflate(inflater, container, false)

        val viewCreateTime = SystemClock.elapsedRealtime() - viewCreateStart
        logPerformanceMetric("VIEW_CREATE_TIME", viewCreateTime)

        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        val setupStart = SystemClock.elapsedRealtime()

        setupObservers()
        setupClickListeners()
        loadUserData()

        val totalSetupTime = SystemClock.elapsedRealtime() - setupStart
        val totalFragmentTime = SystemClock.elapsedRealtime() - fragmentCreateTime

        logPerformanceMetric("SETUP_TIME", totalSetupTime)
        logPerformanceMetric("TOTAL_FRAGMENT_CREATION_TIME", totalFragmentTime)
    }

    private fun setupObservers() {
        val observerSetupStart = SystemClock.elapsedRealtime()

        viewLifecycleOwner.lifecycleScope.launch {
            viewModel.userProfile.collect { user ->
                try {
                    val uiUpdateStart = SystemClock.elapsedRealtime()

                    if (user != null) {
                        // MICROOPTIMIZATION: Cache formatted strings to avoid repeated operations
                        val userName = getCachedOrFormat("user_name", user.name ?: "Name not available")
                        val userEmail = getCachedOrFormat("user_email", user.email ?: "Email not available")
                        val userPhone = getCachedOrFormat("user_phone", user.phone ?: "Phone not available")

                        // MICROOPTIMIZATION: Batch UI updates to reduce layout passes
                        updateUIBatch(userName, userEmail, userPhone)

                        Log.d("ProfileFragment", "User data loaded: ${user.name}")

                        val dataLoadTime = if (dataLoadStartTime > 0) {
                            SystemClock.elapsedRealtime() - dataLoadStartTime
                        } else 0

                        logPerformanceMetric("DATA_LOAD_TIME", dataLoadTime)

                    } else {
                        showErrorState()
                        Log.w("ProfileFragment", "No user data found")
                        logPerformanceMetric("NO_USER_DATA", SystemClock.elapsedRealtime() - dataLoadStartTime)
                    }

                    val uiUpdateTime = SystemClock.elapsedRealtime() - uiUpdateStart
                    logPerformanceMetric("UI_UPDATE_TIME", uiUpdateTime)

                } catch (e: Exception) {
                    Log.e("ProfileFragment", "Error updating UI: ${e.message}")
                    logError("UI_UPDATE_ERROR", e)
                    showErrorState()
                }
            }
        }

        val observerSetupTime = SystemClock.elapsedRealtime() - observerSetupStart
        logPerformanceMetric("OBSERVER_SETUP_TIME", observerSetupTime)
    }

    private fun getCachedOrFormat(key: String, value: String): String {
        return stringCache.getOrPut(key) { value }
    }

    private fun updateUIBatch(name: String, email: String, phone: String) {
        binding.apply {
            tvName.text = name
            tvEmail.text = email
            tvPhone.text = phone
        }
    }

    private fun loadUserData() {
        try {
            dataLoadStartTime = SystemClock.elapsedRealtime()

            val currentUser = firebaseAuth.currentUser
            if (currentUser != null) {
                val userId = currentUser.uid


                if (currentUserId != userId) {
                    currentUserId = userId
                    stringCache.clear() // Clear cache when switching users

                    Log.d("ProfileFragment", "Loading profile for user: $userId")
                    viewModel.loadUserProfile(userId)
                } else {
                    Log.d("ProfileFragment", "User data already loaded for: $userId")
                }
            } else {
                Log.w("ProfileFragment", "No authenticated user found")
                showErrorState()
                logPerformanceMetric("NO_AUTH_USER", SystemClock.elapsedRealtime() - dataLoadStartTime)
            }
        } catch (e: Exception) {
            Log.e("ProfileFragment", "Error loading user data: ${e.message}")
            logError("DATA_LOAD_ERROR", e)
            showErrorState()
        }
    }

    private fun setupClickListeners() {
        binding.btnLogout.setOnClickListener {
            val logoutStart = SystemClock.elapsedRealtime()
            showLogoutConfirmationDialog()
            logPerformanceMetric("LOGOUT_DIALOG_SHOW_TIME", SystemClock.elapsedRealtime() - logoutStart)
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
        val logoutStart = SystemClock.elapsedRealtime()

        try {
            lifecycleScope.launch {
                // MICROOPTIMIZATION: Perform logout operations on background thread
                withContext(Dispatchers.IO) {
                    // Sign out from Firebase
                    firebaseAuth.signOut()

                    // Clear local data
                    clearLocalData()

                    val logoutTime = SystemClock.elapsedRealtime() - logoutStart
                    logPerformanceMetric("LOGOUT_OPERATION_TIME", logoutTime)
                }

                // Navigate on main thread
                withContext(Dispatchers.Main) {
                    navigateToLogin()
                    Log.d("ProfileFragment", "User logged out successfully")
                }
            }

        } catch (e: Exception) {
            Log.e("ProfileFragment", "Error during logout: ${e.message}")
            logError("LOGOUT_ERROR", e)
            android.widget.Toast.makeText(
                requireContext(),
                "Error signing out: ${e.message}",
                android.widget.Toast.LENGTH_SHORT
            ).show()
        }
    }

    private fun clearLocalData() {
        try {
            val clearStart = SystemClock.elapsedRealtime()

            // Clear SharedPreferences
            val sharedPref = requireActivity().getSharedPreferences("user_prefs", android.content.Context.MODE_PRIVATE)
            sharedPref.edit()
                .putBoolean("is_logged_in", false)
                .clear()
                .apply()

            // Clear caches
            stringCache.clear()
            currentUserId = null

            val clearTime = SystemClock.elapsedRealtime() - clearStart
            logPerformanceMetric("DATA_CLEAR_TIME", clearTime)

        } catch (e: Exception) {
            Log.e("ProfileFragment", "Error clearing local data: ${e.message}")
            logError("DATA_CLEAR_ERROR", e)
        }
    }

    private fun navigateToLogin() {
        try {
            val navigationStart = SystemClock.elapsedRealtime()

            val intent = android.content.Intent(requireContext(), getLoginActivityClass())
            intent.flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK or android.content.Intent.FLAG_ACTIVITY_CLEAR_TASK
            startActivity(intent)
            requireActivity().finish()

            val navigationTime = SystemClock.elapsedRealtime() - navigationStart
            logPerformanceMetric("NAVIGATION_TIME", navigationTime)

        } catch (e: Exception) {
            Log.e("ProfileFragment", "Error navigating to login: ${e.message}")
            logError("NAVIGATION_ERROR", e)
            requireActivity().finishAffinity()
        }
    }

    private fun getLoginActivityClass(): Class<*> {
        return com.example.uni_matketplace_kotlin.ui.auth.LoginActivity::class.java
    }

    private fun showErrorState() {
        // MICROOPTIMIZATION: Use cached error strings
        val errorName = getCachedOrFormat("error_name", "Error loading data")
        val errorEmail = getCachedOrFormat("error_email", "Please try again later")
        val errorPhone = getCachedOrFormat("error_phone", "")

        updateUIBatch(errorName, errorEmail, errorPhone)
    }

    // PROFILING STRATEGY 2: Comprehensive performance tracking
    private fun logPerformanceMetric(metricName: String, timeMs: Long) {
        performanceMetrics[metricName] = timeMs
        Log.d("PROFILE_PERFORMANCE", "$metricName: ${timeMs}ms")

        // Alert on performance issues
        when (metricName) {
            "TOTAL_FRAGMENT_CREATION_TIME" -> if (timeMs > 500) reportSlowFragmentCreation(timeMs)
            "DATA_LOAD_TIME" -> if (timeMs > 2000) reportSlowDataLoad(timeMs)
            "UI_UPDATE_TIME" -> if (timeMs > 100) reportSlowUIUpdate(timeMs)
        }
    }

    private fun logError(errorType: String, exception: Exception) {
        Log.e("PROFILE_ERROR", "$errorType: ${exception.message}", exception)
        // Could send to crash reporting service
    }

    private fun reportSlowFragmentCreation(timeMs: Long) {
        Log.w("PROFILE_PERFORMANCE", "Slow fragment creation detected: ${timeMs}ms")
    }

    private fun reportSlowDataLoad(timeMs: Long) {
        Log.w("PROFILE_PERFORMANCE", "Slow data load detected: ${timeMs}ms")
    }

    private fun reportSlowUIUpdate(timeMs: Long) {
        Log.w("PROFILE_PERFORMANCE", "Slow UI update detected: ${timeMs}ms")
    }

    override fun onPause() {
        super.onPause()
        // PROFILING: Log performance summary when leaving fragment
        logPerformanceSummary()
    }

    private fun logPerformanceSummary() {
        val summary = performanceMetrics.entries.joinToString(", ") { "${it.key}=${it.value}ms" }
        Log.i("PROFILE_PERFORMANCE_SUMMARY", summary)
    }

    override fun onDestroyView() {
        super.onDestroyView()

        // MICROOPTIMIZATION: Clean up resources
        stringCache.clear()
        performanceMetrics.clear()
        _binding = null
    }
}