import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:octopus/octopus.dart';
import 'package:teledesk/src/common/constant/config.dart';
import 'package:teledesk/src/common/localization/localization.dart';
import 'package:teledesk/src/common/router/router_state_mixin.dart';
import 'package:teledesk/src/common/util/performance_overlay_tool.dart';
import 'package:teledesk/src/common/widget/window_scope.dart';
import 'package:teledesk/src/feature/authentication/widget/authentication_scope.dart';
import 'package:teledesk/src/feature/settings/widget/settings_scope.dart';

/// {@template app}
/// App widget.
/// {@endtemplate}
class App extends StatefulWidget {
  /// {@macro app}
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with RouterStateMixin {
  final Key builderKey = GlobalKey();

  String _buildBannerMessage() {
    if (Config.environment.isProduction) {
      if (Config.alpha) return 'ALPHA';
      if (Config.beta) return 'BETA';
      return '';
    }
    if (Config.environment.isDevelopment) return 'DEBUG';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final bannerMessage = _buildBannerMessage();
    return SettingsScope(
      child: Builder(
        builder: (context) {
          final theme = SettingsScope.themeOf(context);
          return MaterialApp.router(
            title: 'TeleDesk',
            debugShowCheckedModeBanner: false,
            routerConfig: router.config,
            localizationsDelegates: const <LocalizationsDelegate<Object?>>[
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              Localization.delegate,
            ],
            supportedLocales: Localization.supportedLocales,
            theme: theme.light,
            darkTheme: theme.dark,
            themeMode: theme.mode,
            builder: (context, child) => MediaQuery(
              key: builderKey,
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
              child: WindowScope(
                title: 'TeleDesk',
                child: OctopusTools(
                  enable: !kReleaseMode,
                  octopus: router,
                  child: PerformanceOverlayTool(
                    enabled: false,
                    child: bannerMessage.isNotEmpty
                        ? Banner(
                            location: BannerLocation.topEnd,
                            message: bannerMessage,
                            child: AuthenticationScope(child: child ?? const SizedBox.shrink()),
                          )
                        : AuthenticationScope(child: child ?? const SizedBox.shrink()),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
