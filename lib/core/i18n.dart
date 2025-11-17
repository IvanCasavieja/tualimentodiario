import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_state.dart'; // AppLang, languageProvider

class Strings {
  final String appTitle;
  final String navHome;
  final String navArchive;
  final String navFavorites;
  final String navProfile;

  final String headerDailyFood;
  final String headerSurprise;
  final String headerSubtitle;

  final String archiveTitle;
  final String filterFrom;
  final String filterTo;
  final String filterBtn;
  final String noResults;

  final String favoritesTitle;
  final String favoritesNeedLogin;
  final String favoritesEmpty;

  final String profileTitle;
  final String guest;
  final String guestHint;
  final String googleSignIn;
  final String emailSignIn;
  final String emailRegister;
  final String email;
  final String password;
  final String forgotPassword;
  final String resetEmailSent;
  final String resetEmailMissing;
  final String resetEmailError;
  final String resetEmailFederated;
  final String feedbackTitle;
  final String feedbackSubtitle;
  final String feedbackHint;
  final String feedbackSubmit;
  final String feedbackSuccess;
  final String feedbackError;
  final String feedbackLimitInfo;
  final String feedbackLimitReached;
  final String feedbackTooShort;
  final String cancel;
  final String create;
  final String enter;
  final String language;
  final String adminUpload;
  final String adminPanel;
  final String logout;

  // Extras usados en diálogos (detalle)
  final String close;
  final String prayerTitle;
  final String scrollHint;

  const Strings({
    required this.appTitle,
    required this.navHome,
    required this.navArchive,
    required this.navFavorites,
    required this.navProfile,
    required this.headerDailyFood,
    required this.headerSurprise,
    required this.headerSubtitle,
    required this.archiveTitle,
    required this.filterFrom,
    required this.filterTo,
    required this.filterBtn,
    required this.noResults,
    required this.favoritesTitle,
    required this.favoritesNeedLogin,
    required this.favoritesEmpty,
    required this.profileTitle,
    required this.guest,
    required this.guestHint,
    required this.googleSignIn,
    required this.emailSignIn,
    required this.emailRegister,
    required this.email,
    required this.password,
    required this.forgotPassword,
    required this.resetEmailSent,
    required this.resetEmailMissing,
    required this.resetEmailError,
    required this.resetEmailFederated,
    required this.feedbackTitle,
    required this.feedbackSubtitle,
    required this.feedbackHint,
    required this.feedbackSubmit,
    required this.feedbackSuccess,
    required this.feedbackError,
    required this.feedbackLimitInfo,
    required this.feedbackLimitReached,
    required this.feedbackTooShort,
    required this.cancel,
    required this.create,
    required this.enter,
    required this.language,
    required this.adminUpload,
    required this.adminPanel,
    required this.logout,
    required this.close,
    required this.prayerTitle,
    required this.scrollHint,
  });
}

const _es = Strings(
  appTitle: 'Tu Alimento Diario',
  navHome: 'Inicio',
  navArchive: 'Archivo',
  navFavorites: 'Favoritos',
  navProfile: 'Perfil',
  headerDailyFood: 'Alimento del día',
  headerSurprise: 'Sorpresa',
  headerSubtitle:
      'Elegí cómo te sentís hoy. Te llevo al archivo con los resultados.',
  archiveTitle: 'Archivo',
  filterFrom: 'Desde (yyyy-MM-dd)',
  filterTo: 'Hasta (yyyy-MM-dd)',
  filterBtn: 'Filtrar',
  noResults: 'No hay resultados',
  favoritesTitle: 'Favoritos',
  favoritesNeedLogin: 'Iniciá sesión para ver tus favoritos',
  favoritesEmpty: 'No tenés favoritos aún',
  profileTitle: 'Perfil',
  guest: 'Invitado',
  guestHint: 'Podés crear tu cuenta o iniciar sesión desde aquí.',
  googleSignIn: 'Continuar con Google',
  emailSignIn: 'Iniciar sesión con email',
  emailRegister: 'Crear cuenta con email',
  email: 'Email',
  password: 'Contraseña',
  forgotPassword: '¿Olvidaste tu contraseña?',
  resetEmailSent: 'Revisa tu correo para restablecer la contraseña.',
  resetEmailMissing: 'Ingresá tu email para enviar el enlace.',
  resetEmailError: 'No se pudo enviar el correo de restablecimiento.',
  resetEmailFederated:
      'Esta cuenta se creó con Google u otro proveedor. Inicia sesión con ese método.',
  feedbackTitle: 'Envíanos tu opinión',
  feedbackSubtitle: 'Queremos saber qué mejorar o qué te gusta.',
  feedbackHint: 'Escribe aquí tu mensaje',
  feedbackSubmit: 'Enviar opinión',
  feedbackSuccess: '¡Gracias! Tu opinión fue enviada.',
  feedbackError: 'No se pudo enviar la opinión. Intenta más tarde.',
  feedbackLimitInfo: 'Podés enviar una opinión cada 3 días.',
  feedbackLimitReached:
      'Podrás volver a enviar una opinión desde {date}.',
  feedbackTooShort: 'Escribe al menos 20 caracteres.',
  cancel: 'Cancelar',
  create: 'Crear',
  enter: 'Entrar',
  language: 'Idioma',
  adminUpload: 'Subir alimento diario',
  adminPanel: 'Panel de administración',
  logout: 'Cerrar sesión',
  close: 'Cerrar',
  prayerTitle: 'Oración',
  scrollHint: 'Deslizá para ver más',
);

