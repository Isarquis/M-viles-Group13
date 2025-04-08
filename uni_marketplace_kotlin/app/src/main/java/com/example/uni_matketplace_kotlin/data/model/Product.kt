package com.example.uni_matketplace_kotlin.data.model

import java.sql.Time

data class Product (
    val id: String="",
    val baseBid: Int=0,
    val category: String="",
    val createdAt: Time=Time(0),
    val description: String="",
    val image: String="",
    val ownerId: Int=0,
    val price: Int=0,
    val status: String="",
    val title: String="",
    val type : String="",
    )

