package com.example.finora_frontend

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.content.SharedPreferences
import android.app.PendingIntent
import android.content.Intent

/**
 * FinoraWidget – Android home screen widget scaffold.
 *
 * This AppWidgetProvider reads cached financial data from SharedPreferences
 * (written by Flutter via MethodChannel or WorkManager background sync)
 * and renders it in the widget layout.
 *
 * Data flow:
 *   1. Flutter calls `storeWidgetData()` via MethodChannel after each sync.
 *   2. AppWidgetManager.ACTION_APPWIDGET_UPDATE triggers `onUpdate()`.
 *   3. onUpdate() reads prefs and calls `updateAppWidget()`.
 *
 * To register this widget, add to AndroidManifest.xml:
 *   <receiver android:name=".FinoraWidget" android:exported="true">
 *     <intent-filter>
 *       <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
 *     </intent-filter>
 *     <meta-data
 *       android:name="android.appwidget.provider"
 *       android:resource="@xml/finora_widget_info" />
 *   </receiver>
 */
class FinoraWidget : AppWidgetProvider() {

    companion object {
        const val PREFS_NAME = "FinoraWidgetPrefs"
        const val KEY_BALANCE = "balance"
        const val KEY_TODAY_SPENT = "today_spent"
        const val KEY_BUDGET_PCT = "budget_pct"
        const val KEY_GOAL_NAME = "goal_name"
        const val KEY_GOAL_PCT = "goal_pct"
        const val KEY_UPDATED_AT = "updated_at"

        /**
         * Called from Flutter MethodChannel to persist widget data.
         */
        fun storeWidgetData(
            context: Context,
            balance: String,
            todaySpent: String,
            budgetPct: Int,
            goalName: String,
            goalPct: Int,
            updatedAt: String,
        ) {
            val prefs: SharedPreferences =
                context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit()
                .putString(KEY_BALANCE, balance)
                .putString(KEY_TODAY_SPENT, todaySpent)
                .putInt(KEY_BUDGET_PCT, budgetPct)
                .putString(KEY_GOAL_NAME, goalName)
                .putInt(KEY_GOAL_PCT, goalPct)
                .putString(KEY_UPDATED_AT, updatedAt)
                .apply()

            // Trigger widget refresh
            val intent = Intent(context, FinoraWidget::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            }
            context.sendBroadcast(intent)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (widgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, widgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
    ) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val balance = prefs.getString(KEY_BALANCE, "€0.00") ?: "€0.00"
        val todaySpent = prefs.getString(KEY_TODAY_SPENT, "€0.00") ?: "€0.00"
        val budgetPct = prefs.getInt(KEY_BUDGET_PCT, 0)
        val goalName = prefs.getString(KEY_GOAL_NAME, "") ?: ""
        val goalPct = prefs.getInt(KEY_GOAL_PCT, 0)
        val updatedAt = prefs.getString(KEY_UPDATED_AT, "") ?: ""

        val views = RemoteViews(context.packageName, R.layout.finora_widget)
        views.setTextViewText(R.id.widget_balance, balance)
        views.setTextViewText(R.id.widget_today_spent, todaySpent)
        views.setTextViewText(R.id.widget_budget_pct, "$budgetPct%")
        if (goalName.isNotEmpty()) {
            views.setTextViewText(R.id.widget_goal_name, goalName)
            views.setTextViewText(R.id.widget_goal_pct, "$goalPct%")
        }
        views.setTextViewText(R.id.widget_updated_at, updatedAt)

        // Tap to open app
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}