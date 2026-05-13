# Sistema de Autenticação - Documentação Completa

## 📋 Visão Geral

Sistema de autenticação completo com:
- **API NestJS** em `localhost:3000`
- **Banco de dados Supabase**
- **Aplicativo Flutter** como cliente

### Autenticação suportada:
- Email e Senha
- Google OAuth
- Perfil com imagem padrão ou do Google

---

## 🚀 Configuração Inicial

### 1. Supabase Setup

1. Crie uma conta em [supabase.com](https://supabase.com)
2. Crie um novo projeto
3. Configure as credenciais no arquivo `.env` da API:

```env
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=sua-chave-anonima
SUPABASE_SERVICE_ROLE_KEY=sua-chave-de-servico
```

### 2. Google OAuth Setup

1. Acesse [Google Cloud Console](https://console.cloud.google.com/)
2. Crie um novo projeto
3. Ative a API de Google+
4. Crie credenciais de OAuth 2.0 (Web + Mobile)
5. Configure os Redirect URIs:
   - Web: `http://localhost:3000/auth/google/callback`
   - Android: Adicione o SHA-1 do seu app
   - iOS: Adicione o Bundle ID

6. Configure no `.env` da API:

```env
GOOGLE_CLIENT_ID=seu-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=seu-secret
GOOGLE_REDIRECT_URL=http://localhost:3000/auth/google/callback
```

7. Configure no `.env` do Flutter:

```env
GOOGLE_WEB_CLIENT_ID=seu-web-id.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=seu-ios-id.apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID=seu-android-id.apps.googleusercontent.com
```

---

## 🖥️ Executar a API

```bash
cd api

# Instalar dependências
npm install

# Desenvolvimento (com hot-reload)
npm run start:dev

# Produção
npm run build
npm run start:prod
```

A API estará em `http://localhost:3000`

---

## 📱 Executar o Flutter

```bash
cd flutter

# Instalar dependências
flutter pub get

# Executar em desenvolvimento
flutter run

# Especificar dispositivo
flutter run -d chrome      # Web
flutter run -d emulator-5554  # Android
```

---

## 📝 Rotas Disponíveis

### Autenticação

```
POST   /auth/signup              - Registrar novo usuário
POST   /auth/signin              - Fazer login
GET    /auth/google              - Autenticar com Google
GET    /auth/profile             - Obter perfil (requer token)
POST   /auth/profile/update      - Atualizar perfil (requer token)
```

### Usuários

```
GET    /users/me                 - Informações do usuário logado
DELETE /users/me                 - Deletar conta
```

---

## 📦 Fluxo de Autenticação

### 1. Registro (Email/Senha)

```
Cliente Flutter → POST /auth/signup
{
  "name": "João Silva",
  "email": "joao@email.com",
  "password": "SenhaSegura123",
  "confirmPassword": "SenhaSegura123"
}

↓

API NestJS → Supabase Auth
├─ Criar usuário
├─ Atualizar metadata (nome, foto padrão)
└─ Gerar JWT Token

↓

Resposta:
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "user-uuid",
    "email": "joao@email.com",
    "name": "João Silva",
    "picture": "https://api.dicebear.com/7.x/avataaars/svg?seed=João Silva"
  }
}
```

### 2. Login (Email/Senha)

```
Cliente Flutter → POST /auth/signin
{
  "email": "joao@email.com",
  "password": "SenhaSegura123"
}

↓

API NestJS → Supabase Auth
├─ Validar credenciais
└─ Gerar JWT Token

↓

Resposta: Token + Dados do usuário
```

### 3. Google OAuth

```
Cliente Flutter → Google Sign-In
│
└─ Obtém Google ID Token

↓

Cliente Flutter → GET /auth/google?code=<id_token>

↓

API NestJS → Google OAuth API
├─ Validar ID Token
├─ Obter informações do usuário
└─ Criar/verificar usuário no Supabase

↓

Resposta: Token + Supabase User
```

### 4. Obter Perfil

```
Cliente Flutter → GET /auth/profile
Header: Authorization: Bearer <token>

↓

API NestJS → Supabase Auth
└─ Obter usuário pelo token

↓

Resposta:
{
  "id": "user-uuid",
  "email": "joao@email.com",
  "name": "João Silva",
  "picture": "https://...",
  "provider": "email",
  "emailVerified": false
}
```

---

## 🔐 Segurança

### Variáveis de Ambiente

todas as credenciais sensíveis estão armazenadas em variáveis de ambiente:

- `SUPABASE_KEY` - Chave de serviço do Supabase
- `JWT_SECRET` - Chave secreta para assinar tokens JWT
- `GOOGLE_CLIENT_ID` e `GOOGLE_CLIENT_SECRET` - Credenciais do Google

⚠️ **NUNCA** commit estas variáveis. Use `.env` local.

### Token JWT

- Armazenado no Flutter em `SharedPreferences`
- Enviado no header `Authorization: Bearer <token>`
- Automaticamente adicionado em todas as requisições

### CORS

A API tem CORS habilitado apenas para `http://localhost:5000` (se necessário, ajuste em `main.ts`)

---

## 🗄️ Estrutura do Banco de Dados Supabase

### Tabela: `auth.users` (autogenerada pelo Supabase)

```
id (UUID)
email (string)
encrypted_password (string)
email_confirmed_at (timestamp)
user_metadata (JSON)
├─ name (string)
├─ picture (string)
├─ provider (email|google)
└─ googleId (string - apenas para Google)
created_at (timestamp)
updated_at (timestamp)
```

---

## 🐛 Troubleshooting

### API não conecta ao Supabase

```
❌ Error: Invalid SUPABASE_URL
✅ Solução: Verifique o .env, URL deve ser https://projeto.supabase.co
```

### Google Auth retorna erro 401

```
❌ Error: Unauthorized
✅ Solução:
   - Verifique se o GOOGLE_CLIENT_SECRET está correto
   - Verifique se o GOOGLE_REDIRECT_URL está na whitelist do Google
```

### Flutter não consegue conectar à API

```
❌ Network error
✅ Solução:
   - Verifique se a API está rodando em localhost:3000
   - No Android emulator: use 10.0.2.2 em vez de localhost
   - Verifique o .env do Flutter
```

### Token expirado

```
❌ 401 Unauthorized
✅ Solução:
   - Fazer logout e login novamente
   - O token expira em 7 dias (configurável em JWT_EXPIRATION)
```

---

## 🌐 Endpoints de Teste

### CURL - Registro

```bash
curl -X POST http://localhost:3000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Teste User",
    "email": "teste@email.com",
    "password": "TesteSenha123",
    "confirmPassword": "TesteSenha123"
  }'
```

### CURL - Login

```bash
curl -X POST http://localhost:3000/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teste@email.com",
    "password": "TesteSenha123"
  }'
```

### CURL - Obter Perfil

```bash
curl -X GET http://localhost:3000/auth/profile \
  -H "Authorization: Bearer <token>"
```

---

## 📚 Estrutura de Pastas

```
aplicativo/
├── api/
│   ├── src/
│   │   ├── auth/
│   │   │   ├── auth.controller.ts
│   │   │   ├── auth.service.ts
│   │   │   ├── auth.module.ts
│   │   │   ├── dto/
│   │   │   ├── guards/
│   │   │   └── strategies/
│   │   ├── supabase/
│   │   │   ├── supabase.service.ts
│   │   │   └── supabase.module.ts
│   │   ├── users/
│   │   │   ├── users.controller.ts
│   │   │   ├── users.service.ts
│   │   │   └── users.module.ts
│   │   ├── app.module.ts
│   │   └── main.ts
│   ├── .env
│   ├── .env.example
│   ├── package.json
│   ├── tsconfig.json
│   └── README.md
│
└── flutter/
    ├── lib/
    │   ├── main.dart
    │   ├── models/
    │   ├── screens/
    │   ├── services/
    │   ├── providers/
    │   └── widgets/
    ├── android/
    ├── ios/
    ├── .env
    ├── .env.example
    ├── pubspec.yaml
    └── README.md
```

---

## 🎯 Próximos Passos

- [ ] Implementar recuperação de senha
- [ ] Adicionar verificação de email obrigatória
- [ ] Implementar 2FA (Two-Factor Authentication)
- [ ] Adicionar refresh token
- [ ] Implementar rate limiting
- [ ] Adicionar testes unitários
- [ ] Configurar CI/CD

---

## 📞 Suporte

Para dúvidas ou problemas:
1. Verifique os logs da API: `npm run start:dev`
2. Verifique os logs do Flutter: `flutter run`
3. Consulte a documentação oficial:
   - [NestJS](https://docs.nestjs.com/)
   - [Flutter](https://flutter.dev/docs)
   - [Supabase](https://supabase.com/docs)
   - [Google OAuth](https://developers.google.com/identity/protocols/oauth2)

---

**Versão:** 1.0.0
**Última atualização:** 2 de Abril de 2026
