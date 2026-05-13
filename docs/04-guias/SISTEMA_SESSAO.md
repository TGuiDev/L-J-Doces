# 🔐 Sistema de Sessão e Autenticação

## ✨ Como Funciona:

### 1. **Token Salvo por 7 Dias**
```dart
// Armazenado em SharedPreferences com expiração
- Token: salvo em _auth_token
- Expiração: agora + 7 dias (em millisegundos)
```

### 2. **Fluxo de Login**
```
1. Usuário faz login (email/senha ou Google)
2. API retorna token + dados do usuário
3. Token + expiração salva em SharedPreferences
4. Usuário salvo em SharedPreferences
5. App automaticamente navega para Home
6. Sessão mantida mesmo fechando o app
```

### 3. **Ao Reabrir o App**
```
1. Splash Screen mostra enquanto carrega
2. App verifica se token existe em SharedPreferences
3. Se existe e não expirou:
   - Carrega o usuário do storage local
   - Tenta sincronizar com servidor
   - Leva para Home (sessão restaurada)
4. Se não existe ou expirou:
   - Leva para SignIn
   - Usuário faz login novamente
```

### 4. **Verificação de Expiração**
```dart
// Automático ao tentar usar o token:
- Se expirou: token é deletado
- Se válido: retorna o token e quantidade de dias restantes
```

## 📊 Informações Disponíveis:

```dart
// No AuthProvider, você pode acessar:
authProvider.isAuthenticated      // true/false - autenticado?
authProvider.user                 // User? - dados do usuário
authProvider.token                // String? - token JWT
authProvider.tokenExpiryDaysRemaining // int - dias até expirar
authProvider.expiryMessage        // String - mensagem legível
authProvider.isLoading            // bool - carregando?
authProvider.error                // String? - mensagem de erro
```

## 🎯 Exemplo de Uso:

### No Home Screen:
```dart
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    return Column(
      children: [
        Text('Conectado como: ${authProvider.user?.name}'),
        Text('Sessão expira em: ${authProvider.expiryMessage}'),
        if (authProvider.tokenExpiryDaysRemaining == 1)
          Text('⚠️ Sua sessão expira em 1 dia'),
      ],
    );
  },
)
```

### Logout Manual:
```dart
ElevatedButton(
  onPressed: () async {
    await authProvider.logout();
    // Automaticamente volta para SignIn
  },
  child: Text('Sair'),
)
```

## 🔄 Ciclo de Vida da Sessão:

```
┌─────────────────────────────────────────────────────┐
│                    APP INICIA                       │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
         ┌──────────────────────┐
         │  Splash Screen       │
         │  Carregando sessão   │
         └────────┬─────────────┘
                  │
                  ▼
        ┌────────────────────────────┐
        │ Token vem em SharedPrefs? │
        └────┬──────────────────┬────┘
             │ SIM              │ NÃO
             ▼                  ▼
        ┌─────────────┐  ┌──────────────┐
        │ Verificar   │  │  SignIn      │
        │ Expiração   │  │  Screen      │
        └────┬────┬───┘  └──────────────┘
             │    │
        EXPIROU   VÁLIDO
             │    │
             ▼    ▼
        ┌──────────────────────────┐
        │  Carregar dados do       │
        │  servidor (opcional)     │
        └───────┬──────────────────┘
                │
                ▼
        ┌──────────────────┐
        │  Home Screen     │
        │  Sessão ativa    │
        │  Por 7 dias      │
        └──────────────────┘
```

## ⚙️ Configuração:

### Mudar tempo de expiração (padrão: 7 dias):

Arquivo: `lib/services/storage_service.dart`
```dart
static const int _tokenExpiryDays = 7;  // ← Mudar aqui
```

### Adicionar refresh de token:

```dart
// Adicione este método em auth_provider.dart
Future<void> refreshTokenIfNeeded() async {
  if (tokenExpiryDaysRemaining < 2) {
    // Solicita novo token ao servidor
    // Salva novo token e expiração
  }
}
```

## 🚀 Fluxo Completo de Login:

```
1. User abre app
   ↓
2. Splash Screen aparece (3 segundos)
   ↓
3. AuthProvider.init() é chamado
   ↓
4. Verifica localStorage.getToken()
   ├─ Token válido? → Carrega sessão → Home Screen ✓
   └─ Token inválido/expirado? → SignIn Screen

5. User digita email/senha
   ↓
6. API /auth/signin retorna token
   ↓
7. Token + expiração salvos
   ↓
8. User + dados salvos
   ↓
9. Automático: Consumer<AuthProvider> notificado
   ↓
10. App navega para Home Screen ✓

11. Se fechar app e reabrir:
    - Splash Screen novamente
    - Token verificado
    - Se válido → Home (sessão mantida)
    - Se expirado → SignIn
```

---

**RESUMO:** Seu app agora salva a sessão por 7 dias, mantém mesmo fechando, e faz auto-logout se expirar! 🎉
