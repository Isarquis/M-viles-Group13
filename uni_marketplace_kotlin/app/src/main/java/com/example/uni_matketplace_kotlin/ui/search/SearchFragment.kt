package com.example.uni_matketplace_kotlin.ui.search

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.uni_marketplace_kotlin.ui.search.SearchViewModel
import com.example.uni_marketplace_kotlin.ui.search.adapter.ProductAdapter
import com.example.uni_matketplace_kotlin.databinding.FragmentSearchBinding

class SearchFragment : Fragment() {

    private var _binding: FragmentSearchBinding? = null
    private val binding get() = _binding!!

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

        setupRecyclerView()
        setupFilters()
        setupListeners()
        observeViewModel()
    }

    private fun setupRecyclerView() {
        adapter = ProductAdapter()
        binding.rvProducts.layoutManager = LinearLayoutManager(requireContext())
        binding.rvProducts.adapter = adapter
    }

    private fun setupFilters() {
        val categories = listOf("Math", "Science", "History", "Other")
        val categoryAdapter = ArrayAdapter(requireContext(), android.R.layout.simple_spinner_item, categories)
        categoryAdapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        binding.spinnerCategory.adapter = categoryAdapter
    }

    private fun setupListeners() {
        binding.btnBuy.setOnClickListener {
            viewModel.setTypeFilter("buy")
        }

        binding.btnRent.setOnClickListener {
            viewModel.setTypeFilter("rent")
        }

        binding.btnSearch.setOnClickListener {
            val query = binding.etSearch.text.toString()
            val category = binding.spinnerCategory.selectedItem?.toString() ?: ""
            if (query.isBlank()) {
                Toast.makeText(requireContext(), "Please enter something to search.", Toast.LENGTH_SHORT).show()
            } else {
                viewModel.searchProducts(query, category)
            }
        }
    }

    private fun observeViewModel() {
        viewModel.products.observe(viewLifecycleOwner) { products ->
            adapter.submitList(products)
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
