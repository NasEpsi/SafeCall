package com.example.safecall

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.util.Log

class DatabaseHelper(context: Context) : SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {

    companion object {
        private const val DATABASE_NAME = "safecall.db"
        private const val DATABASE_VERSION = 1

        // Table des numéros bloqués
        private const val TABLE_BLOCKED_NUMBERS = "blocked_numbers"
        private const val COLUMN_ID = "id"
        private const val COLUMN_PHONE_NUMBER = "phone_number"
        private const val COLUMN_BLOCK_REASON = "block_reason"
        private const val COLUMN_CREATED_AT = "created_at"

        private const val TAG = "DatabaseHelper"
    }

    override fun onCreate(db: SQLiteDatabase?) {
        val createBlockedNumbersTable = """
            CREATE TABLE $TABLE_BLOCKED_NUMBERS (
                $COLUMN_ID INTEGER PRIMARY KEY AUTOINCREMENT,
                $COLUMN_PHONE_NUMBER TEXT NOT NULL UNIQUE,
                $COLUMN_BLOCK_REASON TEXT,
                $COLUMN_CREATED_AT INTEGER DEFAULT (strftime('%s', 'now') * 1000)
            )
        """.trimIndent()

        db?.execSQL(createBlockedNumbersTable)

        // Créer un index pour améliorer les performances
        val createIndex = "CREATE INDEX idx_blocked_numbers_phone ON $TABLE_BLOCKED_NUMBERS($COLUMN_PHONE_NUMBER)"
        db?.execSQL(createIndex)

        Log.d(TAG, "Base de données créée avec succès")
    }

    override fun onUpgrade(db: SQLiteDatabase?, oldVersion: Int, newVersion: Int) {
        db?.execSQL("DROP TABLE IF EXISTS $TABLE_BLOCKED_NUMBERS")
        onCreate(db)
    }

    /**
     * Vérifier si un numéro est bloqué
     */
    fun isNumberBlocked(phoneNumber: String): Boolean {
        val db = readableDatabase
        var isBlocked = false

        try {
            val cursor = db.query(
                TABLE_BLOCKED_NUMBERS,
                arrayOf(COLUMN_ID),
                "$COLUMN_PHONE_NUMBER = ?",
                arrayOf(phoneNumber),
                null,
                null,
                null
            )

            isBlocked = cursor.count > 0
            cursor.close()

        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors de la vérification du blocage", e)
        }

        return isBlocked
    }

    /**
     * Ajouter un numéro à la liste des bloqués
     */
    fun blockNumber(phoneNumber: String, reason: String = "Spam"): Boolean {
        val db = writableDatabase

        try {
            val values = ContentValues().apply {
                put(COLUMN_PHONE_NUMBER, phoneNumber)
                put(COLUMN_BLOCK_REASON, reason)
            }

            val id = db.insertWithOnConflict(
                TABLE_BLOCKED_NUMBERS,
                null,
                values,
                SQLiteDatabase.CONFLICT_REPLACE
            )

            Log.d(TAG, "Numéro bloqué: $phoneNumber (ID: $id)")
            return id != -1L

        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors du blocage du numéro", e)
            return false
        }
    }

    /**
     * Débloquer un numéro
     */
    fun unblockNumber(phoneNumber: String): Boolean {
        val db = writableDatabase

        try {
            val deleted = db.delete(
                TABLE_BLOCKED_NUMBERS,
                "$COLUMN_PHONE_NUMBER = ?",
                arrayOf(phoneNumber)
            )

            Log.d(TAG, "Numéro débloqué: $phoneNumber")
            return deleted > 0

        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors du déblocage du numéro", e)
            return false
        }
    }

    /**
     * Récupérer la raison du blocage
     */
    fun getBlockReason(phoneNumber: String): String? {
        val db = readableDatabase
        var reason: String? = null

        try {
            val cursor = db.query(
                TABLE_BLOCKED_NUMBERS,
                arrayOf(COLUMN_BLOCK_REASON),
                "$COLUMN_PHONE_NUMBER = ?",
                arrayOf(phoneNumber),
                null,
                null,
                null
            )

            if (cursor.moveToFirst()) {
                reason = cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_BLOCK_REASON))
            }
            cursor.close()

        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors de la récupération de la raison", e)
        }

        return reason
    }

    /**
     * Récupérer tous les numéros bloqués
     */
    fun getAllBlockedNumbers(): List<Map<String, Any>> {
        val db = readableDatabase
        val blockedNumbers = mutableListOf<Map<String, Any>>()

        try {
            val cursor = db.query(
                TABLE_BLOCKED_NUMBERS,
                null,
                null,
                null,
                null,
                null,
                "$COLUMN_CREATED_AT DESC"
            )

            while (cursor.moveToNext()) {
                val number = mapOf<String, Any>(
                    "id" to cursor.getLong(cursor.getColumnIndexOrThrow(COLUMN_ID)),
                    "phoneNumber" to cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_PHONE_NUMBER)),
                    "blockReason" to (cursor.getString(cursor.getColumnIndexOrThrow(COLUMN_BLOCK_REASON)) ?: ""),
                    "createdAt" to cursor.getLong(cursor.getColumnIndexOrThrow(COLUMN_CREATED_AT))
                )
                blockedNumbers.add(number)
            }
            cursor.close()

        } catch (e: Exception) {
            Log.e(TAG, "Erreur lors de la récupération des numéros bloqués", e)
        }

        return blockedNumbers
    }
}