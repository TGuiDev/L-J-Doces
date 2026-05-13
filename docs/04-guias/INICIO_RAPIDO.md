# 🚀 INÍCIO RÁPIDO - Sistema de Autenticação

## 📋 O que foi criado?

✅ **API NestJS completa** com:
- Autenticação por Email/Senha
- Autenticação Google OAuth
- Gerenciamento de perfil de usuário
- Integração com Supabase
- JWT Token
- CORS habilitado

✅ **App Flutter completo** com:
- Tela de Registro
- Tela de Login
- Autenticação Google
- Tela de Perfil
- Armazenamento local de token
- UI moderna e responsiva

---

## ⚡ Como começar? (5 minutos)

### Passo 1: Configurar Supabase

1. Vá para https://supabase.com e crie uma conta
2. Crie um novo projeto
3. Copie a URL e as chaves de `Settings > API`
4. Cole em `api/.env`:

```bash
SUPABASE_URL=sua-url-aqui
SUPABASE_ANON_KEY=sua-chave-anonima
SUPABASE_SERVICE_ROLE_KEY=sua-chave-de-servico
```

### Passo 2: Configurar Google OAuth

1. Vá para https://console.cloud.google.com
2. Crie um novo projeto
3. Ative "Google+ API"
4. Crie credenciais OAuth 2.0
5. Copie o Client ID e Secret em `api/.env`:

```bash
GOOGLE_CLIENT_ID=seu-id
GOOGLE_CLIENT_SECRET=seu-secret
GOOGLE_REDIRECT_URL=http://localhost:3000/auth/google/callback
```

### Passo 3: Rodando a API

```bash
cd api
npm install
npm run start:dev
```

✅ API rodando em: http://localhost:3000

### Passo 4: Rodando o Flutter

```bash
cd flutter
flutter pub get
flutter run
```

---

## 🧪 Testar os Endpoints

### Registrar novo usuário

```bash
curl -X POST http://localhost:3000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "João Silva",
    "email": "joao@email.com",
    "password": "SenhaSegura123",
    "confirmPassword": "SenhaSegura123"
  }'
```

### Fazer login

```bash
curl -X POST http://localhost:3000/auth/signin \
  -H "Content-Type: application/json" \
  -d '{
    "email": "joao@email.com",
    "password": "SenhaSegura123"
  }'
```

### Obter perfil (com token)

```bash
curl -X GET http://localhost:3000/auth/profile \
  -H "Authorization: Bearer seu-token-aqui"
```

---

## 📁 Estrutura de Pastas

```
aplicativo/
├── api/                  # Backend NestJS
│   ├── src/
│   │   ├── auth/        # Autenticação
│   │   ├── supabase/    # Integração Supabase
│   │   ├── users/       # Gerenciar usuários
│   │   └── main.ts      # Iniciar API
│   └── .env            # Variáveis de ambiente
│
├── flutter/            # Frontend Flutter
│   ├── lib/
│   │   ├── screens/    # Telas (login, signup, perfil)
│   │   ├── models/     # Modelos de dados
│   │   ├── services/   # Serviços (API, storage)
│   │   └── main.dart   # Iniciar app
│   └── .env           # Variáveis de ambiente
│
└── DOCUMENTACAO.md    # Documentação completa
```

---

## 🔐 Variáveis de Ambiente

### api/.env
```env
# Supabase
SUPABASE_URL=https://seu-projeto.supabase.co
SUPABASE_ANON_KEY=chave-anonima
SUPABASE_SERVICE_ROLE_KEY=chave-de-servico

# JWT
JWT_SECRET=sua-chave-secreta-segura
JWT_EXPIRATION=7d

# Google
GOOGLE_CLIENT_ID=seu-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=seu-secret
GOOGLE_REDIRECT_URL=http://localhost:3000/auth/google/callback

# API
API_PORT=3000
NODE_ENV=development
```

### flutter/.env
```env
API_BASE_URL=http://localhost:3000
GOOGLE_WEB_CLIENT_ID=seu-web-id.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=seu-ios-id.apps.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID=seu-android-id.apps.googleusercontent.com
```

---

## 🎯 Funcionalidades

| Feature | API | Flutter | Status |
|---------|-----|---------|--------|
| Registrar com Email/Senha | ✅ | ✅ | Completo |
| Login com Email/Senha | ✅ | ✅ | Completo |
| Google OAuth | ✅ | ✅ | Completo |
| Perfil de Usuário | ✅ | ✅ | Completo |
| Editar Perfil | ✅ | ✅ | Completo |
| Imagem de Perfil | ✅ | ✅ | Completo |
| Token Persistente | ✅ | ✅ | Completo |
| Logout | ✅ | ✅ | Completo |

---

## 🔍 Verificação de Segurança

✅ Senhas são hashadas no Supabase
✅ Tokens JWT assinados com `JWT_SECRET`
✅ CORS configurado
✅ Variáveis sensíveis em arquivo `.env`
✅ Validação de dados com DTOs
✅ Proteção de rotas com Guards

---

## ⚠️ Comum Problemas

| Erro | Solução |
|------|---------|
| `Cannot find module` | Execute `npm install` na pasta `api` |
| `SUPABASE_URL is undefined` | Preencha o arquivo `.env` |
| `Google Auth 401` | Verifique as credenciais do Google |
| `Firebase/Flutter erro` | Use `flutter clean` e `flutter pub get` |
| `API não conecta` | Certifique-se que a API está rodando em `3000` |

---

## 📚 Documentação Adicional

- [DOCUMENTACAO.md](./DOCUMENTACAO.md) - Documentação completa
- [api/README.md](./api/README.md) - Details da API
- [flutter/README.md](./flutter/README.md) - Details do Flutter

---

## 🎓 Próximos Passos

1. ✅ Teste o registro e login
2. ✅ Teste o Google Auth
3. ✅ Edite seu perfil
4. ➡️ Adicione mais funcionalidades conforme necessário
5. ➡️ Configure CI/CD para deploy
6. ➡️ Implemente 2FA (autenticação de dois fatores)
7. ➡️ Adicione recuperação de senha

---

## 📞 Suporte

Se encontrar problemas:

1. Verifique os logs da API: `npm run start:dev`
2. Verifique os logs do Flutter: `flutter run`
3. Consulte a DOCUMENTACAO.md
4. Verifique as credenciais no `.env`

---

**Sistema desenvolvido com ❤️**
**Última atualização: 2 de Abril de 2026**
