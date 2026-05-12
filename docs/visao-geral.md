# Visão Geral do Projeto L&J Doces

Este documento consolida a visão macro do sistema para servir como ponto de partida da documentação técnica.

## Objetivo

O projeto moderniza a operação da microempresa L&J Doces com dois componentes integrados:

1. Uma API em NestJS para autenticação, catálogo, pedidos, favoritos, banners, upload, usuários, análise de dados e tempo real.
2. Um aplicativo Flutter para clientes e administração, com telas de consumo do cardápio, fluxo de compra e área de gestão.

O foco funcional atual está em organização operacional, atualização de estoque, venda assistida e consulta de cardápio em tempo real.

## Estrutura Do Repositório

O repositório está dividido em duas camadas principais:

- `api/`: backend NestJS.
- `mobile/`: aplicativo Flutter.
- `docs/`: documentação funcional, técnica e de processos.

## Backend

A API usa NestJS com configuração global de ambiente, validação de DTOs e CORS habilitado para desenvolvimento.

### Módulos principais

- `auth`: login, cadastro, recuperação de acesso e integração com Google OAuth.
- `users`: dados do usuário logado e manutenção de conta.
- `categories`: categorias do catálogo.
- `products`: produtos, estoque e disponibilidade.
- `favorites`: favoritos do cliente.
- `banners`: banners e destaques da vitrine.
- `orders`: pedidos, vendas e histórico operacional.
- `analytics`: indicadores operacionais e geração de resumos com IA.
- `upload`: upload de arquivos e mídia.
- `supabase`: camada de acesso ao Supabase.
- `websockets`: atualização em tempo real.

### Integrações observadas

- Supabase como base de persistência e autenticação auxiliar.
- Cloudinary para mídia.
- Google OAuth.
- Socket.IO/WebSockets para atualização em tempo real.
- IA para resumos operacionais e análise de dados.

## Aplicativo Mobile

O app Flutter inicializa carregando `.env`, Firebase, serviços de API e sincronização em tempo real.

### Camadas principais

- `services`: API, storage local, Firebase e Socket.IO.
- `providers`: autenticação, admin, favoritos, carrinho, pedidos e sincronização.
- `screens`: login, cadastro, recuperação de senha, home, perfil, checkout, pedidos e área administrativa.
- `widgets`: componentes reutilizáveis.
- `theme`: padronização visual.

### Fluxo de inicialização

1. Carrega variáveis do ambiente.
2. Inicializa Firebase quando disponível.
3. Cria os providers e serviços centrais.
4. Conecta ao backend para autenticação e sincronização.
5. Abre a aplicação principal com navegação por rotas.

## Fluxo Funcional Resumido

### Cliente

- Consulta o cardápio digital.
- Visualiza disponibilidade e preços.
- Usa favoritos, perfil, pedidos e checkout.

### Administração

- Faz login administrativo.
- Gerencia produtos, banners e pedidos.
- Registra vendas e acompanha indicadores.

### Tempo Real E Dados

- Mudanças de estoque e pedidos podem refletir no app por sincronização.
- A área de analytics reúne dados operacionais para apoio à decisão.

## Configuração De Ambiente

### API

Variáveis comuns observadas:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `JWT_SECRET`
- `JWT_EXPIRATION`
- `GOOGLE_CLIENT_ID`
- `GOOGLE_CLIENT_SECRET`
- `GOOGLE_REDIRECT_URL`

### Mobile

O app usa `.env` com a URL da API e outras chaves de execução local.

## Documentação Relacionada

- [Visão geral no README raiz](../README.md)
- [Documentação de requisitos](README.md)
- [Requisitos funcionais](RF.md)
- [Regras de negócio](RN.md)
- [Requisitos não funcionais](RNF.md)
- [MVP e casos de uso](mvp.md)
- [Organograma do projeto](organograma.md)

## Próximos Passos

Esta visão geral serve como base para detalhar depois:

- contratos de API;
- mapa de telas do app;
- fluxo de autenticação;
- fluxo de pedidos e estoque;
- padrão de integração entre mobile e backend.