package com.example.spendsplit

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class SpendSplitWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_spendsplit)

            val balance = widgetData.getString("available_balance", "0") ?: "0"
            views.setTextViewText(R.id.balance_amount, balance)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
