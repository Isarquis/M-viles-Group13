package com.example.uni_matketplace_kotlin.ui.map

import AnalyticsRepository
import SessionViewModel
import android.Manifest
import android.content.pm.PackageManager
import android.location.Location
import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.MenuItem
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.annotation.RequiresPermission
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

    // Inicialización segura del ViewModel con manejo de errores
    private val mapsViewModel: MapsViewModel by viewModels {
        try {
            Log.d(TAG, "Creating MapsViewModelFactory")
            MapsViewModelFactory(requireContext())
        } catch (e: Exception) {
            Log.e(TAG, "Error creating MapsViewModelFactory: ${e.message}", e)
            throw RuntimeException("Failed to initialize MapsViewModel", e)
        }
    }

    private var closestUserMarker: com.google.android.gms.maps.model.Marker? = null
    private val nearbyMarkers = mutableListOf<com.google.android.gms.maps.model.Marker>()
    private val sessionViewModel: SessionViewModel by viewModels()

    companion object {
        private const val REQUEST_CODE_LOCATION = 1
        private const val TAG = "MapsFragment"
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?
    ): View {
        _binding = FragmentMapsBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        try {
            Log.d(TAG, "onViewCreated started")
            setHasOptionsMenu(true)

            // Verificar que el fragment esté agregado antes de continuar
            if (!isAdded) {
                Log.w(TAG, "Fragment not added, skipping setup")
                return
            }

            initializeMap()
            setupObservers()
            setupActionBar()
            checkNetworkStatus()

        } catch (e: Exception) {
            Log.e(TAG, "Error in onViewCreated: ${e.message}", e)
            handleError("Error initializing map: ${e.message}")
        }
    }

    private fun initializeMap() {
        try {
            val mapFragment = childFragmentManager.findFragmentById(R.id.map) as? SupportMapFragment
            if (mapFragment == null) {
                Log.e(TAG, "MapFragment is null")
                handleError("Error loading map component")
                return
            }

            Log.d(TAG, "Requesting map async")
            mapFragment.getMapAsync(this)

        } catch (e: Exception) {
            Log.e(TAG, "Error initializing map: ${e.message}", e)
            handleError("Error setting up map: ${e.message}")
        }
    }

    private fun setupObservers() {
        try {
            Log.d(TAG, "Setting up observers")
            observeNearUsers()
            observerClosestUser()
            observerClosestProduct()
            observeErrors()
            observeLoading()
        } catch (e: Exception) {
            Log.e(TAG, "Error setting up observers: ${e.message}", e)
        }
    }

    private fun observeErrors() {
        mapsViewModel.errorMessage.observe(viewLifecycleOwner) { error ->
            if (error.isNotEmpty() && isAdded) {
                Log.e(TAG, "ViewModel error: $error")
                Toast.makeText(requireContext(), error, Toast.LENGTH_LONG).show()
                mapsViewModel.clearError()
            }
        }
    }

    private fun observeLoading() {
        mapsViewModel.isLoading.observe(viewLifecycleOwner) { isLoading ->
            // Aquí puedes mostrar/ocultar un loading indicator si tienes uno
            Log.d(TAG, "Loading state: $isLoading")
        }
    }

    private fun setupActionBar() {
        try {
            (requireActivity() as? AppCompatActivity)?.supportActionBar?.apply {
                setDisplayHomeAsUpEnabled(true)
                title = "Products nearby"
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error setting up action bar: ${e.message}", e)
        }
    }

    private fun checkNetworkStatus() {
        if (!NetworkUtils.isOnline(requireContext())) {
            Toast.makeText(requireContext(), "No conection, showing stored data.", Toast.LENGTH_LONG).show()
        }
    }

    private fun handleError(message: String) {
        if (isAdded && _binding != null) {
            Toast.makeText(requireContext(), message, Toast.LENGTH_LONG).show()
            Log.e(TAG, message)
        }
    }

    @RequiresPermission(allOf = [Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION])
    override fun onMapReady(googleMap: GoogleMap) {
        try {
            Log.d(TAG, "onMapReady called")
            mMap = googleMap
            mMap.setOnMyLocationButtonClickListener(this)
            mMap.setOnMyLocationClickListener(this)

            // Verificar que el fragment sigue agregado
            if (!isAdded) {
                Log.w(TAG, "Fragment not added, skipping map setup")
                return
            }

            enableMyLocation()

            moverCamaraALaUbicacion { currentLocation ->
                if (::mMap.isInitialized && isAdded && _binding != null) {
                    try {
                        Log.d(TAG, "Moving camera and loading data")
                        mMap.animateCamera(CameraUpdateFactory.newLatLngZoom(currentLocation, 14.0f))

                        // Cargar datos del ViewModel
                        mapsViewModel.loadNearbyUsers(currentLocation)
                        mapsViewModel.loadClosestProduct(currentLocation)
                        mapsViewModel.loadClosestUser(currentLocation)

                        Log.d(TAG, "Map data loading initiated successfully")
                    } catch (e: Exception) {
                        Log.e(TAG, "Error loading map data: ${e.message}", e)
                        handleError("Error loading map data: ${e.message}")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in onMapReady: ${e.message}", e)
            handleError("Error setting up map: ${e.message}")
        }
    }

    // Analytics Pipeline
    override fun onResume() {
        super.onResume()
        try {
            sessionViewModel.logEvent("enter", "map")
        } catch (e: Exception) {
            Log.e(TAG, "Error logging enter event: ${e.message}", e)
        }
    }

    override fun onPause() {
        super.onPause()
        try {
            sessionViewModel.logEvent("exit", "map")
        } catch (e: Exception) {
            Log.e(TAG, "Error logging exit event: ${e.message}", e)
        }
    }

    //Additionals to focus camera
    @RequiresPermission(allOf = [Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION])
    private fun moverCamaraALaUbicacion(callback: (LatLng) -> Unit) {
        if (!isPermissionsGranted()) {
            Log.w(TAG, "Location permissions not granted")
            return
        }

        try {
            if (LocationHelper.isLocationEnabled(requireContext())) {
                val fusedLocationClient = LocationServices.getFusedLocationProviderClient(requireContext())
                fusedLocationClient.lastLocation.addOnSuccessListener { location: Location? ->
                    location?.let {
                        val latLng = LatLng(it.latitude, it.longitude)
                        LocationHelper.saveLastLocation(requireContext(), it)
                        callback(latLng)
                    } ?: run {
                        Log.w(TAG, "Location is null, trying saved location")
                        tryUsingSavedLocation(callback)
                    }
                }.addOnFailureListener { e ->
                    Log.e(TAG, "Error getting location: ${e.message}", e)
                    tryUsingSavedLocation(callback)
                }
            } else {
                tryUsingSavedLocation(callback)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in moverCamaraALaUbicacion: ${e.message}", e)
            tryUsingSavedLocation(callback)
        }
    }

    private fun tryUsingSavedLocation(callback: (LatLng) -> Unit) {
        try {
            val savedLatLng = LocationHelper.getLastSavedLocation(requireContext())
            if (savedLatLng != null) {
                if (isAdded) {
                    Toast.makeText(requireContext(), "Sin Ubicación. Mostrando última ubicación conocida", Toast.LENGTH_SHORT).show()
                }
                callback(savedLatLng)
            } else {
                if (isAdded) {
                    Toast.makeText(requireContext(), "Ubicación no disponible", Toast.LENGTH_SHORT).show()
                }
                Log.w(TAG, "No saved location available")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error using saved location: ${e.message}", e)
        }
    }

    //Permissions
    private fun isPermissionsGranted(): Boolean {
        return ContextCompat.checkSelfPermission(requireContext(), Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
    }

    private fun enableMyLocation() {
        if (!::mMap.isInitialized) {
            Log.w(TAG, "Map not initialized, cannot enable location")
            return
        }

        try {
            if (isPermissionsGranted()) {
                if (ActivityCompat.checkSelfPermission(requireContext(), Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) return
                mMap.isMyLocationEnabled = true
                Log.d(TAG, "My location enabled")
            } else {
                Log.d(TAG, "Requesting location permissions")
                requestPermissions(arrayOf(Manifest.permission.ACCESS_FINE_LOCATION), REQUEST_CODE_LOCATION)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error enabling my location: ${e.message}", e)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        if (requestCode == REQUEST_CODE_LOCATION && grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            Log.d(TAG, "Location permission granted")
            enableMyLocation()
        } else {
            Log.w(TAG, "Location permission denied")
            if (isAdded) {
                Toast.makeText(requireContext(), "Permiso requerido para mostrar tu ubicación", Toast.LENGTH_SHORT).show()
            }
        }
    }

    override fun onMyLocationClick(location: Location) {
        if (isAdded) {
            Toast.makeText(requireContext(), "Estás en: ${location.latitude}, ${location.longitude}", Toast.LENGTH_SHORT).show()
        }
    }

    override fun onMyLocationButtonClick(): Boolean = false

    override fun onDestroyView() {
        super.onDestroyView()
        try {
            // Limpiar marcadores
            closestUserMarker?.remove()
            nearbyMarkers.forEach { it.remove() }
            nearbyMarkers.clear()

            _binding = null
            Log.d(TAG, "View destroyed and cleaned up")
        } catch (e: Exception) {
            Log.e(TAG, "Error in onDestroyView: ${e.message}", e)
        }
    }

    private fun observerClosestUser(){
        mapsViewModel.closestUser.observe(viewLifecycleOwner) { user ->
            if (!isAdded || _binding == null) return@observe

            try {
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
                    Log.d(TAG, "Closest user marker updated: ${user.name}")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error updating closest user: ${e.message}", e)
            }
        }
    }

    private fun observerClosestProduct() {
        mapsViewModel.closestProduct.observe(viewLifecycleOwner) { product ->
            if (!isAdded || _binding == null) return@observe

            try {
                if (product != null) {
                    binding.productName.text = "Producto: ${product.title}"
                    binding.userPrice.text = "Precio: ${product.price}"
                    mapsViewModel.distanceToClosestUser.observe(viewLifecycleOwner) { distance ->
                        if (isAdded && _binding != null) {
                            binding.userDistance.text = "Distance to you: ${"%.0f".format(distance)}m"
                        }
                    }
                    Log.d(TAG, "Closest product updated: ${product.title}")
                } else {
                    closestUserMarker?.remove()
                    closestUserMarker = null
                    binding.productName.text = "No products nearby"
                    binding.userPrice.text = ""
                    binding.userContact.text = ""
                    binding.userName.text = ""
                    binding.userDistance.text = ""
                    Log.d(TAG, "No closest product found")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error updating closest product: ${e.message}", e)
            }
        }
    }

    private fun observeNearUsers() {
        mapsViewModel.nearbyUsers.observe(viewLifecycleOwner) { users ->
            if (!isAdded || !::mMap.isInitialized) return@observe

            try {
                // Limpiar marcadores anteriores
                nearbyMarkers.forEach { it.remove() }
                nearbyMarkers.clear()

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

                Log.d(TAG, "Added ${users.size} nearby user markers")
            } catch (e: Exception) {
                Log.e(TAG, "Error updating nearby users: ${e.message}", e)
            }
        }
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            android.R.id.home -> {
                try {
                    activity?.onBackPressed()
                } catch (e: Exception) {
                    Log.e(TAG, "Error navigating back: ${e.message}", e)
                }
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }
}