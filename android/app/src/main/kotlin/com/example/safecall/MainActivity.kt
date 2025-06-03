package com.example.safecall

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    private lateinit var bridgeHandler: FlutterMethodChannelHandler
    private lateinit var permissionManager: PermissionManager
    private lateinit var permissionChannel: MethodChannel
    private lateinit var callLogChannel: MethodChannel
    private lateinit var callLogManager: CallLogManager

    companion object {
        private const val PERMISSION_CHANNEL = "com.example.safecall/permissions"
        private const val CALL_LOG_CHANNEL = "com.example.safecall/call_logs"
        private const val TAG = "MainActivity"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialiser le gestionnaire de permissions
        permissionManager = PermissionManager(this)

        // Initialiser le gestionnaire de logs d'appels
        callLogManager = CallLogManager(this)

        Log.d(TAG, "Application démarrée")

        // Vérifier et demander les permissions au démarrage
        checkInitialPermissions()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        Log.d(TAG, "Configuration des canaux Flutter")

        // Configurer le bridge natif (si FlutterMethodChannelHandler existe)
        try {
            bridgeHandler = FlutterMethodChannelHandler(this)
            bridgeHandler.setupMethodChannel(flutterEngine)
            Log.d(TAG, "Bridge natif configuré avec succès")
        } catch (e: Exception) {
            Log.w(TAG, "Impossible de configurer le bridge natif: ${e.message}")
        }

        // Configurer le channel pour les permissions
        permissionChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL)
        permissionChannel.setMethodCallHandler { call, result ->
            handlePermissionMethodCall(call, result)
        }
        Log.d(TAG, "Canal des permissions configuré")

        // Configurer le channel pour les logs d'appels
        callLogChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_LOG_CHANNEL)
        callLogChannel.setMethodCallHandler { call, result ->
            handleCallLogMethodCall(call, result)
        }
        Log.d(TAG, "Canal des logs d'appels configuré")
    }

    private fun handlePermissionMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "Méthode de permission appelée: ${call.method}")

        when (call.method) {
            "checkPermissions" -> {
                val hasPermissions = permissionManager.hasAllPermissions()
                Log.d(TAG, "Vérification des permissions: $hasPermissions")
                result.success(hasPermissions)
            }
            "requestPermissions" -> {
                val granted = permissionManager.checkAndRequestPermissions()
                Log.d(TAG, "Demande de permissions: $granted")
                result.success(granted)
            }
            "getMissingPermissions" -> {
                val missing = permissionManager.getMissingPermissions()
                Log.d(TAG, "Permissions manquantes: $missing")
                result.success(missing)
            }
            "requestCallBlockingPermission" -> {
                permissionManager.requestCallBlockingPermission()
                result.success(true)
            }
            "requestInCallServicePermission" -> {
                permissionManager.requestInCallServicePermission()
                result.success(true)
            }
            "openAppSettings" -> {
                permissionManager.openAppSettings()
                result.success(true)
            }
            "logPermissionStatus" -> {
                permissionManager.logPermissionStatus()
                result.success(true)
            }
            "isDefaultDialer" -> {
                val isDefault = permissionManager.isDefaultDialer()
                Log.d(TAG, "Est le composeur par défaut: $isDefault")
                result.success(isDefault)
            }
            "requestDefaultDialerRole" -> {
                permissionManager.requestDefaultDialerRole()
                result.success(true)
            }
            else -> {
                Log.w(TAG, "Méthode de permission non implémentée: ${call.method}")
                result.notImplemented()
            }
        }
    }

    private fun handleCallLogMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "Méthode de log d'appel appelée: ${call.method}")

        when (call.method) {
            "getRecentCalls" -> {
                try {
                    val limit = call.argument<Int>("limit") ?: 100
                    Log.d(TAG, "Demande de récupération de $limit appels récents")

                    // Vérifier les permissions avant d'accéder aux logs
                    if (!permissionManager.hasAllPermissions()) {
                        Log.e(TAG, "Permissions manquantes pour accéder aux logs d'appels")
                        result.error("PERMISSION_DENIED", "Permissions manquantes", null)
                        return
                    }

                    val calls = callLogManager.getRecentCalls(limit)
                    Log.d(TAG, "Récupéré ${calls.size} appels")
                    result.success(calls)

                } catch (e: Exception) {
                    Log.e(TAG, "Erreur lors de la récupération des appels: ${e.message}", e)
                    result.error("CALL_LOG_ERROR", e.message, e.stackTraceToString())
                }
            }
            "deleteCallLogEntry" -> {
                try {
                    val callId = call.argument<Long>("callId")
                    if (callId != null) {
                        val deleted = callLogManager.deleteCallLogEntry(callId)
                        Log.d(TAG, "Suppression d'appel ID $callId: $deleted")
                        result.success(deleted)
                    } else {
                        result.error("INVALID_ARGUMENT", "Call ID is null", null)
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Erreur lors de la suppression: ${e.message}", e)
                    result.error("DELETE_ERROR", e.message, e.stackTraceToString())
                }
            }
            "getCallStatistics" -> {
                try {
                    val stats = callLogManager.getCallStatistics()
                    Log.d(TAG, "Statistiques calculées: $stats")
                    result.success(stats)
                } catch (e: Exception) {
                    Log.e(TAG, "Erreur lors des statistiques: ${e.message}", e)
                    result.error("STATS_ERROR", e.message, e.stackTraceToString())
                }
            }
            "debugCallLogs" -> {
                try {
                    Log.d(TAG, "Debug des colonnes de logs d'appels")
                    callLogManager.debugCallLogColumns()
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "Erreur lors du debug: ${e.message}", e)
                    result.error("DEBUG_ERROR", e.message, e.stackTraceToString())
                }
            }
            "checkCallLogAvailability" -> {
                try {
                    val availability = callLogManager.checkCallLogAvailability()
                    Log.d(TAG, "Disponibilité des logs: $availability")
                    result.success(availability)
                } catch (e: Exception) {
                    Log.e(TAG, "Erreur lors de la vérification: ${e.message}", e)
                    result.error("CHECK_ERROR", e.message, e.stackTraceToString())
                }
            }
            else -> {
                Log.w(TAG, "Méthode de log d'appel non implémentée: ${call.method}")
                result.notImplemented()
            }
        }
    }

    private fun checkInitialPermissions() {
        Log.d(TAG, "Vérification des permissions initiales")

        // Afficher l'état actuel des permissions
        permissionManager.logPermissionStatus()

        // Vérifier et demander les permissions de base
        if (!permissionManager.hasAllPermissions()) {
            Log.w(TAG, "Certaines permissions sont manquantes")
            permissionManager.checkAndRequestPermissions()
        } else {
            Log.d(TAG, "Toutes les permissions de base sont accordées")

            // Vérifier les permissions spéciales
            checkSpecialPermissions()
        }
    }

    private fun checkSpecialPermissions() {
        // Vérifier la permission de blocage d'appels
        if (!permissionManager.checkCallBlockingPermission()) {
            Log.w(TAG, "Permission de blocage d'appels manquante")
        }

        // Vérifier la permission d'overlay (optionnel)
        if (!permissionManager.checkSystemAlertWindowPermission()) {
            Log.w(TAG, "Permission d'overlay manquante")
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        Log.d(TAG, "Résultat des permissions: requestCode=$requestCode")

        val allGranted = permissionManager.handlePermissionResult(requestCode, permissions, grantResults)

        if (allGranted) {
            Log.d(TAG, "Toutes les permissions ont été accordées")
            checkSpecialPermissions()

            // Notifier Flutter que les permissions ont été accordées
            try {
                permissionChannel.invokeMethod("onPermissionsGranted", true)
            } catch (e: Exception) {
                Log.e(TAG, "Erreur lors de la notification Flutter: ${e.message}")
            }
        } else {
            Log.w(TAG, "Certaines permissions ont été refusées")

            // Notifier Flutter que des permissions ont été refusées
            try {
                permissionChannel.invokeMethod("onPermissionsGranted", false)
            } catch (e: Exception) {
                Log.e(TAG, "Erreur lors de la notification Flutter: ${e.message}")
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        Log.d(TAG, "onActivityResult: requestCode=$requestCode, resultCode=$resultCode")

        // Vérifier à nouveau les permissions après un retour d'activité
        permissionManager.logPermissionStatus()
    }

    override fun onResume() {
        super.onResume()

        // Vérifier les permissions à chaque reprise de l'activité
        Log.d(TAG, "Application reprise, vérification des permissions")
        permissionManager.logPermissionStatus()
    }
}