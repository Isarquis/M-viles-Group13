package com.example.uni_matketplace_kotlin

import android.Manifest
import android.content.ContentProviderClient
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.os.Build
import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.os.Looper
import android.view.View
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.SupportMapFragment
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.MarkerOptions
import com.example.uni_matketplace_kotlin.databinding.ActivityMapsBinding
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.Granularity
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority

class MapsActivity : AppCompatActivity(), OnMapReadyCallback, GoogleMap.OnMyLocationButtonClickListener, GoogleMap.OnMyLocationClickListener {

    private lateinit var mMap: GoogleMap
    private lateinit var binding: ActivityMapsBinding
    val lugaresCercanos = listOf(
        LatLng(4.60971, -74.08175), // Bogotá
        LatLng(4.60312, -74.06725), // Lugar cercano 1
        LatLng(4.61022, -74.08533), // Lugar cercano 2
        LatLng(4.61852, -74.06575)  // Lugar cercano 3
    )
    companion object{
        const val REQUEST_CODE_LOCATION=0
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = ActivityMapsBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Obtain the SupportMapFragment and get notified when the map is ready to be used.
        val mapFragment = supportFragmentManager
            .findFragmentById(R.id.map) as SupportMapFragment
        mapFragment.getMapAsync(this)

    }

    override fun onMapReady(googleMap: GoogleMap) {
        mMap = googleMap

        //Marker
        createMarker()

        mMap.setOnMyLocationButtonClickListener(this)
        mMap.setOnMyLocationClickListener (this)
        enableMyLocation()
        for (lugar in lugaresCercanos) {
            mMap.addMarker(
                MarkerOptions()
                    .position(lugar)
                    .title("Lugar cercano")
            )
        }

        // Centrar la cámara en tu ubicación
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
            val fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
            fusedLocationClient.lastLocation.addOnSuccessListener { location: Location? ->
                location?.let {
                    val posicion = LatLng(it.latitude, it.longitude)
                    mMap.animateCamera(CameraUpdateFactory.newLatLngZoom(posicion, 14.0f))
                    callback(posicion) // Pasar la posición al callback
                }
            }
        }
    }

    private fun createMarker(){
        val bogota = LatLng(4.60971, -74.08175)
        mMap.addMarker(MarkerOptions().position(bogota).title("Marker in Bogotá"))
        mMap.animateCamera(CameraUpdateFactory.newLatLngZoom(bogota, 12.0f),
            4000, null)
    }


    fun regresarHome(view: View){
        val intent= Intent(this, MainActivity::class.java).apply{ }
        startActivity(intent)
    }

    private fun isPermissionsGranted(): Boolean {
        return (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                || ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED)
    }


    private fun enableMyLocation() {
        if (!::mMap.isInitialized) return
        if (isPermissionsGranted()) {
            mMap.isMyLocationEnabled = true
            mMap.uiSettings.isMyLocationButtonEnabled = true // Habilitar botón de ubicación
        } else {
            requestLocationPermission()
        }
    }


    private fun requestLocationPermission() {
        if (ActivityCompat.shouldShowRequestPermissionRationale(this,
                Manifest.permission.ACCESS_FINE_LOCATION)) {
            Toast.makeText(this, "Ve a ajustes y acepta los permisos", Toast.LENGTH_SHORT).show()
        } else {
            ActivityCompat.requestPermissions(this,
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                REQUEST_CODE_LOCATION)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == REQUEST_CODE_LOCATION) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                enableMyLocation() // Llamar nuevamente para activar la ubicación
            } else {
                Toast.makeText(this, "Ve a ajustes y acepta los permisos", Toast.LENGTH_SHORT).show()
            }
        }
    }


    override fun onResumeFragments() {
        super.onResumeFragments()
        if(!::mMap.isInitialized) return
        if(!isPermissionsGranted()){
            mMap.isMyLocationEnabled=false
            Toast.makeText(this, "Ve a ajustes y acepta los permisos", Toast.LENGTH_SHORT).show()

        }
    }

    override fun onMyLocationButtonClick(): Boolean {
        Toast.makeText(this, "Botón Pulsado", Toast.LENGTH_SHORT).show()
        return false    }

    override fun onMyLocationClick(p0: Location) {
        Toast.makeText(this, "Estás en ${p0.latitude}$, ${p0.longitude}\$ ", Toast.LENGTH_SHORT).show()
    }
    private fun calcularDistancia(ubicacion1: LatLng, ubicacion2: LatLng): Float {
        val resultados = FloatArray(1)
        Location.distanceBetween(
            ubicacion1.latitude, ubicacion1.longitude,
            ubicacion2.latitude, ubicacion2.longitude,
            resultados
        )
        return resultados[0] // Distancia en metros
    }

}
