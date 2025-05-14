package com.example.uni_matketplace_kotlin.ui.search

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.os.Bundle
import android.view.LayoutInflater
import android.view.MenuItem
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.uni_matketplace_kotlin.ui.search.Adapter.ProductAdapter
import com.example.uni_matketplace_kotlin.databinding.FragmentSearchBinding
import com.example.uni_matketplace_kotlin.viewmodel.SearchViewModel
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class SearchFragment : Fragment() {

    private var _binding: FragmentSearchBinding? = null
    private val binding get() = _binding!!
    private val viewModel: SearchViewModel by viewModels()

    private lateinit var adapter: ProductAdapter

    // BroadcastReceiver para escuchar cambios en la conexión
    private val internetReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val isConnected = isInternetAvailable()
            if (isConnected) {
                // Mostrar un Toast cuando la conexión regrese
                Toast.makeText(requireContext(), "Conexión a Internet restaurada", Toast.LENGTH_SHORT).show()

                // Actualizar los productos cuando se restablezca la conexión
                viewModel.loadAndSaveProducts()
            }
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentSearchBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        // Registrar el receptor para detectar cambios en la conexión
        requireContext().registerReceiver(internetReceiver, IntentFilter(ConnectivityManager.CONNECTIVITY_ACTION))

        // Configuración del ActionBar
        setHasOptionsMenu(true)
        (requireActivity() as AppCompatActivity).supportActionBar?.apply {
            setDisplayHomeAsUpEnabled(true)
            title = "Buscar productos"
        }

        // Configuración del RecyclerView
        setupRecyclerView()
        setupListeners()
        observeViewModel()

        // Cargar productos iniciales
        viewModel.loadFirstProducts()
        viewModel.loadProductsByType("")
    }

    override fun onDestroyView() {
        super.onDestroyView()
        // Desregistrar el receptor para cambios de conexión cuando se destruye la vista
        requireContext().unregisterReceiver(internetReceiver)
        _binding = null
    }

    private fun setupRecyclerView() {
        adapter = ProductAdapter { productId, attribute ->
            viewModel.incrementClickCounter(attribute)
        }

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
            if (products.isNotEmpty()) {
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

    // Verificar si hay conexión a internet
    private fun isInternetAvailable(): Boolean {
        val connectivityManager = requireContext().getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val networkInfo = connectivityManager.activeNetworkInfo
        return networkInfo != null && networkInfo.isConnected
    }

    // Regresar al fragmento anterior al presionar el icono de "home"
    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            android.R.id.home -> {
                requireActivity().onBackPressedDispatcher.onBackPressed()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }
}
