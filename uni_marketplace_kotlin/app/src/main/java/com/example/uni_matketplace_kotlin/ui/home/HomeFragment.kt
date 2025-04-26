package com.example.uni_matketplace_kotlin.ui.home

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProvider
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
import com.google.firebase.firestore.ktx.firestore
import com.google.firebase.ktx.Firebase

class HomeFragment : Fragment() {

    private lateinit var _binding: FragmentHomeBinding

    // This property is only valid between onCreateView and
    // onDestroyView.
    private val binding get() = _binding


    override fun onCreateView(

        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {

        _binding = FragmentHomeBinding.inflate(inflater, container, false)
        val root: View = binding.root

        val recyclerView:RecyclerView = root.findViewById(R.id.recyclerViewCards)
        recyclerView.layoutManager = LinearLayoutManager(context)

        val ProductList = mutableListOf<Product>()



        val database = FirebaseDatabase.getInstance()
        val myRef = database.getReference("items")

        myRef.addValueEventListener(object : ValueEventListener {
            override fun onDataChange(dataSnapshot: DataSnapshot) {
                ProductList.clear()
                for (snapshot in dataSnapshot.children) {
                    val product = snapshot.getValue(Product::class.java)
                    product?.let { ProductList.add(it) }
                }
                recyclerView.adapter = HomeCardmanager(ProductList)
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
            val intent = Intent(requireContext(), LoginActivity::class.java)
            startActivity(intent)
        }
    }
}