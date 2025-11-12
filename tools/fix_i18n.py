import re, io

path = 'lib/core/i18n.dart'
with io.open(path, 'r', encoding='utf8', errors='replace') as f:
    s = f.read()

# Fix comment line
s = re.sub(r"Extras usados en .+\(detalle\)", "Extras usados en diálogos (detalle)", s)

def r(lang, key, value):
    global s
    s = re.sub(rf"(const {lang} = Strings\([\s\S]*?{key}:\s*)'[^']*'", rf"\1'{value}'", s)

# Spanish
r('_es', 'headerDailyFood', 'Alimento del día')
r('_es', 'headerSubtitle', 'Elegí cómo te sentís hoy. Te llevo al archivo con los resultados.')
r('_es', 'favoritesNeedLogin', 'Iniciá sesión para ver tus favoritos')
r('_es', 'favoritesEmpty', 'No tenés favoritos aún')
r('_es', 'guestHint', 'Podés crear tu cuenta o iniciar sesión desde aquí.')
r('_es', 'emailSignIn', 'Iniciar sesión con email')
r('_es', 'password', 'Contraseña')
r('_es', 'adminPanel', 'Panel de administración')
r('_es', 'logout', 'Cerrar sesión')
r('_es', 'prayerTitle', 'Oración')
r('_es', 'scrollHint', 'Deslizá para ver más')

# English
r('_en', 'headerSubtitle', "Choose how you feel today. I'll take you to the Archive with results.")

# Portuguese
r('_pt', 'appTitle', 'Seu Alimento Diário')
r('_pt', 'navHome', 'Início')
r('_pt', 'headerSubtitle', 'Escolha como você se sente hoje. Levo você ao arquivo com os resultados.')
r('_pt', 'filterTo', 'Até (yyyy-MM-dd)')
r('_pt', 'favoritesNeedLogin', 'Faça login para ver seus favoritos')
r('_pt', 'favoritesEmpty', 'Você ainda não tem favoritos')
r('_pt', 'guestHint', 'Você pode criar uma conta ou fazer login aqui.')
r('_pt', 'adminUpload', 'Enviar alimento diário')
r('_pt', 'adminPanel', 'Painel de administração')
r('_pt', 'prayerTitle', 'Oração')

# Italian
r('_it', 'headerSubtitle', "Scegli come ti senti oggi. Ti porto all'archivio con i risultati.")

with io.open(path, 'w', encoding='utf8') as f:
    f.write(s)

print('fixed')
