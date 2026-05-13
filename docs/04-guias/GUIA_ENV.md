## 🔐 Guia Completo: Como Preencher os .env

---

## 📝 Passo 1: Criar Conta Supabase

1. Acesse https://supabase.com
2. Clique em "Start your project"
3. Faça login com GitHub (recomendado)
4. Crie um novo projeto
5. Guarde a **senha do banco de dados** (você vai precisar)
6. Aguarde o projeto ser criado

---

## 📁 Passo 2: Obter Credenciais do Supabase

1. Na dashboard do projeto, clique em **Settings** (engrenagem)
2. Vá para **API**
3. Copie:
   - **Project URL** → `SUPABASE_URL` (nos dois .env)
   - **anon public** → `SUPABASE_ANON_KEY` (nos dois .env)
   - **service_role** → `SUPABASE_SERVICE_ROLE_KEY` (só no api/.env)

```
api/.env:
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...

flutter/.env:
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=eyJ...
```

---

## 🔑 Passo 3: Gerar JWT Secret (só api/.env)

Use um destes métodos:

### No Terminal (Linux/Mac):
```bash
openssl rand -base64 32
```

### No Windows (PowerShell):
```powershell
[Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
```

### Online:
Vá para https://www.uuidgenerator.net/ e gere

Cole em:
```
api/.env:
JWT_SECRET=seu-valor-aleatorio-aqui
JWT_EXPIRATION=7d
```

---

## 🌐 Passo 4: Configurar Google OAuth (OPCIONAL)

### Se quiser login com Google:

#### 4.1 - Criar projeto Google Cloud

1. Acesse https://console.cloud.google.com
2. Crie um novo projeto
3. Vá para **Credentials**
4. Clique em **Create Credentials** → **OAuth 2.0 Client ID**
5. Selecione **Web Application**

#### 4.2 - Configurar URLs autorizadas

Na criação do OAuth 2.0:

**Authorized JavaScript origins:**
```
http://localhost:3000
http://localhost:3000
http://localhost
```

**Authorized redirect URIs:**
```
http://localhost:3000/auth/google/callback
http://localhost:3000
```

#### 4.3 - Copiar credenciais

```
api/.env:
GOOGLE_CLIENT_ID=seu-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=seu-secret-xyz
GOOGLE_REDIRECT_URL=http://localhost:3000/auth/google/callback

flutter/.env:
GOOGLE_WEB_CLIENT_ID=seu-client-id.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=seu-ios-id.apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID=seu-android-id.apps.googleusercontent.com
```

#### 4.4 - Adicionar ao Supabase

1. No Supabase, vá para **Authentication** → **Providers**
2. Clique em **Google** → **Enable**
3. Cole o `GOOGLE_CLIENT_ID` e `GOOGLE_CLIENT_SECRET`
4. Clique em **Save**

---

## ✅ Arquivo `api/.env` Final

```env
## Supabase
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

## JWT
JWT_SECRET=ABC123DEF456GHI789...
JWT_EXPIRATION=7d

## Google OAuth (opcional)
GOOGLE_CLIENT_ID=seu-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=seu-secret
GOOGLE_REDIRECT_URL=http://localhost:3000/auth/google/callback

## Ambiente
NODE_ENV=development
API_PORT=3000
```

---

## ✅ Arquivo `flutter/.env` Final

```env
## Supabase
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

## API
API_BASE_URL=http://localhost:3000

## Google OAuth (opcional)
GOOGLE_WEB_CLIENT_ID=seu-web-id.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=seu-ios-id.apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID=seu-android-id.apps.googleusercontent.com
```

---

## 🚀 Verificar se Funcionou

### Testar API:
```bash
cd api
npm install
npm run start:dev
# Se rodar em localhost:3000 ✅
```

### Testar Flutter:
```bash
cd flutter
flutter pub get
flutter run
# Se rodar sem erros de .env ✅
```

---

## ⚠️ Erros Comuns

| Erro | Causa | Solução |
|------|-------|---------|
| `SUPABASE_URL is empty` | .env não foi carregado corretamente | Copie exatamente: `https://seu-projeto.supabase.co` |
| `Invalid SUPABASE_ANON_KEY` | Chave incorreta | Use a chave pública (anon), não a service_role |
| `JWT_SECRET not set` | JWT_SECRET faltando | Gere com `openssl rand -base64 32` |
| `Google OAuth error` | Credenciais erradas | Verifique `GOOGLE_CLIENT_ID` e `GOOGLE_CLIENT_SECRET` |
| `Redirect URI mismatch` | URL não registrada no Google | Adicione a URL em `Authorized redirect URIs` no Google Cloud |

---

## 📚 Links Úteis

- [Supabase Docs](https://supabase.com/docs)
- [Google Cloud Console](https://console.cloud.google.com)
- [Google OAuth Setup](https://developers.google.com/identity/protocols/oauth2)
- [JWT.io](https://jwt.io)

---

## 🎯 Checklist Final

- [ ] Criou conta Supabase
- [ ] Copiou SUPABASE_URL e SUPABASE_ANON_KEY
- [ ] Preencheu SUPABASE_SERVICE_ROLE_KEY (api/.env)
- [ ] Gerou JWT_SECRET
- [ ] (Opcional) Configurou Google OAuth
- [ ] Criou `api/.env` com todos os valores
- [ ] Criou `flutter/.env` com todos os valores
- [ ] Testou `npm run start:dev` (api)
- [ ] Testou `flutter run` (flutter)

**Pronto! ✅ Você está configurado!**
