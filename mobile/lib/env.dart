enum AppEnv { dev, staging, prod }

class Env {
  /// Remote config endpoint. Returns `{"api_base_url": "..."}`.
  /// We host this on a GitHub gist so the API URL can change without
  /// rebuilding the APK — useful while the backend is on a rotating
  /// Cloudflare Quick Tunnel URL.
  static const String configUrl = String.fromEnvironment(
    'CONFIG_URL',
    defaultValue:
        'https://gist.githubusercontent.com/davidgarg20/41e35770101521a186e148be8b4462c2/raw',
  );

  /// Fallback API URL used if the config fetch fails AND there's no cached
  /// value from a previous launch. Update when the tunnel URL changes
  /// (then rebuild for fresh installs; existing users get the gist).
  static const String apiBaseUrlFallback = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dip-keno-obviously-launch.trycloudflare.com',
  );

  static const String _envName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static AppEnv get current => switch (_envName) {
        'prod' => AppEnv.prod,
        'staging' => AppEnv.staging,
        _ => AppEnv.dev,
      };

  static bool get isDev => current == AppEnv.dev;
}
