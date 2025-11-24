package com.tualimentodiario.app

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        applyPreferredSplashBackground()
        super.onCreate(savedInstanceState)
    }

    private fun applyPreferredSplashBackground() {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val mode = prefs.getString("flutter.pref_theme_mode", null)
            val useDark = when (mode) {
                "dark" -> true
                "system" -> {
                    val nightModeFlags =
                        resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
                    nightModeFlags == Configuration.UI_MODE_NIGHT_YES
                }
                else -> false
            }
            val splashColor = if (useDark) Color.parseColor("#1C1F27") else Color.WHITE
            window.setBackgroundDrawable(ColorDrawable(splashColor))
        } catch (_: Exception) {
            // Best effort: if prefs are unavailable we fall back to the default theme.
        }
    }
}
