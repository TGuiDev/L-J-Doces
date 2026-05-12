# L&J Doces - API (NestJS)

API backend do projeto L&J Doces implementada em NestJS. Fornece autenticação, gerenciamento de catálogo, pedidos, favoritos, banners, uploads, analytics e integração em tempo real.

## Visão Rápida

- Framework: NestJS
- Persistência: Supabase (Postgres) e serviços externos (Cloudinary)
- Autenticação: JWT + integração opcional com Google
- Tempo real: Socket.IO / WebSockets

## Requisitos

- Node.js 18+ (recomendado)
- npm ou pnpm
- Variáveis de ambiente definidas (ver seção abaixo)

## Instalação

```bash
# Na pasta api/
npm install
```

## Variáveis de ambiente

Crie um `.env` com base em `api/.env.example` e preencha os valores:

```env
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=

JWT_SECRET=
JWT_EXPIRATION=7d

GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REDIRECT_URL=http://localhost:3000/auth/google/callback

FRONTEND_URL=lejdoces://reset-password
NODE_ENV=development
PORT=3000

OPENAI_API_KEY=
GEMINI_API_KEY=

CLOUDINARY_CLOUD_NAME=
CLOUDINARY_UPLOAD_PRESET=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=
CLOUDINARY_URL=
```

Observações:

- Use apenas a `ANON_KEY` do Supabase no cliente; a `SERVICE_ROLE_KEY` deve ficar no servidor.
- `GOOGLE_*` é necessário apenas se o backend orquestrar o fluxo OAuth; o app mobile pode usar Supabase/Google diretamente.
- `FRONTEND_URL` aponta para o deep link usado no fluxo de recuperação de senha no app mobile.
- `PORT` define a porta padrão da API em desenvolvimento.

## Executando em desenvolvimento

```bash
# Rodar em modo watch (Hot reload)
npm run start:dev

# Build e rodar em produção (exemplo)
npm run build
npm run start:prod
```

## Endpoints principais (resumo)

- `POST /auth/signup` - Registrar novo usuário
- `POST /auth/signin` - Login com email/senha
- `POST /auth/google` - Autenticar via Google (recebe idToken do cliente)
- `POST /auth/reset-password` - Solicitar reset de senha
- `GET /users/me` - Obter perfil (autenticado)

- `GET /products` - Listar produtos (com paginação)
- `POST /products` - Criar produto (admin)
- `PUT /products/:id` - Atualizar produto (admin)

- `GET /orders` - Listar pedidos (admin)
- `POST /orders` - Criar pedido (cliente)
- `PUT /orders/:id/status` - Atualizar status do pedido (admin)

> Para detalhes completos dos endpoints, veja os controladores em `src/` e os arquivos de DTO.

## WebSocket / Tempo real

- A API expõe um namespace/socket para eventos de estoque e pedidos.
- Clients (mobile) devem conectar ao endpoint configurado em `API_BASE_URL` e inscrever-se nos eventos relevantes.
- Implementar reconexão automática e re-subscribe em caso de queda.

## Integrações

- Supabase: banco e autenticação auxiliar
- Cloudinary: upload e hospedagem de mídias
- Google OAuth: opcional para autenticação social

## Estrutura do projeto (resumida)

```
src/
├── auth/
├── users/
├── products/
├── orders/
├── banners/
├── analytics/
├── upload/
├── supabase/
├── websockets/
├── app.module.ts
└── main.ts
```

## Scripts úteis

- `npm run start:dev` - Inicia com hot-reload
- `npm run start:prod` - Inicia em modo produção
- `npm run lint` - Rodar linter (se configurado)

## Testes

- Adicione testes unitários e de integração conforme necessário. Este repositório pode incluir `jest` (ver `package.json`).

## Deploy e Docker (opcional)

- Para produção, recomendo criar uma imagem Docker multi-stage com Node 18, copiar `dist` e usar processo gerenciador (PM2 ou node diretamente). Configure variáveis de ambiente no host.

## Contribuição

- Ao alterar requisitos ou endpoints, cite os IDs de requisito (`RF-XX`, `RN-XX`) na PR.
- Atualize a documentação em `docs/` correspondendo às mudanças.

## Contato / Responsáveis

- `Guilherme Portilho` — desenvolvimento full stack / mobile & backend

## Links úteis

- Visão geral: [docs/visao-geral.md](../docs/visao-geral.md)
- MVP / Casos de uso: [docs/mvp.md](../docs/mvp.md)
- RF / RN / RNF: [docs/RF.md](../docs/RF.md), [docs/RN.md](../docs/RN.md), [docs/RNF.md](../docs/RNF.md)
