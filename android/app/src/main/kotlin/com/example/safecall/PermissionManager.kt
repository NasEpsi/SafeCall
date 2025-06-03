package com.example.safecall

import android.Manifest
import android.annotation.TargetApi
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.telecom.TelecomManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

@TargetApi(Build.VERSION_CODES.JELLY_BEAN)
class PermissionManager(private val activity: Activity) {

    companion object {
        private const val PERMISSION_REQUEST_CODE = 1001
        private const val CALL_BLOCKING_REQUEST_CODE = 1002
        private const val REQUEST_CODE_CALL_LOG = 1003

    }

    private val requiredPermissions = arrayOf(
        Manifest.permission.READ_PHONE_STATE,
        Manifest.permission.READ_CALL_LOG,
        Manifest.permission.ANSWER_PHONE_CALLS,
        Manifest.permission.WRITE_CALL_LOG,
        Manifest.permission.READ_CONTACTS,
        Manifest.permission.CALL_PHONE
    ).let { permissions ->
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            permissions + Manifest.permission.ANSWER_PHONE_CALLS
        } else {
            permissions
        }
    }.let { permissions ->
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions + Manifest.permission.POST_NOTIFICATIONS
        } else {
            permissions
        }
    }

    fun checkAndRequestPermissions(): Boolean {
        val missingPermissions = requiredPermissions.filter { permission ->
            ContextCompat.checkSelfPermission(activity, permission) != PackageManager.PERMISSION_GRANTED
        }

        if (missingPermissions.isNotEmpty()) {
            Log.d("PermissionManager", "Permissions manquantes: ${missingPermissions.joinToString()}")
            ActivityCompat.requestPermissions(
                activity,
                missingPermissions.toTypedArray(),
                PERMISSION_REQUEST_CODE
            )
            return false
        }

        Log.d("PermissionManager", "Toutes les permissions de base sont accordées")
        return true
    }

    fun checkCallBlockingPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val telecomManager = activity.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            // Check if our app is the default dialer
            return activity.packageName == telecomManager.defaultDialerPackage
        }
        return true
    }

    fun requestCallBlockingPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val telecomManager = activity.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            if (activity.packageName != telecomManager.defaultDialerPackage) {
                Log.d("PermissionManager", "Demande de l'autorisation de gestion des appels")
                val intent = Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER)
                intent.putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, activity.packageName)
                activity.startActivityForResult(intent, CALL_BLOCKING_REQUEST_CODE)
            }
        }
    }

    fun requestInCallServicePermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val telecomManager = activity.getSystemService(Context.TELECOM_SERVICE) as TelecomManager

            // Check if we have a valid phone account
            val phoneAccounts = telecomManager.callCapablePhoneAccounts
            Log.d("PermissionManager", "Phone Accounts: ${phoneAccounts.size}")

            // Redirect to accessibility settings to enable InCall service
            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
            activity.startActivity(intent)
        }
    }

    fun openAppSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
        val uri = Uri.fromParts("package", activity.packageName, null)
        intent.data = uri
        activity.startActivity(intent)
    }

    fun hasAllPermissions(): Boolean {
        return requiredPermissions.all { permission ->
            ContextCompat.checkSelfPermission(activity, permission) == PackageManager.PERMISSION_GRANTED
        }
    }

    fun getMissingPermissions(): List<String> {
        return requiredPermissions.filter { permission ->
            ContextCompat.checkSelfPermission(activity, permission) != PackageManager.PERMISSION_GRANTED
        }
    }

    fun handlePermissionResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val deniedPermissions = mutableListOf<String>()

            for (i in permissions.indices) {
                if (grantResults[i] != PackageManager.PERMISSION_GRANTED) {
                    deniedPermissions.add(permissions[i])
                }
            }

            if (deniedPermissions.isNotEmpty()) {
                Log.w("PermissionManager", "Permissions refusées: ${deniedPermissions.joinToString()}")

                // Check if user has selected "Don't ask again"
                val shouldShowRationale = deniedPermissions.any { permission ->
                    ActivityCompat.shouldShowRequestPermissionRationale(activity, permission)
                }

                if (!shouldShowRationale) {
                    Log.w("PermissionManager", "L'utilisateur a refusé définitivement les permissions")
                    // Optional: show dialog to go to settings
                }

                return false
            } else {
                Log.d("PermissionManager", "Toutes les permissions ont été accordées")
                return true
            }
        }
        return false
    }

    fun checkSystemAlertWindowPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(activity)
        } else {
            true
        }
    }

    fun requestSystemAlertWindowPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(activity)) {
            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
            intent.data = Uri.parse("package:${activity.packageName}")
            activity.startActivity(intent)
        }
    }

    // Check if the app is set as the default dialer
    fun isDefaultDialer(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val telecomManager = activity.getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            activity.packageName == telecomManager.defaultDialerPackage
        } else {
            false
        }
    }

    // Request to become the default dialer
    fun requestDefaultDialerRole() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER)
            intent.putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, activity.packageName)
            activity.startActivity(intent)
        }
    }

    fun logPermissionStatus() {
        Log.d("PermissionManager", "=== État des permissions ===")
        requiredPermissions.forEach { permission ->
            val status = if (ContextCompat.checkSelfPermission(activity, permission) == PackageManager.PERMISSION_GRANTED) {
                "ACCORDÉE"
            } else {
                "REFUSÉE"
            }
            Log.d("PermissionManager", "$permission: $status")
        }

        Log.d("PermissionManager", "Default dialer: ${isDefaultDialer()}")
        Log.d("PermissionManager", "Overlay autorisé: ${checkSystemAlertWindowPermission()}")
        Log.d("PermissionManager", "========================")
    }
}