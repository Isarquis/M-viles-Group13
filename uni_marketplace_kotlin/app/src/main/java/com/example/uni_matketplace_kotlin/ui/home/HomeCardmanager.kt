package com.example.uni_matketplace_kotlin.ui.home

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.example.uni_matketplace_kotlin.R
import com.example.uni_matketplace_kotlin.data.model.Product

class HomeCardmanager(private val Products: List<Product>) : RecyclerView.Adapter<HomeCardmanager.ViewHolder>() {

    inner class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
        val title: TextView = view.findViewById(R.id.title)
        val description: TextView = view.findViewById(R.id.description)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.fragment_home_cards, parent, false)
        return ViewHolder(view)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.title.text = Products[position].title
        holder.description.text = Products[position].description
    }

    override fun getItemCount(): Int = Products.size
}