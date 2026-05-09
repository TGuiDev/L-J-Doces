# 🔐 Guia de Segurança e Boas Práticas

## ⚠️ Checklist de Segurança

### ✅ Antes de Colocar em Produção

- [ ] **Variáveis de Ambiente**
  - [ ] `.env` adicionado ao `.gitignore`
  - [ ] `OPENAI_API_KEY` está segura
  - [ ] `SUPABASE_SERVICE_ROLE_KEY` não é compartilhada
  - [ ] JWT_SECRET é aleatório e forte

- [ ] **Autenticação**
  - [ ] Endpoint requer autenticação JWT
  - [ ] Tokens possuem expiração (ex: 1 hora)
  - [ ] Implementar rate limiting
  - [ ] Validar permissão de admin (não qualquer autenticado)

- [ ] **Banco de Dados**
  - [ ] RLS (Row Level Security) habilitado no Supabase
  - [ ] Índices criados em colunas frequentemente consultadas
  - [ ] Backup automático configurado
  - [ ] Logs de auditoria ativos

- [ ] **API OpenAI**
  - [ ] Monitorar uso e custos
  - [ ] Implementar quota/limite de análises por dia
  - [ ] Usar API Key com permissões restritas se possível
  - [ ] Rotacionar chave periodicamente

- [ ] **Infraestrutura**
  - [ ] HTTPS/SSL obrigatório
  - [ ] CORS configurado corretamente
  - [ ] Modo produção do NestJS
  - [ ] Logs centralizados

## 🔒 Implementações de Segurança Necessárias

### 1. Restricão por Role (Admin Only)

Crie um Enum para roles:

```typescript
// src/auth/roles.enum.ts
export enum UserRole {
  ADMIN = 'admin',
  USER = 'user',
  MODERATOR = 'moderator',
}
```

Crie um Decorator:

```typescript
// src/auth/roles.decorator.ts
import { SetMetadata } from '@nestjs/common';
import { UserRole } from './roles.enum';

export const Roles = (...roles: UserRole[]) => SetMetadata('roles', roles);
```

Crie um Guard:

```typescript
// src/auth/roles.guard.ts
import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserRole } from './roles.enum';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const roles = this.reflector.get<UserRole[]>('roles', context.getHandler());
    if (!roles) {
      return true;
    }

    const request = context.switchToHttp().getRequest();
    const user = request.user;

    return roles.includes(user.role);
  }
}
```

Use no Controller:

```typescript
// src/analytics/analytics.controller.ts
import { UseGuards } from '@nestjs/common';
import { Roles } from '../auth/roles.decorator';
import { RolesGuard } from '../auth/roles.guard';
import { UserRole } from '../auth/roles.enum';

@Controller('analytics')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AnalyticsController {
  @Get('operational-summary')
  @Roles(UserRole.ADMIN)
  async getOperationalSummary(...) {
    // Apenas admins podem acessar
  }
}
```

### 2. Rate Limiting

```bash
npm install @nestjs/throttler
```

```typescript
// app.module.ts
import { ThrottlerModule } from '@nestjs/throttler';

@Module({
  imports: [
    ThrottlerModule.forRoot([
      {
        ttl: 60000,      // 1 minuto
        limit: 10,       // máximo 10 requisições
      },
    ]),
    // ... outros imports
  ],
})
export class AppModule {}
```

No Controller:

```typescript
import { Throttle } from '@nestjs/throttler';

@Controller('analytics')
export class AnalyticsController {
  @Get('operational-summary')
  @Throttle({ default: { limit: 5, ttl: 3600000 } }) // 5x por hora
  async getOperationalSummary(...) {
    // Implementação
  }
}
```

### 3. Validação de Query Parameters

```typescript
import { IsDateString, IsOptional } from 'class-validator';

export class AnalyticsQueryDto {
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;
}
```

No Controller:

```typescript
import { Query, UsePipes, ValidationPipe } from '@nestjs/common';

@Get('operational-summary')
@UsePipes(new ValidationPipe({ transform: true }))
async getOperationalSummary(@Query() query: AnalyticsQueryDto) {
  // query.startDate e query.endDate são validadas
}
```

### 4. Monitoramento de Custos OpenAI

```typescript
// src/analytics/openai-monitor.service.ts
import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class OpenAiMonitorService {
  private readonly logger = new Logger(OpenAiMonitorService.name);
  private dailyTokens = 0;
  private monthlyTokens = 0;
  private readonly dailyLimit = 100000; // tokens por dia
  private readonly monthlyLimit = 1000000; // tokens por mês

  trackTokenUsage(tokens: number) {
    this.dailyTokens += tokens;
    this.monthlyTokens += tokens;

    const dailyPercent = (this.dailyTokens / this.dailyLimit) * 100;
    const monthlyPercent = (this.monthlyTokens / this.monthlyLimit) * 100;

    this.logger.log(`Daily usage: ${dailyPercent.toFixed(2)}%`);
    this.logger.log(`Monthly usage: ${monthlyPercent.toFixed(2)}%`);

    if (dailyPercent > 90) {
      this.logger.warn('⚠️ Approaching daily limit!');
    }

    if (monthlyPercent > 80) {
      this.logger.warn('⚠️ High monthly usage!');
    }
  }

  resetDaily() {
    this.dailyTokens = 0;
  }
}
```

