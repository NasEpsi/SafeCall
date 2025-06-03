package com.example.safecall

import android.annotation.SuppressLint
import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.provider.CallLog
import android.util.Log
import java.text.SimpleDateFormat
import java.util.*

class CallLogManager(private val context: Context) : SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        private const val DATABASE_NAME = "custom_call_logs.db"
        private const val DATABASE_VERSION = 1
        private const val TABLE_CALL_LOGS = "call_logs"

        // Colonnes
        private const val COLUMN_ID = "id"
        private const val COLUMN_NUMBER = "number"
        private const val COLUMN_CONTACT_NAME = "contact_name"
        private const val COLUMN_CALL_TYPE = "call_type"
        private const val COLUMN_DATE = "date"
        private const val COLUMN_DURATION = "duration"
        private const val COLUMN_IS_BLOCKED = "is_blocked"
        private const val COLUMN_BLOCK_REASON = "block_reason"
        private const val COLUMN_CREATED_AT = "created_at"

        // Types d'appels
        const val CALL_TYPE_INCOMING = 1
        const val CALL_TYPE_OUTGOING = 2
        const val CALL_TYPE_MISSED = 3
        const val CALL_TYPE_BLOCKED = 4

        private const val TAG = "CallLogManager"
    }

    override fun onCreate(db: SQLiteDatabase?) {
        val createTable = """
            CREATE TABLE $TABLE_CALL_LOGS (
                $COLUMN_ID INTEGER PRIMARY KEY AUTOINCREMENT,
                $COLUMN_NUMBER TEXT NOT NULL,
                $COLUMN_CONTACT_NAME TEXT,
                $COLUMN_CALL_TYPE INTEGER NOT NULL,
                $COLUMN_DATE INTEGER NOT NULL,
                $COLUMN_DURATION INTEGER DEFAULT 0,
                $COLUMN_IS_BLOCKED INTEGER DEFAULT 0,
                $COLUMN_BLOCK_REASON TEXT,
                $COLUMN_CREATED_AT INTEGER DEFAULT (strftime('%s', 'now') * 1000)
            )
        """.trimIndent()

        db?.execSQL(createTable)

        // Créer un index pour améliorer les performances
        val createIndex = "CREATE INDEX idx_call_logs_date ON $TABLE_CALL_LOGS($COLUMN_DATE DESC)"
        db?.execSQL(createIndex)

        Log.d(TAG, "Table call_logs créée avec succès")
    }

    override fun onUpgrade(db: SQLiteDatabase?, oldVersion: Int, newVersion: Int) {
        db?.execSQL("DROP TABLE IF EXISTS $TABLE_CALL_LOGS")
        onCreate(db)
    }

    /**
     * Récupérer les appels récents depuis les logs système Android
     */
    @SuppressLint("Range")
    fun getRecentCalls(limit: Int = 100): List<Map<String, Any>> {
        val calls = mutableListOf<Map<String, Any>>()

        try {
            // Vérifier les permissions
            if (!hasCallLogPermission()) {
                Log.e(TAG, "Permission READ_CALL_LOG manquante")
                return calls
            }

            // Colonnes à récupérer
            val projection = arrayOf(
                CallLog.Calls._ID,
                CallLog.Calls.NUMBER,
                CallLog.Calls.CACHED_NAME,
                CallLog.Calls.TYPE,
                CallLog.Calls.DATE,
                CallLog.Calls.DURATION
            )

            // Requête avec tri par date décroissante (sans LIMIT dans sortOrder)
            val cursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                projection,
                null,
                null,
                "${CallLog.Calls.DATE} DESC"
            )

            cursor?.use {
                var count = 0
                while (it.moveToNext() && count < limit) {
                    val callId = it.getLong(it.getColumnIndex(CallLog.Calls._ID))
                    val number = it.getString(it.getColumnIndex(CallLog.Calls.NUMBER)) ?: ""
                    val name = it.getString(it.getColumnIndex(CallLog.Calls.CACHED_NAME)) ?: ""
                    val type = it.getInt(it.getColumnIndex(CallLog.Calls.TYPE))
                    val date = it.getLong(it.getColumnIndex(CallLog.Calls.DATE))
                    val duration = it.getInt(it.getColumnIndex(CallLog.Calls.DURATION))

                    // Vérifier si le numéro est bloqué dans notre système
                    val isBlocked = isNumberBlocked(number)
                    val blockReason = if (isBlocked) getBlockReason(number) else null

                    val call = mapOf<String, Any>(
                        "id" to callId,
                        "number" to number,
                        "name" to name,
                        "type" to type,
                        "date" to date,
                        "duration" to duration,
                        "isBlocked" to isBlocked,
                        "blockReason" to (blockReason ?: "")
                    )
                    calls.add(call)
                    count++
                }
            }

            Log.d(TAG, "Récupéré ${calls.size} appels depuis les logs système")

        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors de la récupération des appels système", e)
        }

        return calls
    }

    /**
     * Supprimer un appel du journal système
     */
    fun deleteCallLogEntry(callId: Long): Boolean {
        return try {
            if (!hasCallLogPermission()) {
                Log.e(TAG, "Permission WRITE_CALL_LOG manquante")
                return false
            }

            val deleted = context.contentResolver.delete(
                CallLog.Calls.CONTENT_URI,
                "${CallLog.Calls._ID} = ?",
                arrayOf(callId.toString())
            )

            Log.d(TAG, "Suppression d'appel: ID $callId, résultat: $deleted")
            deleted > 0

        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors de la suppression de l'appel", e)
            false
        }
    }

    /**
     * Vérifier la disponibilité des logs d'appels
     */
    fun checkCallLogAvailability(): Map<String, Any> {
        val availability = mutableMapOf<String, Any>()

        try {
            availability["hasReadPermission"] = hasCallLogPermission()
            availability["hasWritePermission"] = hasWriteCallLogPermission()

            // Tester l'accès aux données
            val cursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(CallLog.Calls._ID),
                null,
                null,
                "${CallLog.Calls.DATE} DESC"
            )

            availability["canAccessData"] = cursor != null
            cursor?.close()

            // Compter le nombre total d'appels
            val countCursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf("COUNT(*) as count"),
                null,
                null,
                null
            )

            var totalCalls = 0
            countCursor?.use {
                if (it.moveToFirst()) {
                    totalCalls = it.getInt(0)
                }
            }

            availability["totalCallsInSystem"] = totalCalls

        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors de la vérification de disponibilité", e)
            availability["error"] = e.message ?: "Erreur inconnue"
        }

        return availability
    }

    /**
     * Debug des colonnes disponibles
     */
    @SuppressLint("Range")
    fun debugCallLogColumns() {
        try {
            val cursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                null,
                null,
                null,
                "${CallLog.Calls.DATE} DESC"
            )

            cursor?.use {
                Log.d(TAG, "Colonnes disponibles dans CallLog:")
                for (columnName in it.columnNames) {
                    Log.d(TAG, "  - $columnName")
                }

                if (it.moveToFirst()) {
                    Log.d(TAG, "Exemple d'enregistrement:")
                    for (i in 0 until it.columnCount) {
                        val columnName = it.getColumnName(i)
                        val value = it.getString(i)
                        Log.d(TAG, "  $columnName: $value")
                    }
                }
            }

        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors du debug des colonnes", e)
        }
    }

    /**
     * Obtenir des statistiques des appels système
     */
    @SuppressLint("Range")
    fun getCallStatistics(): Map<String, Any> {
        val stats = mutableMapOf<String, Any>()

        try {
            if (!hasCallLogPermission()) {
                stats["error"] = "Permission manquante"
                return stats
            }

            // Total des appels
            val totalCursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf("COUNT(*) as count"),
                null,
                null,
                null
            )

            totalCursor?.use {
                if (it.moveToFirst()) {
                    stats["totalCalls"] = it.getInt(0)
                }
            }

            // Appels manqués
            val missedCursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf("COUNT(*) as count"),
                "${CallLog.Calls.TYPE} = ?",
                arrayOf(CallLog.Calls.MISSED_TYPE.toString()),
                null
            )

            missedCursor?.use {
                if (it.moveToFirst()) {
                    stats["missedCalls"] = it.getInt(0)
                }
            }

            // Appels sortants
            val outgoingCursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf("COUNT(*) as count"),
                "${CallLog.Calls.TYPE} = ?",
                arrayOf(CallLog.Calls.OUTGOING_TYPE.toString()),
                null
            )

            outgoingCursor?.use {
                if (it.moveToFirst()) {
                    stats["outgoingCalls"] = it.getInt(0)
                }
            }

            // Appels entrants
            val incomingCursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf("COUNT(*) as count"),
                "${CallLog.Calls.TYPE} = ?",
                arrayOf(CallLog.Calls.INCOMING_TYPE.toString()),
                null
            )

            incomingCursor?.use {
                if (it.moveToFirst()) {
                    stats["incomingCalls"] = it.getInt(0)
                }
            }

            // Appels aujourd'hui
            val todayStart = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }.timeInMillis

            val todayCursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf("COUNT(*) as count"),
                "${CallLog.Calls.DATE} >= ?",
                arrayOf(todayStart.toString()),
                null
            )

            todayCursor?.use {
                if (it.moveToFirst()) {
                    stats["todayCalls"] = it.getInt(0)
                }
            }

        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors du calcul des statistiques", e)
            stats["error"] = e.message ?: "Erreur inconnue"
        }

        return stats
    }

    // Méthodes utilitaires privées

    private fun hasCallLogPermission(): Boolean {
        return context.checkSelfPermission(android.Manifest.permission.READ_CALL_LOG) ==
                android.content.pm.PackageManager.PERMISSION_GRANTED
    }

    private fun hasWriteCallLogPermission(): Boolean {
        return context.checkSelfPermission(android.Manifest.permission.WRITE_CALL_LOG) ==
                android.content.pm.PackageManager.PERMISSION_GRANTED
    }

    private fun isNumberBlocked(phoneNumber: String): Boolean {
        return try {
            // Ici vous pouvez implémenter la logique pour vérifier
            // si le numéro est dans votre liste de blocage
            // Par exemple, en utilisant votre DatabaseHelper
            val dbHelper = DatabaseHelper(context)
            dbHelper.isNumberBlocked(phoneNumber)
        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors de la vérification du blocage", e)
            false
        }
    }

    private fun getBlockReason(phoneNumber: String): String? {
        return try {
            // Récupérer la raison du blocage depuis votre base de données
            "Spam détecté"
        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors de la récupération de la raison", e)
            null
        }
    }

    // Méthodes pour la base de données locale (conservation du code existant)

    /**
     * Enregistrer un appel entrant détecté
     */
    fun logIncomingCall(
        phoneNumber: String,
        contactName: String? = null,
        isBlocked: Boolean = false,
        blockReason: String? = null
    ): Long {
        val db = writableDatabase

        try {
            val values = ContentValues().apply {
                put(COLUMN_NUMBER, phoneNumber)
                put(COLUMN_CONTACT_NAME, contactName ?: getContactName(phoneNumber))
                put(COLUMN_CALL_TYPE, if (isBlocked) CALL_TYPE_BLOCKED else CALL_TYPE_INCOMING)
                put(COLUMN_DATE, System.currentTimeMillis())
                put(COLUMN_DURATION, 0) // Durée inconnue pour les appels entrants
                put(COLUMN_IS_BLOCKED, if (isBlocked) 1 else 0)
                put(COLUMN_BLOCK_REASON, blockReason)
            }

            val id = db.insert(TABLE_CALL_LOGS, null, values)

            if (isBlocked) {
                Log.i(TAG, "Appel bloqué enregistré: $phoneNumber (ID: $id)")
            } else {
                Log.d(TAG, "Appel entrant enregistré: $phoneNumber (ID: $id)")
            }

            return id

        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors de l'enregistrement de l'appel", e)
            return -1
        } finally {
            db.close()
        }
    }

    /**
     * Mettre à jour un appel (par exemple, marquer comme manqué)
     */
    fun updateCall(id: Long, callType: Int, duration: Int = 0): Boolean {
        val db = writableDatabase

        try {
            val values = ContentValues().apply {
                put(COLUMN_CALL_TYPE, callType)
                put(COLUMN_DURATION, duration)
            }

            val rowsUpdated = db.update(
                TABLE_CALL_LOGS,
                values,
                "$COLUMN_ID = ?",
                arrayOf(id.toString())
            )

            Log.d(TAG, "Appel mis à jour: ID $id, type: $callType")
            return rowsUpdated > 0

        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors de la mise à jour de l'appel", e)
            return false
        } finally {
            db.close()
        }
    }

    /**
     * Récupération simple du nom de contact (à améliorer selon vos besoins)
     */
    private fun getContactName(phoneNumber: String): String? {
        // Ici vous pouvez implémenter la logique pour récupérer le nom du contact
        // depuis la base de contacts du téléphone si vous avez la permission
        return null
    }
}