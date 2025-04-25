package com.example.uni_matketplace_kotlin.ui.createproduct

import android.os.Bundle
import android.view.*
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import androidx.core.widget.doAfterTextChanged
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import com.example.uni_matketplace_kotlin.databinding.FragmentCreateproductBinding
import com.google.firebase.firestore.FirebaseFirestore

class CreateProductFragment : Fragment() {

    private var _binding: FragmentCreateproductBinding? = null
    private val binding get() = _binding!!

    private val viewModel: CreateProductViewModel by viewModels {
        CreateProductViewModelFactory(FirebaseFirestore.getInstance())
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setHasOptionsMenu(true)
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentCreateproductBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        (requireActivity() as AppCompatActivity).supportActionBar?.apply {
            setDisplayHomeAsUpEnabled(true)
            title = "Crear producto"
        }

        fun updateValidation() {
            val title = binding.etProductName.text.toString()
            val description = binding.etDescription.text.toString()
            val category = binding.etCategory.text.toString()
            val price = binding.etPrice.text.toString()
            val types = mutableListOf<String>().apply {
                if (binding.cbRental.isChecked) add("rental")
                if (binding.cbBuy.isChecked) add("buy")
                if (binding.cbBid.isChecked) add("bid")
                if (binding.cbEarn.isChecked) add("earn")
            }
            viewModel.validateForm(title, description, category, price, types)
        }

        listOf(
            binding.etProductName,
            binding.etDescription,
            binding.etCategory,
            binding.etPrice
        ).forEach { editText ->
            editText.doAfterTextChanged { updateValidation() }
        }

        listOf(
            binding.cbRental,
            binding.cbBuy,
            binding.cbBid,
            binding.cbEarn
        ).forEach { checkBox ->
            checkBox.setOnCheckedChangeListener { _, _ -> updateValidation() }
        }

        viewModel.isFormValid.observe(viewLifecycleOwner) { isValid ->
            binding.btnPost.isEnabled = isValid
            if (!isValid) {
                binding.btnPost.setOnClickListener {
                    Toast.makeText(context, "Completa todos los campos correctamente", Toast.LENGTH_SHORT).show()
                }
            } else {
                binding.btnPost.setOnClickListener {
                    val title = binding.etProductName.text.toString()
                    val description = binding.etDescription.text.toString()
                    val category = binding.etCategory.text.toString()
                    val price = binding.etPrice.text.toString().toIntOrNull() ?: 0
                    val types = mutableListOf<String>().apply {
                        if (binding.cbRental.isChecked) add("rental")
                        if (binding.cbBuy.isChecked) add("buy")
                        if (binding.cbBid.isChecked) add("bid")
                        if (binding.cbEarn.isChecked) add("earn")
                    }

                    val ownerId = "user-id-aqui" // Lógica de autenticación

                    viewModel.createProduct(
                        title,
                        description,
                        category,
                        price,
                        types,
                        ownerId,
                        onSuccess = {
                            Toast.makeText(context, "Producto publicado con éxito", Toast.LENGTH_SHORT).show()
                            requireActivity().onBackPressedDispatcher.onBackPressed()
                        },
                        onFailure = {
                            Toast.makeText(context, "Error al publicar: ${it.message}", Toast.LENGTH_SHORT).show()
                        }
                    )
                }
            }
        }

        requireActivity().onBackPressedDispatcher.addCallback(viewLifecycleOwner, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                requireActivity().supportFragmentManager.popBackStack()
            }
        })
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

