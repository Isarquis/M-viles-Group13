// utils/LocationHelper.kt
package com.example.uni_matketplace_kotlin.data.location

import android.content.Context
import android.location.Location
import android.location.LocationManager
import android.preference.PreferenceManager
import com.google.android.gms.maps.model.LatLng

object LocationHelper {

    fun isLocationEnabled(context: Context): Boolean {
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }

    fun saveLastLocation(context: Context, location: Location) {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        prefs.edit()
            .putFloat("last_lat", location.latitude.toFloat())
            .putFloat("last_lng", location.longitude.toFloat())
            .apply()
    }

    fun getLastSavedLocation(context: Context): LatLng? {
        val prefs = PreferenceManager.getDefaultSharedPreferences(context)
        val lat = prefs.getFloat("last_lat", Float.MIN_VALUE)
        val lng = prefs.getFloat("last_lng", Float.MIN_VALUE)

        return if (lat != Float.MIN_VALUE && lng != Float.MIN_VALUE) {
            LatLng(lat.toDouble(), lng.toDouble())
        } else null
    }
}