const _en = Strings(
  appTitle: 'Your Daily Food',
  navHome: 'Home',
  navArchive: 'Archive',
  navFavorites: 'Favorites',
  navProfile: 'Profile',
  headerDailyFood: 'Daily Food',
  headerSurprise: 'Random',
  headerSubtitle:
      "Choose how you feel today. I'll take you to the Archive with results.",
  archiveTitle: 'Archive',
  filterFrom: 'From (yyyy-MM-dd)',
  filterTo: 'To (yyyy-MM-dd)',
  filterBtn: 'Filter',
  noResults: 'No results',
  favoritesTitle: 'Favorites',
  favoritesNeedLogin: 'Sign in to view your favorites',
  favoritesEmpty: 'You have no favorites yet',
  profileTitle: 'Profile',
  guest: 'Guest',
  guestHint: 'You can create an account or sign in here.',
  googleSignIn: 'Continue with Google',
  emailSignIn: 'Sign in with email',
  emailRegister: 'Create account with email',
  email: 'Email',
  password: 'Password',
  forgotPassword: 'Forgot password?',
  resetEmailSent: 'Check your inbox to reset your password.',
  resetEmailMissing: 'Enter your email to receive the reset link.',
  resetEmailError: 'Could not send the reset email.',
  resetEmailFederated:
      'This account uses Google/another provider. Please continue with that method.',
  feedbackTitle: 'Send us your feedback',
  feedbackSubtitle: 'Tell us what you love or what we can improve.',
  feedbackHint: 'Write your message here',
  feedbackSubmit: 'Send feedback',
  feedbackSuccess: 'Thanks! Your feedback was sent.',
  feedbackError: 'Could not send your feedback. Try again later.',
  feedbackLimitInfo: 'You can send feedback every 3 days.',
  feedbackLimitReached: 'You can send a new opinion after {date}.',
  feedbackTooShort: 'Write at least 20 characters.',
  cancel: 'Cancel',
  create: 'Create',
  enter: 'Enter',
  language: 'Language',
  adminUpload: 'Upload daily food',
  adminPanel: 'Admin panel',
  logout: 'Sign out',
  close: 'Close',
  prayerTitle: 'Prayer',
  scrollHint: 'Scroll to see more',
);

