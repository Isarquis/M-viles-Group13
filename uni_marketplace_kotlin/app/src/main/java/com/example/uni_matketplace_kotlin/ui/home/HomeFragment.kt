package com.example.uni_matketplace_kotlin.ui.home

import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.example.uni_matketplace_kotlin.R
import com.example.uni_matketplace_kotlin.databinding.FragmentHomeBinding
import com.example.uni_matketplace_kotlin.ui.auth.LoginActivity
import com.example.uni_matketplace_kotlin.data.remote.entities.Product
import com.google.firebase.database.DataSnapshot
import com.google.firebase.database.DatabaseError
import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.database.ValueEventListener

class HomeFragment : Fragment() {

    private lateinit var _binding: FragmentHomeBinding
    private val binding get() = _binding

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentHomeBinding.inflate(inflater, container, false)
        val root: View = binding.root

        val recyclerView: RecyclerView = root.findViewById(R.id.recyclerViewCards)
        recyclerView.layoutManager = LinearLayoutManager(context)

        val productList = mutableListOf<Product>()

        val database = FirebaseDatabase.getInstance()
        val myRef = database.getReference("items")

        myRef.addValueEventListener(object : ValueEventListener {
            override fun onDataChange(dataSnapshot: DataSnapshot) {
                productList.clear()
                for (snapshot in dataSnapshot.children) {
                    val product = snapshot.getValue(Product::class.java)
                    product?.let { productList.add(it) }
                }
                recyclerView.adapter = HomeCardmanager(productList)
            }

            override fun onCancelled(error: DatabaseError) {
                // Maneja errores
            }
        })
        return root
    }

    override fun onDestroyView() {
        super.onDestroyView()
        //_binding = null
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        binding.buttonActivity2.setOnClickListener {
            // Cerrar sesión
            val sharedPreferences: SharedPreferences = requireActivity().getSharedPreferences("user_prefs", android.content.Context.MODE_PRIVATE)
            val editor = sharedPreferences.edit()
            editor.putBoolean("is_logged_in", false)
            editor.apply()

            // Redirigir al LoginActivity
            val intent = Intent(requireContext(), LoginActivity::class.java)
            startActivity(intent)
            requireActivity().finish() // Opcionalmente cerrar la actividad actual
        }
    }
}
