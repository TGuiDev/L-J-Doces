// Tipos para o módulo de Analytics

export interface SalesAnalytics {
  totalOrders: number;
  totalRevenue: number;
  averageOrderValue: number;
  ordersByStatus: Record<string, number>;
  dateRange: string;
}

export interface Product {
  id: string;
  name: string;
  price: number;
  cost_price: number;
  stock_quantity: number;
  category_id: string;
  created_at: string;
}

export interface TopProduct {
  productId: string;
  productName: string;
  quantity: number;
  revenue: number;
  profit?: number;
}

export interface ProductAnalytics {
  topProducts: TopProduct[];
  lowStockProducts: Product[];
  totalProductsInCatalog: number;
}

export interface ProfitabilityAnalytics {
  totalRevenue: number;
  totalCost: number;
  profit: number;
  marginPercentage: string;
  hasLosses: boolean;
  negativeMarginProducts: NegativeMarginProduct[];
}

export interface NegativeMarginProduct {
  name: string;
  revenue: number;
  cost: number;
  loss: number;
}

export interface PaymentAnalytics {
  totalPayments: number;
  completedPayments: number;
  paymentRate: string;
  totalCompletedAmount: number;
  paymentsByStatus: Record<string, number>;
  paymentsByMethod: Record<string, number>;
}

export interface TemporalAnalytics {
  salesByDayOfWeek: Record<string, number>;
  revenueByDayOfWeek: Record<string, number>;
  salesByHour: Record<string, number>;
  revenueByHour: Record<string, number>;
  peakDay: [string, number];
}

export interface AnalysisData {
  salesData: SalesAnalytics;
  productsData: {
    topProducts: TopProduct[];
    lowStockProducts: Product[];
    totalInCatalog: number;
  };
  ordersData: {
    profitability: ProfitabilityAnalytics;
    temporal: TemporalAnalytics;
  };
  paymentsData: PaymentAnalytics;
  dateRange: string;
}

export interface OperationalSummaryResponse {
  success: boolean;
  summary?: string;
  rawData?: {
    sales: SalesAnalytics;
    products: ProductAnalytics;
    profitability: ProfitabilityAnalytics;
    payments: PaymentAnalytics;
    temporal: TemporalAnalytics;
  };
  error?: string;
}

export interface AnalyticsResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

// Enum para status de pagamento
export enum PaymentStatus {
  PENDING = 'pending',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CANCELLED = 'cancelled',
}

// Enum para status de pedido
export enum OrderStatus {
  PENDING = 'pending',
  PROCESSING = 'processing',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
  REFUNDED = 'refunded',
}

// Enum para métodos de pagamento
export enum PaymentMethod {
  CREDIT_CARD = 'credit_card',
  DEBIT_CARD = 'debit_card',
  PIX = 'pix',
  BANK_TRANSFER = 'bank_transfer',
  SIMULATED = 'simulated',
}
