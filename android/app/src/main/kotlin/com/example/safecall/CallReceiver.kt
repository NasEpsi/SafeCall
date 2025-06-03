package com.example.safecall

import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.telephony.TelephonyManager
import android.util.Log
import java.lang.reflect.Method

class CallReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "CallReceiver"
    }

    private var callLogManager: CallLogManager? = null
    private var currentCallId: Long = -1
    private var currentCallNumber: String? = null
    private var callStartTime: Long = 0

    @TargetApi(Build.VERSION_CODES.CUPCAKE)
    @SuppressLint("MissingPermission")
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return

        // Initialiser le gestionnaire de logs si nécessaire
        if (callLogManager == null) {
            callLogManager = CallLogManager(context)
        }

        val action = intent.action
        Log.d(TAG, "Broadcast reçu: $action")

        if (action == TelephonyManager.ACTION_PHONE_STATE_CHANGED) {
            val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
            val incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)

            Log.d(TAG, "État de l'appel: $state, Numéro: $incomingNumber")

            when (state) {
                TelephonyManager.EXTRA_STATE_RINGING -> {
                    handleIncomingCall(context, incomingNumber)
                }
                TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                    handleCallAnswered(context)
                }
                TelephonyManager.EXTRA_STATE_IDLE -> {
                    handleCallEnded(context)
                }
            }
        }
    }

    private fun handleIncomingCall(context: Context, incomingNumber: String?) {
        if (incomingNumber != null) {
            Log.d(TAG, "Appel entrant de : $incomingNumber")

            currentCallNumber = incomingNumber
            callStartTime = System.currentTimeMillis()

            // Vérifier si le numéro doit être bloqué dans un thread séparé
            Thread {
                try {
                    val shouldBlock = shouldBlockNumber(context, incomingNumber)
                    val blockReason = if (shouldBlock) getBlockReason(context, incomingNumber) else null

                    if (shouldBlock) {
                        Log.d(TAG, "Numéro bloqué détecté : $incomingNumber")

                        // Enregistrer l'appel comme bloqué
                        currentCallId = callLogManager?.logIncomingCall(
                            phoneNumber = incomingNumber,
                            contactName = null, // Vous pouvez ajouter la récupération du nom de contact
                            isBlocked = true,
                            blockReason = blockReason
                        ) ?: -1

                        // Tenter de bloquer l'appel
                        blockIncomingCall(context, incomingNumber)

                    } else {
                        Log.d(TAG, "Numéro autorisé : $incomingNumber")

                        // Enregistrer l'appel comme entrant normal
                        currentCallId = callLogManager?.logIncomingCall(
                            phoneNumber = incomingNumber,
                            contactName = null,
                            isBlocked = false,
                            blockReason = null
                        ) ?: -1
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Erreur lors de la vérification du numéro", e)
                }
            }.start()
        }
    }

    private fun handleCallAnswered(context: Context) {
        Log.d(TAG, "Appel décroché")

        // Si nous avons un appel en cours et qu'il n'était pas bloqué
        if (currentCallId != -1L && currentCallNumber != null) {
            // Marquer l'appel comme répondu (type INCOMING)
            callLogManager?.updateCall(currentCallId, CallLogManager.CALL_TYPE_INCOMING)
        }
    }

    private fun handleCallEnded(context: Context) {
        Log.d(TAG, "Appel terminé")

        if (currentCallId != -1L) {
            val callDuration = if (callStartTime > 0) {
                ((System.currentTimeMillis() - callStartTime) / 1000).toInt()
            } else {
                0
            }

            // Si l'appel n'a pas été répondu (durée très courte), marquer comme manqué
            if (callDuration < 5) { // Moins de 5 secondes = probablement manqué
                callLogManager?.updateCall(currentCallId, CallLogManager.CALL_TYPE_MISSED, 0)
                Log.d(TAG, "Appel marqué comme manqué")
            } else {
                // Mettre à jour avec la durée réelle
                callLogManager?.updateCall(currentCallId, CallLogManager.CALL_TYPE_INCOMING, callDuration)
                Log.d(TAG, "Appel terminé avec durée: ${callDuration}s")
            }
        }

        // Réinitialiser les variables
        currentCallId = -1
        currentCallNumber = null
        callStartTime = 0
    }

    private fun shouldBlockNumber(context: Context, number: String): Boolean {
        return try {
            // Utiliser DatabaseHelper directement plutôt que le bridge Flutter
            val dbHelper = DatabaseHelper(context)
            val isBlocked = dbHelper.isNumberBlocked(number)
            Log.d(TAG, "Vérification du blocage pour $number: $isBlocked")
            isBlocked
        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors de la vérification du blocage", e)
            // Par défaut, ne pas bloquer en cas d'erreur
            false
        }
    }

    private fun getBlockReason(context: Context, number: String): String? {
        return try {
            // Récupérer la raison du blocage depuis votre base de données
            val dbHelper = DatabaseHelper(context)
            // Vous devrez implémenter une méthode pour récupérer la raison
            // dbHelper.getBlockReason(number)
            "Numéro spam détecté"
        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors de la récupération de la raison", e)
            null
        }
    }

    @SuppressLint("MissingPermission")
    private fun blockIncomingCall(context: Context, phoneNumber: String) {
        try {
            val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

            // Méthode 1: Utiliser endCall via réflexion
            try {
                val telephonyClass = Class.forName(telephonyManager.javaClass.name)
                val endCallMethod: Method = telephonyClass.getDeclaredMethod("endCall")
                endCallMethod.isAccessible = true
                endCallMethod.invoke(telephonyManager)

                Log.d(TAG, "Appel bloqué via endCall() pour : $phoneNumber")

            } catch (e: Exception) {
                Log.e(TAG, "Échec de endCall(), tentative alternative", e)

                // Méthode 2: Utiliser ITelephony
                try {
                    val getITelephonyMethod = telephonyManager.javaClass.getDeclaredMethod("getITelephony")
                    getITelephonyMethod.isAccessible = true
                    val telephonyService = getITelephonyMethod.invoke(telephonyManager)

                    val endCallMethod = telephonyService.javaClass.getDeclaredMethod("endCall")
                    endCallMethod.invoke(telephonyService)

                    Log.d(TAG, "Appel bloqué via ITelephony pour : $phoneNumber")

                } catch (ex: Exception) {
                    Log.e(TAG, "Toutes les méthodes de blocage ont échoué", ex)

                    // Méthode 3: Notification à l'utilisateur
                    showCallBlockedNotification(context, phoneNumber)
                }
            }

            // Enregistrer l'appel bloqué dans les logs système
            logBlockedCall(context, phoneNumber)

        } catch (e: Exception) {
            Log.e(TAG, "Erreur générale lors du blocage de l'appel", e)
        }
    }

    private fun showCallBlockedNotification(context: Context, phoneNumber: String) {
        Log.d(TAG, "Notification: Appel spam détecté de $phoneNumber")

        // TODO: Implémenter la notification système
        // NotificationManager, etc.
    }

    private fun logBlockedCall(context: Context, phoneNumber: String) {
        Log.i(TAG, "CALL_BLOCKED: $phoneNumber at ${System.currentTimeMillis()}")

        // Optionnel: Statistiques supplémentaires
        try {
            // Vous pouvez ajouter ici une logique pour sauvegarder des statistiques
            // sur le nombre d'appels bloqués par jour, etc.
        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors de l'enregistrement des statistiques", e)
        }
    }
}