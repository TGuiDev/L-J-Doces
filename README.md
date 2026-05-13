# 🍬 L&J Doces - Gestão Inteligente & Cardápio Digital

![NestJS](https://img.shields.io/badge/NestJS-E0234E?style=for-the-badge&logo=nestjs&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![ODS 8](https://img.shields.io/badge/ODS%208-Trabalho%20Decente-A21942?style=for-the-badge)

Sistema completo desenvolvido para modernizar a operação da microempresa **L&J Doces** com dois componentes integrados: uma API em NestJS e um aplicativo Flutter. O foco é eficiência operacional, controle de estoque, vendas, consulta de cardápio em tempo real e apoio à decisão com dados e IA.

---

## 📌 Visão Geral

O projeto é organizado em duas camadas principais:

1. **API (`api/`)**: backend em NestJS responsável por autenticação, usuários, produtos, categorias, pedidos, favoritos, banners, upload, analytics e tempo real.
2. **App Mobile (`mobile/`)**: aplicativo Flutter para clientes e administração, com telas de acesso, consumo do cardápio, checkout, pedidos e gestão.

Documentação central da arquitetura: [docs/01-visao/visao-geral.md](docs/01-visao/visao-geral.md)

## 👥 Equipe e Empresa
* **Integrantes:**
  - Guilherme Portilho<br>
  - Gabrielly Cristina dos Reis<br>
  - Vitória Karolina Santos Silva<br>
  - Leonardo Delfino Vieira
* **Empresa Beneficiada:**
  - L&J Doces.
* **Justificativa Extensionista:**
  - Promoção da modernização tecnológica local e alinhamento ao **ODS 8 (Trabalho Decente e Crescimento Econômico)**.

---

## 📝 Documento de Visão

### 📌 O Problema
Atualmente, a L&J Doces opera de forma presencial e manual. Isso gera:
* Incerteza na reposição de insumos.
* Dificuldade em prever a demanda diária.
* Perda de tempo informando sabores e preços repetidamente aos alunos.

### 🎯 Solução Proposta
Uma solução integrada estruturada em três pilares:
1.  **Módulo de Gestão (Dono):** controle de estoque, vendas, banners, pedidos e acompanhamento operacional.
2.  **Módulo de Consulta (Cliente):** cardápio digital em tempo real, favoritos, pedidos e checkout.
3.  **Diferencial de IA e dados:** análise de tendências e resumo operacional para apoio à produção e tomada de decisão.

---

## 🧱 Arquitetura Do Sistema

### Backend

- **Framework:** NestJS
- **Persistência/Integração:** Supabase
- **Tempo real:** WebSockets / Socket.IO
- **Upload de mídia:** Cloudinary
- **Autenticação:** email/senha, Google OAuth e JWT

### Mobile

- **Framework:** Flutter
- **Estado e integração:** Provider, serviços de API, storage local e Socket.IO
- **Recursos complementares:** Firebase, Google Sign-In, QR Code, offline e sincronização


---

## 📂 Documentação Técnica
Clique nos links abaixo para explorar a documentação complementar do projeto:

* [Hub de documentação](docs/README.md)
* [Visão geral do sistema](docs/01-visao/visao-geral.md)
* [Casos de uso e fluxos do MVP](docs/01-visao/mvp.md)
* [Organograma do projeto](docs/03-processo/organograma.md)
* [Requisitos funcionais](docs/02-requisitos/RF.md)
* [Regras de negócio](docs/02-requisitos/RN.md)
* [Requisitos não funcionais](docs/02-requisitos/RNF.md)
* [Diagramas PUML](docs/05-arquitetura/diagramas/README.md)
