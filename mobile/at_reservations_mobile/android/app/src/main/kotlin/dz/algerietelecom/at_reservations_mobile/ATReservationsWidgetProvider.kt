package dz.algerietelecom.at_reservations_mobile

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class ATReservationsWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.at_widget_layout).apply {
                val validations = widgetData.getInt("validations_count", 0)
                val nextTitle = widgetData.getString("next_mission_title", "Aucune mission") ?: "Aucune mission"
                val nextDate = widgetData.getString("next_mission_date", "") ?: ""
                val active = widgetData.getInt("missions_active", 0)

                setTextViewText(R.id.tv_validations_count, validations.toString())
                setTextViewText(R.id.tv_next_mission_title, nextTitle)
                setTextViewText(R.id.tv_next_mission_date, nextDate)
                setTextViewText(R.id.tv_missions_active, "$active actives")
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
