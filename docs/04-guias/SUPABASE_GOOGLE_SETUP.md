# Configuração do Supabase para Login Google

## 📱 Informações Necessárias do Supabase

Copie estas informações no arquivo `.env` do Flutter:

```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua-chave-anonima-publica
```

## 🔐 Configurar Google OAuth no Supabase

### 1. Acesse a Dashboard do Supabase

1. Vá para [app.supabase.com](https://app.supabase.com)
2. Selecione seu projeto
3. Vá para **Authentication** → **Providers**
4. Procure por **Google** e clique em **Enable**

### 2. Adicionar Credenciais do Google

1. Vá para [Google Cloud Console](https://console.cloud.google.com)
2. Crie um novo projeto
3. Ative a **Google+ API**
4. Vá para **Credentials** → **Create Credentials** → **OAuth 2.0 Client ID**
5. Selecione **Web Application**
6. Adicione URLs autorizadas:
   ```
   http://localhost:3000
   https://seu-projeto.supabase.co/auth/v1/callback
   ```
7. Copie o **Client ID** e **Client Secret**
8. Volte ao Supabase e cole essas credenciais

### 3. Configurar URLs de Redirect no Supabase

Em **Authentication** → **URL Configuration**:

**Redirect URLs:**
```
http://localhost:3000
io.supabase.flutterquickstart://login-callback/
```

(Se usar bundle ID diferente, ajuste o scheme)

## 📝 Arquivo `.env` do Flutter

```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua-chave-publica
```

## ✅ Como Funciona Agora

1. Usuário clica em "Login com Google"
2. Flutter abre o navegador com Google Sign-In
3. Após login, Google redireciona para o callback
4. Supabase cria/vincula a sessão automaticamente
5. Token JWT é gerado
6. App está autenticado!

**Sem necessidade de:**
- ❌ Google Client Secret na API
- ❌ Validação manual de tokens Google
- ❌ Chamadas HTTP extras

**Tudo gerenciado pelo Supabase! 🎉**

## 🔄 Fluxo Simplificado

```
Cliente Flutter
       ↓
signInWithGoogle() (Supabase)
       ↓
Google OAuth Flow (no navegador)
       ↓
Callback para Supabase
       ↓
Supabase cria/retorna sessão
       ↓
AuthProvider escuta mudança
       ↓
App autenticado com token
```

## 🚀 Rodar

```bash
cd flutter
flutter pub get
flutter run
```

## ⚠️ Se der erro de redirect

1. Verifique o bundle ID do seu app Android/iOS
2. Configure o scheme correto:
   - Android: `io.supabase.flutterquickstart` (ou seu bundle ID)
   - iOS: Mesmo scheme no `Info.plist`
3. Adicione no Supabase → **URL Configuration** → **Redirect URLs**

## 📚 Documentação Oficial

- [Supabase Auth Docs](https://supabase.com/docs/guides/auth/social-login)
- [Flutter Supabase](https://supabase.com/docs/reference/flutter/introduction)
