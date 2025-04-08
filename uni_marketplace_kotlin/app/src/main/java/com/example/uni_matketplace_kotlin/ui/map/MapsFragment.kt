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
import androidx.fragment.app.viewModels
import com.bumptech.glide.Glide
import com.example.uni_matketplace_kotlin.R
import com.example.uni_matketplace_kotlin.databinding.FragmentMapsBinding
import com.example.uni_matketplace_kotlin.viewmodel.MapsViewModel
import com.google.android.gms.location.LocationServices
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.SupportMapFragment
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.MarkerOptions

typealias GeoPoint = com.google.firebase.firestore.GeoPoint

class MapsFragment : Fragment(), OnMapReadyCallback, GoogleMap.OnMyLocationButtonClickListener, GoogleMap.OnMyLocationClickListener {

    private var _binding: FragmentMapsBinding? = null
    private val binding get() = _binding!!
    private lateinit var mMap: GoogleMap
    private val mapsViewModel: MapsViewModel by viewModels()

    companion object {
        private const val REQUEST_CODE_LOCATION = 1
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
    ): View? {
        _binding = FragmentMapsBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        val mapFragment = childFragmentManager.findFragmentById(R.id.map) as SupportMapFragment
        mapFragment.getMapAsync(this)

        mapsViewModel.closestUser.observe(viewLifecycleOwner) { user ->
            binding.userName.text = user?.name ?: "Nombre desconocido"
            binding.userContact.text = "Contact: ${user?.phone ?: "Desconocido"}"
        }

        mapsViewModel.closestProduct.observe(viewLifecycleOwner) { product ->
            binding.userPrice.text = (product?.price ?: "Precio desconocido").toString()
        }

        mapsViewModel.closestUser.observe(viewLifecycleOwner) { user ->
            binding.userName.text = user?.name ?: "Nombre desconocido"
            binding.userContact.text = user?.phone ?: "Contacto desconocido"

            user?.location?.let { geoPoint ->
                val userLatLng = LatLng(geoPoint.latitude, geoPoint.longitude)
                mMap.addMarker(
                    MarkerOptions()
                        .position(userLatLng)
                        .title("Producto cercano")
                )
            }
        }
        binding.backButton.setOnClickListener {
            requireActivity().onBackPressedDispatcher.onBackPressed()
        }

    }

    override fun onMapReady(googleMap: GoogleMap) {
        mMap = googleMap
        mMap.setOnMyLocationButtonClickListener(this)
        mMap.setOnMyLocationClickListener(this)
        enableMyLocation()
        moverCamaraALaUbicacion { posicionActual ->
            mMap.animateCamera(CameraUpdateFactory.newLatLngZoom(posicionActual, 14.0f))
            mapsViewModel.loadClosestProduct(posicionActual)
        }
    }

    private fun moverCamaraALaUbicacion(callback: (LatLng) -> Unit) {
        if (isPermissionsGranted()) {
            val fusedLocationClient =
                LocationServices.getFusedLocationProviderClient(requireContext())
            fusedLocationClient.lastLocation.addOnSuccessListener { location: Location? ->
                location?.let {
                    val posicion = LatLng(it.latitude, it.longitude)
                    callback(posicion)
                }
            }
        }
    }

    private fun isPermissionsGranted(): Boolean {
        return (ContextCompat.checkSelfPermission(
            requireContext(),
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED ||
                ContextCompat.checkSelfPermission(
                    requireContext(),
                    Manifest.permission.ACCESS_COARSE_LOCATION
                ) == PackageManager.PERMISSION_GRANTED)
    }

    private fun enableMyLocation() {
        if (!::mMap.isInitialized) return
        if (isPermissionsGranted()) {
            if (ActivityCompat.checkSelfPermission(
                    requireContext(),
                    Manifest.permission.ACCESS_FINE_LOCATION
                ) != PackageManager.PERMISSION_GRANTED &&
                ActivityCompat.checkSelfPermission(
                    requireContext(),
                    Manifest.permission.ACCESS_COARSE_LOCATION
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                return
            }
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
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
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

    override fun onMyLocationClick(location: Location) {
        Toast.makeText(
            requireContext(),
            "Estás en ${location.latitude}, ${location.longitude}",
            Toast.LENGTH_SHORT
        ).show()
    }

    override fun onMyLocationButtonClick(): Boolean {
        return false
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}