package com.example.uni_matketplace_kotlin.ui.map

import android.Manifest
import android.content.pm.PackageManager
import android.location.Location
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import com.bumptech.glide.Glide
import com.example.uni_matketplace_kotlin.R
import com.example.uni_matketplace_kotlin.data.model.User
import com.example.uni_matketplace_kotlin.databinding.FragmentMapsBinding
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.SupportMapFragment
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.MarkerOptions
import com.google.android.gms.location.LocationServices

class MapsFragment : Fragment(R.layout.fragment_maps), OnMapReadyCallback, GoogleMap.OnMyLocationButtonClickListener,
    GoogleMap.OnMyLocationClickListener {

    private var _binding: FragmentMapsBinding? = null
    private val binding get() = _binding!!
    private lateinit var mMap: GoogleMap

    private val lugaresCercanos = listOf(
        LatLng(4.60971, -74.08175), // Bogotá
        LatLng(4.60312, -74.06725), // Lugar cercano 1
        LatLng(4.61022, -74.08533), // Lugar cercano 2
        LatLng(4.61852, -74.06575)  // Lugar cercano 3
    )

    companion object {
        const val REQUEST_CODE_LOCATION = 0
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
    ): View {
        _binding = FragmentMapsBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        val mapFragment = childFragmentManager.findFragmentById(R.id.map) as SupportMapFragment
        mapFragment.getMapAsync(this)
        binding.backButton.setOnClickListener {
            requireActivity().onBackPressedDispatcher.onBackPressed()
        }
        loadUserData()
    }

    override fun onMapReady(googleMap: GoogleMap) {
        mMap = googleMap
        createMarker()
        mMap.setOnMyLocationButtonClickListener(this)
        mMap.setOnMyLocationClickListener(this)
        enableMyLocation()
        for (lugar in lugaresCercanos) {
            mMap.addMarker(
                MarkerOptions()
                    .position(lugar)
                    .title("Lugar cercano")
            )
        }
        moverCamaraALaUbicacion { posicionActual ->
            for (lugar in lugaresCercanos) {
                val distancia = calcularDistancia(posicionActual, lugar)
                mMap.addMarker(
                    MarkerOptions()
                        .position(lugar)
                        .title("Lugar cercano")
                        .snippet("Distancia: ${distancia.toInt()} metros")
                )
            }
        }
    }

    private fun moverCamaraALaUbicacion(callback: (LatLng) -> Unit) {
        if (isPermissionsGranted()) {
            val fusedLocationClient =
                LocationServices.getFusedLocationProviderClient(requireContext())
            fusedLocationClient.lastLocation.addOnSuccessListener { location: Location? ->
                location?.let {
                    val posicion = LatLng(it.latitude, it.longitude)
                    mMap.animateCamera(CameraUpdateFactory.newLatLngZoom(posicion, 14.0f))
                    callback(posicion)
                }
            }
        }
    }

    private fun loadUserData() {
        val sampleUser = User(
            name = "Juan Herrera",
            distance = 50,
            price = "50.000 COP",
            contact = "323 122 3511",
            imageResId = R.drawable.user
        )
        binding.userName.text = sampleUser.name
        binding.userDistance.text = "Distance to you: ${sampleUser.distance}m"
        binding.userPrice.text = "Price: ${sampleUser.price}"
        binding.userContact.text = "Contact: ${sampleUser.contact}"
        binding.userImage.setImageResource(sampleUser.imageResId)
    }

    private fun createMarker() {
        val bogota = LatLng(4.60971, -74.08175)
        mMap.addMarker(MarkerOptions().position(bogota).title("Marker in Bogotá"))
        mMap.animateCamera(CameraUpdateFactory.newLatLngZoom(bogota, 12.0f), 4000, null)
    }

    private fun isPermissionsGranted(): Boolean {
        return (ContextCompat.checkSelfPermission(
            requireContext(),
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
                || ContextCompat.checkSelfPermission(
            requireContext(),
            Manifest.permission.ACCESS_COARSE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED)
    }

    private fun enableMyLocation() {
        if (!::mMap.isInitialized) return
        if (isPermissionsGranted()) {
            mMap.isMyLocationEnabled = true
            mMap.uiSettings.isMyLocationButtonEnabled = true
        } else {
            requestLocationPermission()
        }
    }

    private fun requestLocationPermission() {
        requestPermissions(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION), REQUEST_CODE_LOCATION)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CODE_LOCATION) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                enableMyLocation()
            } else {
                Toast.makeText(
                    requireContext(),
                    "Ve a ajustes y acepta los permisos",
                    Toast.LENGTH_SHORT
                ).show()
            }
        }
    }

    override fun onMyLocationButtonClick(): Boolean {
        Toast.makeText(requireContext(), "Botón Pulsado", Toast.LENGTH_SHORT).show()
        return false
    }

    override fun onMyLocationClick(p0: Location) {
        Toast.makeText(
            requireContext(),
            "Estás en ${p0.latitude}, ${p0.longitude}",
            Toast.LENGTH_SHORT
        ).show()
    }

    private fun calcularDistancia(ubicacion1: LatLng, ubicacion2: LatLng): Float {
        val resultados = FloatArray(1)
        Location.distanceBetween(
            ubicacion1.latitude, ubicacion1.longitude,
            ubicacion2.latitude, ubicacion2.longitude,
            resultados
        )
        return resultados[0]
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
