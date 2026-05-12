# L&J Doces - Aplicativo Mobile (Flutter)

Aplicativo Flutter do projeto L&J Doces, com fluxo de cliente e administrativo integrado a API NestJS.

## Visao Geral

O app cobre os fluxos principais de:

- autenticacao (email/senha e Google);
- recuperacao de acesso;
- catalogo, favoritos e perfil;
- checkout e pedidos;
- administracao (produtos, banners, vendas, pedidos e analytics);
- atualizacoes em tempo real via socket.

## Requisitos

- Flutter 3.x
- Dart SDK 3.x
- Android Studio (para Android) ou Chrome (para Web)
- API do projeto em execucao (pasta API)

## Instalacao

1. Entre na pasta mobile.
2. Instale as dependencias.
3. Crie o arquivo .env a partir do .env.example.

Comandos:

```bash
flutter pub get
cp .env.example .env
```

No Windows (PowerShell), se preferir:

```powershell
Copy-Item .env.example .env
```

## Configuracao do .env

Preencha o arquivo .env com os valores do seu ambiente:

```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua-chave-publica-anon

API_BASE_URL=http://localhost:3000

GOOGLE_WEB_CLIENT_ID=seu-web-client-id.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=seu-ios-client-id.apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID=seu-android-client-id.apps.googleusercontent.com
```

Observacoes importantes:

- Em emulador Android, localhost aponta para o proprio emulador. Se necessario, use API_BASE_URL=http://10.0.2.2:3000.
- O app carrega o .env no inicio da execucao (main.dart).

## Google Sign-In e Firebase - pontos obrigatorios

### Android: google-services.json

Arquivo obrigatorio para integracao Google/Firebase no Android:

- caminho: android/app/google-services.json

Checklist:

1. Baixar o arquivo no Firebase Console do app Android correto.
2. Garantir que o package/applicationId seja br.com.lejdoces.app.
3. Confirmar que o plugin Google Services esta aplicado no Gradle

Sem esse arquivo, o login Google no Android pode falhar na inicializacao/autenticacao.

### Web: token do Google no index.html

Para funcionar no Web, configure o client id no arquivo:

- caminho: web/index.html

Meta tag esperada:

```html
<meta name="google-signin-client_id" content="SEU_WEB_CLIENT_ID.apps.googleusercontent.com">
```

Tambem mantenha o script do Google Identity Services:

```html
<script src="https://accounts.google.com/gsi/client" async defer></script>
```

Se o client id estiver errado, o login Google no navegador falha mesmo com backend e .env corretos.

## Execucao

Android:

```bash
flutter run
```

Web:

```bash
flutter run -d chrome --web-port 5000
```

Build Web:

```bash
flutter build web
```

## Rotas principais do app

- /signin
- /signup
- /reset-password
- /home
- /profile
- /checkout
- /orders
- /admin
- /admin/banners
- /admin/products
- /admin/orders
- /admin/sales
- /admin/analytics

## Estrutura resumida

- lib/services: API, storage, socket e integracoes
- lib/providers: estado de autenticacao, admin, favoritos, carrinho, pedidos e sync
- lib/screens: telas de cliente e admin
- lib/widgets: componentes reutilizaveis
- lib/theme: tema da aplicacao

## Solucao de problemas rapida

- Erro de autenticacao Google no Android:
	- conferir android/app/google-services.json e package br.com.lejdoces.app
- Erro de autenticacao Google no Web:
	- conferir web/index.html com google-signin-client_id correto
- App sem comunicar com API:
	- validar API_BASE_URL no .env
	- verificar se a API esta em execucao
- Falha de sessao persistida:
	- limpar dados locais do app e autenticar novamente

## Documentacao relacionada

- README raiz: [README.md](../README.md)
- Visao geral: [visao-geral.md](../docs/visao-geral.md)
- Requisitos funcionais: [docs/RF.md](../docs/RF.md)
- Regras de negocio: [docs/RN.md](../docs/RN.md)
- Requisitos nao funcionais: [docs/RNF.md](../docs/RNF.md)
- MVP: [docs/mvp.md](../docs/mvp.md)
