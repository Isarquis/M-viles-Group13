package com.example.uni_matketplace_kotlin.data.repositories

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore

object SessionLogRepository {

    private val firestore = FirebaseFirestore.getInstance()

    fun logSessionEvent(event: String, section: String) {
        val userId = FirebaseAuth.getInstance().currentUser?.uid ?: return

        val log = hashMapOf(
            "type" to "session_event",
            "event" to event,
            "timestamp" to System.currentTimeMillis(),
            "section" to section,
            "user_id" to userId
        )

        firestore.collection("logs")
            .add(log)
            .addOnSuccessListener {
                // Optional: log success
            }
            .addOnFailureListener { e ->
                // Optional: log error
            }
    }
}
