import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teledesk/src/feature/initialization/models/dependencies.dart';

class AppThemeData {
  const AppThemeData({required this.light, required this.dark, required this.mode});
  final ThemeData light;
  final ThemeData dark;
  final ThemeMode mode;
}

/// {@template settings_scope}
/// SettingsScope widget.
/// {@endtemplate}
class SettingsScope extends StatefulWidget {
  /// {@macro settings_scope}
  const SettingsScope({required this.child, super.key});

  final Widget child;

  static AppThemeData themeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_InheritedSettings>()!.theme;

  static void setThemeMode(BuildContext context, ThemeMode mode) =>
      context.findAncestorStateOfType<_SettingsScopeState>()!.setThemeMode(mode);

  static ThemeMode themeModeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_InheritedSettings>()!.theme.mode;

  @override
  State<SettingsScope> createState() => _SettingsScopeState();
}

class _SettingsScopeState extends State<SettingsScope> {
  ThemeMode _themeMode = ThemeMode.light;
  SharedPreferences? _prefs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefs == null) {
      _prefs = Dependencies.of(context).sharedPreferences;
      final saved = _prefs!.getString('theme_mode');
      if (saved == 'dark') {
        _themeMode = ThemeMode.dark;
      }
    }
  }

  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    _prefs?.setString('theme_mode', mode == ThemeMode.dark ? 'dark' : 'light');
  }

  AppThemeData _buildTheme() {
    const seedColor = Color(0xFF6366F1); // Indigo
    return AppThemeData(
      light: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seedColor,
        brightness: Brightness.light,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(elevation: 0, scrolledUnderElevation: 1),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      ),
      dark: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seedColor,
        brightness: Brightness.dark,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(elevation: 0, scrolledUnderElevation: 1),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
        ),
      ),
      mode: _themeMode,
    );
  }

  @override
  Widget build(BuildContext context) =>
      _InheritedSettings(theme: _buildTheme(), child: widget.child);
}

class _InheritedSettings extends InheritedWidget {
  const _InheritedSettings({required this.theme, required super.child});
  final AppThemeData theme;

  @override
  bool updateShouldNotify(_InheritedSettings old) => old.theme.mode != theme.mode;
}
