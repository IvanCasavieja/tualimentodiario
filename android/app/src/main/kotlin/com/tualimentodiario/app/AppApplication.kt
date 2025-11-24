package com.tualimentodiario.app

import android.content.Context
import androidx.appcompat.app.AppCompatDelegate
import io.flutter.app.FlutterApplication

class AppApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        applySavedThemeMode()
    }

    private fun applySavedThemeMode() {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            when (prefs.getString("flutter.pref_theme_mode", null)) {
                "dark" -> AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_YES)
                "light" -> AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_NO)
                else -> AppCompatDelegate.setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM)
            }
        } catch (_: Exception) {
            // If preferences are unavailable we keep the default mode.
        }
    }
}