const _pt = Strings(
  appTitle: 'Seu Alimento Diário',
  navHome: 'Início',
  navArchive: 'Arquivo',
  navFavorites: 'Favoritos',
  navProfile: 'Perfil',
  headerDailyFood: 'Alimento do dia',
  headerSurprise: 'Surpresa',
  headerSubtitle:
      'Escolha como você se sente hoje. Levo você ao arquivo com os resultados.',
  archiveTitle: 'Arquivo',
  filterFrom: 'De (yyyy-MM-dd)',
  filterTo: 'Até (yyyy-MM-dd)',
  filterBtn: 'Filtrar',
  noResults: 'Sem resultados',
  favoritesTitle: 'Favoritos',
  favoritesNeedLogin: 'Faça login para ver seus favoritos',
  favoritesEmpty: 'Você ainda não tem favoritos',
  profileTitle: 'Perfil',
  guest: 'Convidado',
  guestHint: 'Você pode criar uma conta ou fazer login aqui.',
  googleSignIn: 'Continuar com Google',
  emailSignIn: 'Entrar com e-mail',
  emailRegister: 'Criar conta com e-mail',
  email: 'E-mail',
  password: 'Senha',
  forgotPassword: 'Esqueceu sua senha?',
  resetEmailSent: 'Confira seu e-mail para redefinir a senha.',
  resetEmailMissing: 'Informe seu e-mail para receber o link.',
  resetEmailError: 'Não foi possível enviar o e-mail de redefinição.',
  resetEmailFederated:
      'Esta conta usa Google/outro provedor. Entre por esse método.',
  feedbackTitle: 'Envie sua opinião',
  feedbackSubtitle: 'Conte-nos o que você ama ou o que podemos melhorar.',
  feedbackHint: 'Escreva sua mensagem aqui',
  feedbackSubmit: 'Enviar opinião',
  feedbackSuccess: 'Obrigado! Sua opinião foi enviada.',
  feedbackError: 'Não foi possível enviar a opinião. Tente novamente.',
  feedbackLimitInfo: 'Você pode enviar uma opinião a cada 3 dias.',
  feedbackLimitReached:
      'Você poderá enviar novamente depois de {date}.',
  feedbackTooShort: 'Escreva pelo menos 20 caracteres.',
  cancel: 'Cancelar',
  create: 'Criar',
  enter: 'Entrar',
  language: 'Idioma',
  adminUpload: 'Enviar alimento diário',
  adminPanel: 'Painel de administração',
  logout: 'Sair',
  close: 'Fechar',
  prayerTitle: 'Oração',
  scrollHint: 'Deslize para ver mais',
);

const _it = Strings(
  appTitle: 'Il Tuo Cibo Quotidiano',
  navHome: 'Home',
  navArchive: 'Archivio',
  navFavorites: 'Preferiti',
  navProfile: 'Profilo',
  headerDailyFood: 'Cibo del giorno',
  headerSurprise: 'Sorpresa',
  headerSubtitle:
      "Scegli come ti senti oggi. Ti porto all'archivio con i risultati.",
  archiveTitle: 'Archivio',
  filterFrom: 'Da (yyyy-MM-dd)',
  filterTo: 'A (yyyy-MM-dd)',
  filterBtn: 'Filtra',
  noResults: 'Nessun risultato',
  favoritesTitle: 'Preferiti',
  favoritesNeedLogin: 'Accedi per vedere i tuoi preferiti',
  favoritesEmpty: 'Non hai ancora preferiti',
  profileTitle: 'Profilo',
  guest: 'Ospite',
  guestHint: 'Puoi creare un account o accedere qui.',
  googleSignIn: 'Continua con Google',
  emailSignIn: 'Accedi con email',
  emailRegister: 'Crea account con email',
  email: 'Email',
  password: 'Password',
  forgotPassword: 'Hai dimenticato la password?',
  resetEmailSent: 'Controlla la tua email per reimpostare la password.',
  resetEmailMissing: 'Inserisci la tua email per ricevere il link.',
  resetEmailError: 'Impossibile inviare l’email di reimpostazione.',
  resetEmailFederated:
      'Questo account usa Google o un altro provider. Accedi con quel metodo.',
  feedbackTitle: 'Inviaci la tua opinione',
  feedbackSubtitle: 'Dicci cosa ami o cosa possiamo migliorare.',
  feedbackHint: 'Scrivi qui il tuo messaggio',
  feedbackSubmit: 'Invia opinione',
  feedbackSuccess: 'Grazie! La tua opinione è stata inviata.',
  feedbackError: 'Impossibile inviare l’opinione. Riprova più tardi.',
  feedbackLimitInfo: 'Puoi inviare un’opinione ogni 3 giorni.',
  feedbackLimitReached:
      'Potrai inviarne un’altra dopo il {date}.',
  feedbackTooShort: 'Scrivi almeno 20 caratteri.',
  cancel: 'Annulla',
  create: 'Crea',
  enter: 'Entra',
  language: 'Lingua',
  adminUpload: 'Carica cibo quotidiano',
  adminPanel: 'Pannello di amministrazione',
  logout: 'Esci',
  close: 'Chiudi',
  prayerTitle: 'Preghiera',
  scrollHint: 'Scorri per vedere altro',
);

final stringsProvider = Provider<Strings>((ref) {
  final lang = ref.watch(languageProvider);
  switch (lang) {
    case AppLang.en:
      return _en;
    case AppLang.pt:
      return _pt;
    case AppLang.it:
      return _it;
    case AppLang.es:
      return _es;
  }
});