### 5. Implementar Cache

```bash
npm install @nestjs/cache-manager cache-manager
```

```typescript
// src/analytics/analytics.service.ts
import { Cacheable } from '@nestjs/cache-manager';

@Injectable()
export class AnalyticsService {
  @Cacheable({
    key: 'operational-summary',
    ttl: 3600000, // 1 hora
  })
  async getOperationalSummary(...) {
    // Resultado será cacheado por 1 hora
  }
}
```

## 🚨 Logs e Monitoramento

### 1. Estruturar Logs

```typescript
import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class AnalyticsService {
  private readonly logger = new Logger(AnalyticsService.name);

  async getSalesAnalytics() {
    this.logger.log('Iniciando análise de vendas');

    try {
      const data = await this.supabase.from('orders').select();
      this.logger.log(`✅ Análise concluída: ${data.length} pedidos`);
      return data;
    } catch (error) {
      this.logger.error(`❌ Erro na análise: ${error.message}`);
      throw error;
    }
  }
}
```

### 2. Alertas de Erros

```typescript
// Quando OpenAI falha muito
if (failureCount > 3) {
  await sendEmailToAdmin('OpenAI API está falhando');
}

// Quando custos sobem demais
if (monthlyUsage > threshold) {
  await sendEmailToAdmin('Aviso: Custos OpenAI acima do esperado');
}
```

## 💰 Gerenciamento de Custos OpenAI

### Dicas para Reduzir Gastos

1. **Use GPT-3.5 ao invés de GPT-4**
   - 3.5: $0.001/1K tokens (entrada)
   - 4: $0.03/1K tokens (entrada)
   - Economia: 97% ⚠️

   ```typescript
   model: 'gpt-3.5-turbo' // ao invés de 'gpt-4'
   ```

2. **Implemente Cache**
   - Evita duplicar análises
   - Cache por 1-24 horas dependendo da necessidade

3. **Limite Análises por Usuário**
   - Máximo 2 análises/hora por admin
   - Máximo 10 análises/dia por admin

4. **Simplifique o Prompt**
   - Remova análises desnecessárias
   - Use templates pré-processados

5. **Batch Processing**
   - Processe múltiplas lojas em uma única chamada
   - Economiza tokens

### Monitorar Custos

1. Acesse [https://platform.openai.com/account/usage](https://platform.openai.com/account/usage)
2. Configure alertas
3. Revise diariamente nos primeiros dias

## 🔄 Rotinas de Manutenção

### Diárias
- [ ] Verificar logs de erro
- [ ] Monitorar uso OpenAI
- [ ] Verificar uptime do Supabase

### Semanais
- [ ] Analisar custos
- [ ] Revisar queries lentas
- [ ] Atualizar dependências menores

### Mensalmente
- [ ] Atualizar dependências maiores
- [ ] Analisar performance
- [ ] Revisar política de backup
- [ ] Auditar acessos

## 🛡️ GDPR e Privacidade

Se aplicável ao seu negócio:

- [ ] Dados pessoais não são enviados para OpenAI
- [ ] Conformidade LGPD (lei brasileira)
- [ ] Termo de privacidade atualizado
- [ ] Direito ao esquecimento implementado

## 📋 Documentação de Segurança

Mantenha documentado:

1. Quem tem acesso (admins)
2. O que é acessado (dados operacionais)
3. Quando é acessado (logs de requisições)
4. Onde está armazenado (Supabase + OpenAI)
5. Como é protegido (JWT + HTTPS + Role)

## 🚀 Deployment em Produção

Checklist final:

```bash
# 1. Build
npm run build

# 2. Testes
npm run test

# 3. Lint
npm run lint

# 4. Variáveis de ambiente
# - Verificar .env com valores reais
# - OPENAI_API_KEY válida
# - SUPABASE_SERVICE_ROLE_KEY correto
# - JWT_SECRET forte

# 5. HTTPS/SSL
# - Certificado SSL configurado
# - Redirecionar HTTP → HTTPS

# 6. Monitoramento
# - Datadog / Sentry / CloudWatch configurado
# - Alertas para erros críticos

# 7. Backup
# - Backup automático Supabase ativo
# - Teste restore

# 8. Go live!
npm run start:prod
```

---

**Lembre-se:** Segurança é um processo contínuo, não um estado final.
