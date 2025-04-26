package com.example.uni_matketplace_kotlin.ui.search

import AnalyticsRepository
import android.os.Bundle
import android.view.LayoutInflater
import android.view.MenuItem
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.uni_marketplace_kotlin.ui.search.adapter.ProductAdapter
import com.example.uni_matketplace_kotlin.data.repositories.ProductRepository
import com.example.uni_matketplace_kotlin.databinding.FragmentSearchBinding
import com.example.uni_matketplace_kotlin.ui.viewmodel.SearchViewModel
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch
@AndroidEntryPoint
class SearchFragment : Fragment() {

    private var _binding: FragmentSearchBinding? = null
    private val binding get() = _binding!!
    private var featureUsageId: String? = null
    private val analyticsRepository = AnalyticsRepository()
    private val viewModel: SearchViewModel by viewModels()

    private lateinit var adapter: ProductAdapter

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentSearchBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        setHasOptionsMenu(true)
        (requireActivity() as AppCompatActivity).supportActionBar?.apply {
            setDisplayHomeAsUpEnabled(true)
            title = "Buscar productos"
        }
        requireActivity().onBackPressedDispatcher.addCallback(viewLifecycleOwner, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                requireActivity().supportFragmentManager.popBackStack()
            }
        })

        setupRecyclerView()
        setupListeners()
        observeViewModel()
        viewModel.loadFirstProducts()

        viewModel.loadProductsByType("")
    }

    private fun setupRecyclerView() {
        adapter = ProductAdapter()
        binding.rvProducts.layoutManager = LinearLayoutManager(requireContext())
        binding.rvProducts.adapter = adapter
    }

    private fun setupListeners() {
        binding.btnBuy.setOnClickListener {
            viewModel.loadProductsByType("Buy")
        }

        binding.btnRent.setOnClickListener {
            viewModel.loadProductsByType("Rent")
        }

        binding.btnEarn.setOnClickListener {
            viewModel.loadProductsByType("Earn")
        }
    }

    private fun observeViewModel() {

        viewModel.loading.observe(viewLifecycleOwner) { isLoading ->
            binding.progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
        }
        viewModel.firstProducts.observe(viewLifecycleOwner) { products ->
            if(products.isNotEmpty()){
                adapter.submitList(products)
            }
        }
        viewModel.products.observe(viewLifecycleOwner) { products ->
            if (products.isEmpty()) {
                Toast.makeText(requireContext(), "No se encontraron productos.", Toast.LENGTH_SHORT).show()
            }
            adapter.submitList(products)
        }

        viewModel.error.observe(viewLifecycleOwner) { errorMessage ->
            errorMessage?.let {
                Toast.makeText(requireContext(), it, Toast.LENGTH_SHORT).show()
            }
        }
    }
    override fun onResume() {
        super.onResume()
        featureUsageId = analyticsRepository.saveFeatureEntry("DiscoveryScreen")
    }

    override fun onPause() {
        super.onPause()
        featureUsageId?.let { id ->
            analyticsRepository.saveFeatureExit(id)
        }
    }
    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            android.R.id.home -> {
                requireActivity().onBackPressedDispatcher.onBackPressed()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}




