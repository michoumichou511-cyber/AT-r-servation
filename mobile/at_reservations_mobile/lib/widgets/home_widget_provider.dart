import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

const String appWidgetProvider = 'ATReservationsWidgetProvider';
const String iOSWidgetName = 'ATReservationsWidget';

class HomeWidgetService {
  static final HomeWidgetService _instance = HomeWidgetService._();
  factory HomeWidgetService() => _instance;
  HomeWidgetService._();

  Future<void> initialize() async {
    HomeWidget.setAppGroupId('group.com.at.reservations');
    await updateWidget();
  }

  Future<void> updateWidget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        await _setDefaultData();
        return;
      }

      final apiService = ApiService();
      final stats = await _fetchStats(apiService, token);

      await HomeWidget.saveWidgetData<int>(
        'validations_count',
        stats['validations'] ?? 0,
      );
      await HomeWidget.saveWidgetData<String>(
        'next_mission_title',
        stats['nextMission'] ?? 'Aucune mission',
      );
      await HomeWidget.saveWidgetData<String>(
        'next_mission_date',
        stats['nextMissionDate'] ?? '',
      );
      await HomeWidget.saveWidgetData<int>(
        'missions_active',
        stats['missionsActive'] ?? 0,
      );

      await HomeWidget.updateWidget(
        androidName: appWidgetProvider,
        iOSName: iOSWidgetName,
      );
    } catch (_) {
      await _setDefaultData();
    }
  }

  Future<void> _setDefaultData() async {
    await HomeWidget.saveWidgetData<int>('validations_count', 0);
    await HomeWidget.saveWidgetData<String>(
      'next_mission_title',
      'Aucune mission',
    );
    await HomeWidget.saveWidgetData<String>('next_mission_date', '');
    await HomeWidget.saveWidgetData<int>('missions_active', 0);
    await HomeWidget.updateWidget(
      androidName: appWidgetProvider,
      iOSName: iOSWidgetName,
    );
  }

  Future<Map<String, dynamic>> _fetchStats(
    ApiService api,
    String token,
  ) async {
    try {
      final response = await api.get('/dashboard/stats');
      if (response != null && response['success'] == true) {
        final data = response['data'] ?? {};
        final missions = data['missions'] as List? ?? [];
        final pending = data['validations_en_attente'] ?? 0;

        String nextTitle = 'Aucune mission';
        String nextDate = '';
        int active = 0;

        for (final m in missions) {
          if (m['statut'] == 'approuvee' || m['statut'] == 'soumise') {
            active++;
            if (nextTitle == 'Aucune mission' && m['date_depart'] != null) {
              nextTitle = m['titre'] ?? 'Mission';
              nextDate = m['date_depart'] ?? '';
            }
          }
        }

        return {
          'validations': pending is int ? pending : 0,
          'nextMission': nextTitle,
          'nextMissionDate': nextDate,
          'missionsActive': active,
        };
      }
    } catch (_) {}
    return {};
  }
}
