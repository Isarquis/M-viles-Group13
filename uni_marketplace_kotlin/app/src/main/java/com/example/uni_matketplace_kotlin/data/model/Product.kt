package com.example.uni_matketplace_kotlin.data.model

import java.util.ArrayList
import java.util.Date

data class Product (
    val id: String="",
    val baseBid: Int=0,
    val category: String="",
    val createdAt: Date= Date(0),
    val description: String="",
    val image: String="",
    val ownerId: String="",
    val price: Int=0,
    val status: String="",
    val title: String="",
    var type: List<String> = listOf(),
    )

