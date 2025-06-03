package com.example.safecall

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.telecom.Call
import android.telecom.InCallService
import android.telephony.TelephonyManager
import android.util.Log
import java.lang.reflect.Method

@TargetApi(Build.VERSION_CODES.M)
class CallBlockerService : InCallService() {

    private lateinit var bridgeHandler: FlutterMethodChannelHandler

    override fun onCreate() {
        super.onCreate()
        bridgeHandler = FlutterMethodChannelHandler(this)
    }

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)

        val incomingNumber = call.details.handle?.schemeSpecificPart
        Log.d("CallBlockerService", "Appel détecté de : $incomingNumber")

        if (incomingNumber != null) {
            // Vérifier en arrière-plan si le numéro doit être bloqué
            Thread {
                if (shouldBlockNumber(incomingNumber)) {
                    Log.d("CallBlockerService", "Blocage de l'appel : $incomingNumber")
                    // Revenir sur le thread principal pour bloquer l'appel
                    runOnUiThread {
                        blockCall(call)
                    }
                }
            }.start()
        }
    }

    private fun shouldBlockNumber(number: String): Boolean {
        return try {
            // Utiliser le bridge Flutter au lieu de DatabaseHelper
            val isBlocked = bridgeHandler.isNumberBlocked(number)
            Log.d("CallBlockerService", "Numéro $number bloqué: $isBlocked")
            isBlocked
        } catch (e: Exception) {
            Log.e("CallBlockerService", "Erreur lors de la vérification du numéro", e)
            // Fallback vers l'ancienne méthode si le bridge ne fonctionne pas
            try {
                val dbHelper = DatabaseHelper(this)
                dbHelper.isNumberBlocked(number)
            } catch (ex: Exception) {
                Log.e("CallBlockerService", "Erreur fallback DatabaseHelper", ex)
                false
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun blockCall(call: Call) {
        try {
            // Méthode 1: Rejet direct de l'appel
            call.reject(false, null)

            // Méthode 2: Si la première ne fonctionne pas, couper l'appel
            if (call.state == Call.STATE_RINGING) {
                call.disconnect()
            }

            Log.d("CallBlockerService", "Appel bloqué avec succès")

        } catch (e: Exception) {
            Log.e("CallBlockerService", "Erreur lors du blocage de l'appel", e)

            // Méthode alternative utilisant TelephonyManager
            try {
                blockCallUsingTelephonyManager()
            } catch (ex: Exception) {
                Log.e("CallBlockerService", "Échec du blocage alternatif", ex)
            }
        }
    }

    @SuppressLint("MissingPermission")
    private fun blockCallUsingTelephonyManager() {
        try {
            val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

            // Utilisation de la réflexion pour accéder aux méthodes cachées
            val telephonyClass = Class.forName(telephonyManager.javaClass.name)
            val endCallMethod: Method = telephonyClass.getDeclaredMethod("endCall")
            endCallMethod.isAccessible = true
            endCallMethod.invoke(telephonyManager)

            Log.d("CallBlockerService", "Appel terminé via TelephonyManager")

        } catch (e: Exception) {
            Log.e("CallBlockerService", "Impossible d'utiliser TelephonyManager pour bloquer", e)
        }
    }

    private fun runOnUiThread(action: () -> Unit) {
        val handler = android.os.Handler(android.os.Looper.getMainLooper())
        handler.post(action)
    }

    override fun onBind(intent: Intent?): IBinder? {
        return super.onBind(intent)
    }
}