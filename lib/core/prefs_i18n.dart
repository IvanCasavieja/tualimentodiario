import 'app_state.dart';

class PrefsTexts {
  final String title;
  final String subtitle;
  final String darkMode;
  final String textSize;
  final String googleSignedIn;
  const PrefsTexts({
    required this.title,
    required this.subtitle,
    required this.darkMode,
    required this.textSize,
    required this.googleSignedIn,
  });
}

PrefsTexts prefsTextsOf(AppLang lang) {
  switch (lang) {
    case AppLang.en:
      return const PrefsTexts(
        title: 'Preferences',
        subtitle: 'Affects the entire app',
        darkMode: 'Dark mode',
        textSize: 'Text size',
        googleSignedIn: 'Signed in with Google',
      );
    case AppLang.pt:
      return const PrefsTexts(
        title: 'Preferências',
        subtitle: 'Afetam todo o aplicativo',
        darkMode: 'Modo escuro',
        textSize: 'Tamanho do texto',
        googleSignedIn: 'Sessão iniciada com Google',
      );
    case AppLang.it:
      return const PrefsTexts(
        title: 'Preferenze',
        subtitle: 'Valgono per tutta l’app',
        darkMode: 'Tema scuro',
        textSize: 'Dimensione testo',
        googleSignedIn: 'Accesso con Google eseguito',
      );
    case AppLang.es:
      return const PrefsTexts(
        title: 'Preferencias',
        subtitle: 'Afectan a toda la aplicación',
        darkMode: 'Modo oscuro',
        textSize: 'Tamaño de texto',
        googleSignedIn: 'Sesión iniciada con Google',
      );
  }
}

