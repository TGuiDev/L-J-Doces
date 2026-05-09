### Exemplos de Uso da API de Analytics

## 1. Resumo Operacional com IA (Recomendado para Admins)

### cURL

```bash
# Últimos 30 dias (padrão)
curl -X GET "http://localhost:3000/analytics/operational-summary" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Período específico
curl -X GET "http://localhost:3000/analytics/operational-summary?startDate=2024-01-01&endDate=2024-01-31" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### JavaScript/TypeScript (Axios)

```typescript
import axios from 'axios';

async function getOperationalSummary(token: string, startDate?: string, endDate?: string) {
  try {
    const response = await axios.get(
      'http://localhost:3000/analytics/operational-summary',
      {
        headers: {
          Authorization: `Bearer ${token}`,
        },
        params: {
          startDate, // ex: "2024-01-01"
          endDate,   // ex: "2024-01-31"
        },
      }
    );

    console.log('Resumo Operacional:');
    console.log(response.data.summary);

    return response.data;
  } catch (error) {
    console.error('Erro ao buscar resumo:', error);
  }
}
```

### Dart/Flutter

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> getOperationalSummary(String token, {String? startDate, String? endDate}) async {
  try {
    String url = 'http://localhost:3000/analytics/operational-summary';

    if (startDate != null || endDate != null) {
      final params = <String, String>{};
      if (startDate != null) params['startDate'] = startDate;
      if (endDate != null) params['endDate'] = endDate;

      url = '$url?${Uri(queryParameters: params).query}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Resumo Operacional:');
      print(data['summary']);
    }
  } catch (e) {
    print('Erro: $e');
  }
}
```

### Python/FastAPI

```python
import requests

def get_operational_summary(token: str, start_date: str = None, end_date: str = None):
    url = "http://localhost:3000/analytics/operational-summary"

    params = {}
    if start_date:
        params['startDate'] = start_date
    if end_date:
        params['endDate'] = end_date

    headers = {
        "Authorization": f"Bearer {token}"
    }

    response = requests.get(url, headers=headers, params=params)

    if response.status_code == 200:
        data = response.json()
        print("Resumo Operacional:")
        print(data['summary'])
        return data
    else:
        print(f"Erro: {response.status_code}")
```

## 2. Análise Individual de Vendas

```typescript
async function getSalesAnalytics(token: string) {
  const response = await axios.get('http://localhost:3000/analytics/sales', {
    headers: { Authorization: `Bearer ${token}` },
    params: {
      startDate: '2024-01-01',
      endDate: '2024-01-31',
    },
  });

  return response.data.data;
  // Retorna: { totalOrders, totalRevenue, averageOrderValue, ordersByStatus }
}
```

## 3. Produtos e Estoque

```typescript
async function getProductAnalytics(token: string) {
  const response = await axios.get('http://localhost:3000/analytics/products', {
    headers: { Authorization: `Bearer ${token}` },
  });

  const { topProducts, lowStockProducts } = response.data.data;

  console.log('Top 10 Produtos:', topProducts);
  console.log('Produtos com Estoque Baixo:', lowStockProducts);
}
```

## 4. Lucratividade e Margens

```typescript
async function getProfitabilityAnalytics(token: string) {
  const response = await axios.get('http://localhost:3000/analytics/profitability', {
    headers: { Authorization: `Bearer ${token}` },
  });

  const { profit, marginPercentage, negativeMarginProducts } = response.data.data;

  console.log(`Lucro Total: R$ ${profit}`);
  console.log(`Margem: ${marginPercentage}%`);

  if (negativeMarginProducts.length > 0) {
    console.warn('⚠️ Produtos com Prejuízo:');
    console.table(negativeMarginProducts);
  }
}
```

## 5. Análise Temporal (Picos de Vendas)

```typescript
async function getTemporalAnalytics(token: string) {
  const response = await axios.get('http://localhost:3000/analytics/temporal', {
    headers: { Authorization: `Bearer ${token}` },
  });

  const { salesByDayOfWeek, revenueByHour, peakDay } = response.data.data;

  console.log('Vendas por dia da semana:', salesByDayOfWeek);
  console.log('Receita por hora:', revenueByHour);
  console.log('Dia de pico:', peakDay);
}
```

## 6. Integração no Admin Dashboard (React)

```typescript
import { useState, useEffect } from 'react';

function AdminDashboard({ token }: { token: string }) {
  const [summary, setSummary] = useState<string>('');
  const [loading, setLoading] = useState(false);
  const [dateRange, setDateRange] = useState({
    startDate: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    endDate: new Date().toISOString().split('T')[0],
  });

  const generateSummary = async () => {
    setLoading(true);
    try {
      const response = await axios.get(
        'http://localhost:3000/analytics/operational-summary',
        {
          headers: { Authorization: `Bearer ${token}` },
          params: dateRange,
        }
      );

      setSummary(response.data.summary);
    } catch (error) {
      console.error('Erro:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="admin-dashboard">
      <h1>Resumo Operacional</h1>

      <div className="date-picker">
        <input
          type="date"
          value={dateRange.startDate}
          onChange={(e) => setDateRange({ ...dateRange, startDate: e.target.value })}
        />
        <input
          type="date"
          value={dateRange.endDate}
          onChange={(e) => setDateRange({ ...dateRange, endDate: e.target.value })}
        />
        <button onClick={generateSummary} disabled={loading}>
          {loading ? 'Gerando...' : 'Gerar Resumo'}
        </button>
      </div>

      {summary && (
        <div className="summary-container">
          <pre>{summary}</pre>
        </div>
      )}
    </div>
  );
}

export default AdminDashboard;
```

## 7. Agendamento Automático (com node-cron)

```typescript
import cron from 'node-cron';

// Gerar relatório todo dia às 9 AM
cron.schedule('0 9 * * *', async () => {
  try {
    const summary = await generateOperationalSummary();

    // Salvar em banco de dados
    await saveReport({
      date: new Date(),
      content: summary,
      type: 'daily',
    });

    // Ou enviar por email
    await sendEmailToAdmin(summary);

    console.log('✅ Relatório diário gerado');
  } catch (error) {
    console.error('❌ Erro ao gerar relatório:', error);
  }
});
```

## 8. Tratamento de Erros

```typescript
async function generateSummaryWithErrorHandling(token: string) {
  try {
    const response = await axios.get(
      'http://localhost:3000/analytics/operational-summary',
      {
        headers: { Authorization: `Bearer ${token}` },
        timeout: 30000, // 30 segundos
      }
    );

    if (!response.data.success) {
      throw new Error(response.data.error);
    }

    return response.data.summary;
  } catch (error) {
    if (error.response?.status === 401) {
      console.error('Token expirado');
      // Renovar token
    } else if (error.response?.status === 403) {
      console.error('Sem permissão para acessar analytics');
    } else if (error.code === 'ECONNABORTED') {
      console.error('Requisição expirou - tente novamente');
    } else {
      console.error('Erro desconhecido:', error.message);
    }
  }
}
```

## Dicas Importantes

1. **Sempre use HTTPS em produção**
2. **Implemente rate limiting** para não exceder quotas da OpenAI
3. **Cache os resultados** por algumas horas para economizar custos
4. **Monitore uso da API OpenAI** para evitar surpresas de cobrança
5. **Teste primeiro com GPT-3.5** (mais barato) antes de usar GPT-4
