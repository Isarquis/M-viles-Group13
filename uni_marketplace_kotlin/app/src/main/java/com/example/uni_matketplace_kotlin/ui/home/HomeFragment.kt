package com.example.uni_matketplace_kotlin.ui.home

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.Toast
import androidx.appcompat.widget.SearchView
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.uni_matketplace_kotlin.R
import com.example.uni_matketplace_kotlin.databinding.FragmentHomeBinding
import com.example.uni_matketplace_kotlin.data.remote.entities.Product
import com.example.uni_matketplace_kotlin.ui.search.Adapter.ProductAdapter
import com.google.firebase.auth.FirebaseAuth
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class HomeFragment : Fragment() {

    private var _binding: FragmentHomeBinding? = null
    private val binding get() = _binding!!

    private val viewModel: HomeViewModel by viewModels()
    private lateinit var recommendedAdapter: ProductAdapter
    private lateinit var recentAdapter: ProductAdapter

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentHomeBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        setupRecyclerViews()
        setupSwipeRefresh()
        observeViewModel()
        loadProducts()
    }

    private fun setupRecyclerViews() {
        // Adapter for recommended products (horizontal)
        recommendedAdapter = ProductAdapter { productId, attribute ->
            handleProductClick(productId, attribute)
        }

        // Adapter for recent products (horizontal)
        recentAdapter = ProductAdapter { productId, attribute ->
            handleProductClick(productId, attribute)
        }

        // Configure RecyclerViews
        binding.recommendedRecyclerView.apply {
            layoutManager = LinearLayoutManager(context, LinearLayoutManager.HORIZONTAL, false)
            adapter = recommendedAdapter
        }

        binding.recentRecyclerView.apply {
            layoutManager = LinearLayoutManager(context, LinearLayoutManager.HORIZONTAL, false)
            adapter = recentAdapter
        }
    }

    private fun setupSwipeRefresh() {
        binding.swipeRefreshLayout.setOnRefreshListener {
            viewModel.refreshProducts()
        }
    }

    private fun loadProducts() {
        viewModel.loadProductsFromFirebase()
    }

    private fun observeViewModel() {
        viewModel.loading.observe(viewLifecycleOwner) { isLoading ->
            binding.swipeRefreshLayout.isRefreshing = isLoading
        }

        viewModel.recommendedProducts.observe(viewLifecycleOwner) { products ->
            recommendedAdapter.submitList(products)
            // Show/hide recommended section
            binding.recommendedSection.visibility =
                if (products.isNotEmpty()) View.VISIBLE else View.GONE
        }

        viewModel.recentProducts.observe(viewLifecycleOwner) { products ->
            recentAdapter.submitList(products)
            // Show/hide recent section
            binding.recentSection.visibility =
                if (products.isNotEmpty()) View.VISIBLE else View.GONE
        }

        viewModel.isOffline.observe(viewLifecycleOwner) { offline ->
            showOfflineIndicator(offline)
        }

        viewModel.error.observe(viewLifecycleOwner) { errorMessage ->
            errorMessage?.let {
                Toast.makeText(requireContext(), it, Toast.LENGTH_SHORT).show()
                viewModel.clearError()
            }
        }
    }

    private fun showOfflineIndicator(show: Boolean) {
        binding.offlineIndicator.visibility = if (show) View.VISIBLE else View.GONE
    }

    private fun handleProductClick(productId: String, attribute: String) {
        // Only register the click, no navigation
        viewModel.incrementClickCounter(attribute)

        // Show temporary message
        Toast.makeText(
            requireContext(),
            "Clicked on $attribute of product: $productId",
            Toast.LENGTH_SHORT
        ).show()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}