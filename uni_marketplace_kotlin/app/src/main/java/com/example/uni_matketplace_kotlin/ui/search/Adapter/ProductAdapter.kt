package com.example.uni_matketplace_kotlin.ui.search.Adapter


import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.example.uni_matketplace_kotlin.data.remote.entities.Product
import com.example.uni_matketplace_kotlin.databinding.ItemProductBinding

class ProductAdapter(
    private val onAttributeClick: (productId: String, attribute: String) -> Unit
) : RecyclerView.Adapter<ProductAdapter.ProductViewHolder>() {

    private val productList = mutableListOf<Product>()

    inner class ProductViewHolder(private val binding: ItemProductBinding) :
        RecyclerView.ViewHolder(binding.root) {

        fun bind(product: Product) {
            binding.tvTitle.text = product.title
            binding.tvPrice.text = "$${product.price}"
            binding.tvCategory.text = product.category

            Glide.with(binding.ivProduct.context)
                .load(product.image)
                .into(binding.ivProduct)

            // Click listeners por atributo:
            binding.ivProduct.setOnClickListener {
                onAttributeClick(product.id, "image")
            }
            binding.tvTitle.setOnClickListener {
                onAttributeClick(product.id, "title")
            }
            binding.tvPrice.setOnClickListener {
                onAttributeClick(product.id, "price")
            }
            binding.tvCategory.setOnClickListener {
                onAttributeClick(product.id, "category")
            }
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ProductViewHolder {
        val binding = ItemProductBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return ProductViewHolder(binding)
    }

    override fun getItemCount(): Int = productList.size

    override fun onBindViewHolder(holder: ProductViewHolder, position: Int) {
        holder.bind(productList[position])
    }

    fun submitList(newList: List<Product>) {
        productList.clear()
        productList.addAll(newList)
        notifyDataSetChanged()
    }
}
