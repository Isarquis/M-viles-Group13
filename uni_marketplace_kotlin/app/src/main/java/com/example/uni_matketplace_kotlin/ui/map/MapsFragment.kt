package com.example.uni_matketplace_kotlin.ui.map

import AnalyticsRepository
import SessionViewModel
import android.Manifest
import android.content.pm.PackageManager
import android.location.Location
import android.os.Bundle
import android.view.LayoutInflater
import android.view.MenuItem
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.ViewModelProvider
import com.example.uni_matketplace_kotlin.R
import com.example.uni_matketplace_kotlin.databinding.FragmentMapsBinding
import com.example.uni_matketplace_kotlin.data.LocationHelper
import com.example.uni_matketplace_kotlin.data.repositories.ProductRepository
import com.example.uni_matketplace_kotlin.data.repositories.UserRepository
import com.example.uni_matketplace_kotlin.utils.NetworkUtils
import com.example.uni_matketplace_kotlin.viewmodel.MapsViewModel
import com.example.uni_matketplace_kotlin.viewmodel.MapsViewModelFactory
import com.google.android.gms.location.LocationServices
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.SupportMapFragment
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.MarkerOptions

class MapsFragment : Fragment(), OnMapReadyCallback, GoogleMap.OnMyLocationButtonClickListener, GoogleMap.OnMyLocationClickListener {

    private var _binding: FragmentMapsBinding? = null
    private val binding get() = _binding!!
    private lateinit var mMap: GoogleMap
    private var featureUsageId: String? = null
    private val analyticsRepository = AnalyticsRepository()
    private val mapsViewModel: MapsViewModel by viewModels {
        MapsViewModelFactory(requireContext())
    }

    private var closestUserMarker: com.google.android.gms.maps.model.Marker? = null
    private val nearbyMarkers = mutableListOf<com.google.android.gms.maps.model.Marker>()
    private val sessionViewModel: SessionViewModel by viewModels()

    companion object {
        private const val REQUEST_CODE_LOCATION = 1
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
    ): View {
        _binding = FragmentMapsBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        setHasOptionsMenu(true)

        val mapFragment = childFragmentManager.findFragmentById(R.id.map) as SupportMapFragment
        mapFragment.getMapAsync(this)

        observeNearUsers()
        observerClosestUser()
        observerClosestProduct()

        (requireActivity() as AppCompatActivity).supportActionBar?.apply {
            setDisplayHomeAsUpEnabled(true)
            title = "Productos cerca a ti"
        }

        if (!NetworkUtils.isOnline(requireContext())) {
            Toast.makeText(requireContext(), "Sin conexión. Mostrando datos almacenados.", Toast.LENGTH_LONG).show()
        }
    }


    override fun onMapReady(googleMap: GoogleMap) {
        mMap = googleMap
        mMap.setOnMyLocationButtonClickListener(this)
        mMap.setOnMyLocationClickListener(this)
        enableMyLocation()

        moverCamaraALaUbicacion { currentLocation ->
            mMap.animateCamera(CameraUpdateFactory.newLatLngZoom(currentLocation, 14.0f))
            mapsViewModel.loadNearbyUsers(currentLocation)
            mapsViewModel.loadClosestProduct(currentLocation)
            mapsViewModel.loadClosestUser(currentLocation)
        }
    }

    // Anaalytics Pipeline
    override fun onResume() {
        super.onResume()
        sessionViewModel.logEvent("enter", "map")
    }

    override fun onPause() {
        super.onPause()
        sessionViewModel.logEvent("exit", "map")
    }

    //Addition
    private fun moverCamaraALaUbicacion(callback: (LatLng) -> Unit) {
        if (!isPermissionsGranted()) return

        if (LocationHelper.isLocationEnabled(requireContext())) {
            val fusedLocationClient = LocationServices.getFusedLocationProviderClient(requireContext())
            fusedLocationClient.lastLocation.addOnSuccessListener { location: Location? ->
                location?.let {
                    val latLng = LatLng(it.latitude, it.longitude)
                    LocationHelper.saveLastLocation(requireContext(), it)
                    callback(latLng)
                }
            }
        } else {
            val savedLatLng = LocationHelper.getLastSavedLocation(requireContext())
            if (savedLatLng != null) {
                Toast.makeText(requireContext(), "Sin Ubicación. Mostrando última ubicación conocida", Toast.LENGTH_SHORT).show()
                callback(savedLatLng)
            } else {
                Toast.makeText(requireContext(), "Ubicación no disponible", Toast.LENGTH_SHORT).show()
            }
        }
    }


    //Permissions

    private fun isPermissionsGranted(): Boolean {
        return ContextCompat.checkSelfPermission(requireContext(), Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
    }

    private fun enableMyLocation() {
        if (!::mMap.isInitialized) return
        if (isPermissionsGranted()) {
            if (ActivityCompat.checkSelfPermission(requireContext(), Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) return
            mMap.isMyLocationEnabled = true
        } else {
            requestPermissions(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION), REQUEST_CODE_LOCATION)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        if (requestCode == REQUEST_CODE_LOCATION && grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            enableMyLocation()
        } else {
            Toast.makeText(requireContext(), "Permiso requerido para mostrar tu ubicación", Toast.LENGTH_SHORT).show()
        }
    }

    override fun onMyLocationClick(location: Location) {
        Toast.makeText(requireContext(), "Estás en: ${location.latitude}, ${location.longitude}", Toast.LENGTH_SHORT).show()
    }

    override fun onMyLocationButtonClick(): Boolean = false

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    //Obsevers

    private fun observerClosestUser(){
        mapsViewModel.closestUser.observe(viewLifecycleOwner) { user ->
            if (user?.location != null && ::mMap.isInitialized) {
                val userLatLng = LatLng(user.location.latitude, user.location.longitude)
                closestUserMarker?.remove()
                closestUserMarker = mMap.addMarker(
                    MarkerOptions()
                        .position(userLatLng)
                        .title(user.name)
                        .snippet("Tel: ${user.phone}")
                )
                mMap.animateCamera(CameraUpdateFactory.newLatLngZoom(userLatLng, 15f))
                binding.userName.text = user.name
                binding.userContact.text = user.phone
            }
        }
    }

    private fun observerClosestProduct() {
        mapsViewModel.closestProduct.observe(viewLifecycleOwner) { product ->
            if (product != null) {
                binding.productName.text = "Producto: ${product.title}"
                binding.userPrice.text = "Precio: ${product.price}"
                mapsViewModel.distanceToClosestUser.observe(viewLifecycleOwner) { distance ->
                    binding.userDistance.text = "Distance to you: ${"%.0f".format(distance)}m"
                }
            } else {
                closestUserMarker?.remove()
                closestUserMarker = null
                binding.productName.text = "No hay productos cerca"
                binding.userPrice.text = ""
                binding.userContact.text = ""
                binding.userName.text = ""
                binding.userDistance.text = ""
            }
        }
    }

    private fun observeNearUsers() {
        mapsViewModel.nearbyUsers.observe(viewLifecycleOwner) { users ->
            // Limpiar marcadores anteriores
            nearbyMarkers.forEach { it.remove() }
            nearbyMarkers.clear()

            // Agregar nuevos marcadores
            users.forEach { user ->
                val userLatLng = LatLng(user.location.latitude, user.location.longitude)
                val marker = mMap.addMarker(
                    MarkerOptions()
                        .position(userLatLng)
                        .title(user.name)
                        .snippet("Contacto: ${user.phone}")
                )
                marker?.let { nearbyMarkers.add(it) }
            }
        }
    }
    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            android.R.id.home -> {
                activity?.onBackPressed()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }


}
