# ⚙️ Configuração do Google OAuth

## Problema: ClientID not set

O erro `ClientID not set` ocorre porque o Google Sign In Web requer o `clientId` configurado.

## Solução:

### 1. Obter seu Google Client ID

1. Vá para [Google Cloud Console](https://console.cloud.google.com/)
2. Crie um projeto (ou use um existente)
3. Ative a API "Google+ API"
4. Vá para "Credenciais" → "Criar Credenciais" → "ID do Cliente OAuth 2.0"
5. Selecione "Aplicação da Web"
6. Adicione as origens autorizadas:
   - `http://localhost:5000`
   - `http://localhost:5001`
   - `http://localhost`
   - `http://127.0.0.1`
7. Copie o **Client ID** (termina com `.apps.googleusercontent.com`)

### 2. Configurar na Web App

**Arquivo:** `flutter/web/index.html` (linha ~35)

Procure:
```html
<meta name="google-signin-client_id" content="YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com">
```

Substitua `YOUR_GOOGLE_CLIENT_ID` pelo seu Client ID:
```html
<meta name="google-signin-client_id" content="123456789-abc123def456.apps.googleusercontent.com">
```

### 3. Configurar na API (Backend)

**Arquivo:** `api/.env`

Adicione:
```
GOOGLE_CLIENT_ID=seu_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=seu_client_secret
```

### 4. Configurar no Mobile (se usar em Android/iOS)

**Arquivo:** `flutter/android/app/build.gradle` (para Android)

```gradle
// Adicione a configuração do Google Services
dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
}
```

E configure o `google-services.json` usando o Firebase Console.

## Testando

Depois de configurar:

### Web (Chrome):
```bash
cd flutter
flutter run -d chrome
# Clique em "Login com Google" - deve funcionar agora
```

### Verificar se está funcionando:

- ✅ If console não mostra `ClientID not set`
- ✅ Google login popup aparece
- ✅ Login funciona e redireciona para home

## Troubleshooting

### "Popup blocked" ou "Failed to authenticate"
- Verifique se o `clientId` está correto
- Verifique as origens autorizadas no Google Console
- Tente em incógnito (limpa cookies/cache)

### API rejeita token
- Verifique se `GOOGLE_CLIENT_ID` no backend está correto
- Confira se o backend está em `localhost:3000`

### "localhost refused to connect"
- Certifique-se de que:
  - API está rodando: `npm run start:dev` em `api/`
  - Flutter está rodando: `flutter run -d chrome` em `flutter/`

## Verificar Configuração

Abra o DevTools do Chrome (F12):
- Aba "Console" - Não deve aparecer erro de `ClientID`
- Aba "Network" - Verifique requisições para Google

---

**Próximo passo:** Após configurar o clientId, rode novamente o app e teste o Google Login! 🚀
