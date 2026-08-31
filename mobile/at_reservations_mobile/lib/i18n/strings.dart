/// Traductions FR/AR minimales pour l'app AT Reservations.
/// Usage : t(context, 'home') -> 'Accueil' ou 'الرئيسية' selon la locale.
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_preferences.dart';

/// Map des chaines : key -> {fr, ar}
const Map<String, Map<String, String>> _strings = {
  // Navigation
  'home':          {'fr': 'Accueil',        'ar': 'الرئيسية'},
  'missions':      {'fr': 'Missions',       'ar': 'المهمات'},
  'messages':      {'fr': 'Messages',       'ar': 'الرسائل'},
  'notifications': {'fr': 'Notifications',  'ar': 'الإشعارات'},
  'profile':       {'fr': 'Profil',         'ar': 'الملف الشخصي'},
  'dml':           {'fr': 'DML',            'ar': 'الخدمات اللوجستية'},
  'validations':   {'fr': 'Validations',    'ar': 'المصادقات'},
  'dashboard':     {'fr': 'Tableau de bord','ar': 'لوحة التحكم'},
  'logout':        {'fr': 'Deconnexion',    'ar': 'تسجيل الخروج'},

  // Profil
  'settings':      {'fr': 'Parametres',     'ar': 'الإعدادات'},
  'appearance':    {'fr': 'Apparence',      'ar': 'المظهر'},
  'theme':         {'fr': 'Theme',          'ar': 'السمة'},
  'theme_light':   {'fr': 'Clair',          'ar': 'فاتح'},
  'theme_dark':    {'fr': 'Sombre',         'ar': 'داكن'},
  'language':      {'fr': 'Langue',         'ar': 'اللغة'},
  'lang_fr':       {'fr': 'Francais',       'ar': 'الفرنسية'},
  'lang_ar':       {'fr': 'Arabe',          'ar': 'العربية'},
  'change_password':{'fr':'Changer mot de passe','ar':'تغيير كلمة المرور'},

  // Notifications panel
  'notif_missions':    {'fr': 'Missions',     'ar': 'المهمات'},
  'notif_missions_sub':{'fr': 'Creations et mises a jour de vos missions','ar': 'إنشاء وتحديثات مهماتك'},
  'notif_validations': {'fr': 'Validations',  'ar': 'المصادقات'},
  'notif_validations_sub':{'fr':'Approbations et rejets','ar': 'الموافقات والرفض'},
  'notif_messages':    {'fr': 'Messages',     'ar': 'الرسائل'},
  'notif_messages_sub':{'fr': 'Nouveaux messages recus','ar': 'الرسائل الجديدة المستلمة'},
  'notif_systeme':     {'fr': 'Systeme',      'ar': 'النظام'},
  'notif_systeme_sub': {'fr': 'Maintenances et mises a jour','ar': 'الصيانة والتحديثات'},
  'notif_saved':       {'fr': 'Preferences enregistrees','ar': 'تم حفظ التفضيلات'},

  // Common
  'save':         {'fr': 'Enregistrer',     'ar': 'حفظ'},
  'cancel':       {'fr': 'Annuler',         'ar': 'إلغاء'},
  'close':        {'fr': 'Fermer',          'ar': 'إغلاق'},

  // Dashboard
  'welcome':      {'fr': 'Bonjour',         'ar': 'مرحبا'},
  'quick_actions':{'fr': 'Actions rapides', 'ar': 'إجراءات سريعة'},
  'recent_missions':{'fr':'Missions recentes','ar': 'المهمات الأخيرة'},
  'new_mission':  {'fr': 'Nouvelle mission','ar': 'مهمة جديدة'},
  'my_missions':  {'fr': 'Mes missions',    'ar': 'مهماتي'},
  'search':       {'fr': 'Recherche',       'ar': 'بحث'},
};

/// Traduction selon la locale courante (depuis AppPreferences).
String t(BuildContext context, String key) {
  final lang = context.watch<AppPreferences>().locale.languageCode;
  return _strings[key]?[lang] ?? _strings[key]?['fr'] ?? key;
}

/// Variante non-reactive (pour callbacks)
String tNow(BuildContext context, String key) {
  final lang = context.read<AppPreferences>().locale.languageCode;
  return _strings[key]?[lang] ?? _strings[key]?['fr'] ?? key;
}
