import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AnalyticsService } from './analytics.service';
import { AiService } from './ai.service';

@Controller('analytics')
@UseGuards(JwtAuthGuard)
export class AnalyticsController {
  constructor(
    private analyticsService: AnalyticsService,
    private aiService: AiService,
  ) {}

  private parseDateParam(value: string | undefined, endOfDay = false): Date | undefined {
    if (!value) {
      return undefined;
    }

    const dateOnlyMatch = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
    if (dateOnlyMatch) {
      const [, year, month, day] = dateOnlyMatch;
      return new Date(
        Date.UTC(
          Number(year),
          Number(month) - 1,
          Number(day),
          endOfDay ? 23 : 0,
          endOfDay ? 59 : 0,
          endOfDay ? 59 : 0,
          endOfDay ? 999 : 0,
        ),
      );
    }

    return new Date(value);
  }

  @Get('operational-summary')
  async getOperationalSummary(
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    try {
      // Converter datas se fornecidas
      const start = this.parseDateParam(startDate);
      const end = this.parseDateParam(endDate, true);

      // Coletar todos os dados
      const [sales, products, profitability, payments, temporal] =
        await Promise.all([
          this.analyticsService.getSalesAnalytics(start, end),
          this.analyticsService.getProductAnalytics(start, end),
          this.analyticsService.getProfitabilityAnalysis(start, end),
          this.analyticsService.getPaymentAnalytics(start, end),
          this.analyticsService.getTemporalAnalytics(start, end),
        ]);

      // Preparar dados para IA
      const analysisData = {
        salesData: sales,
        productsData: products,
        ordersData: {
          profitability,
          temporal,
        },
        paymentsData: payments,
        dateRange: startDate && endDate
          ? `${startDate} a ${endDate}`
          : sales.dateRange || 'Período atual',
      };

      console.log('📊 Enviando dados para IA:', JSON.stringify(analysisData, null, 2));

      // Gerar resumo com IA
      const summary = await this.aiService.generateOperationalSummary(
        analysisData,
      );

      return {
        success: true,
        summary,
        rawData: {
          sales,
          products,
          profitability,
          payments,
          temporal,
        },
      };
    } catch (error: any) {
      console.error('❌ Erro ao gerar resumo operacional:', error);
      return {
        success: false,
        error: error.message || 'Erro ao gerar resumo operacional',
      };
    }
  }

  @Get('sales')
  async getSalesAnalytics(
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    try {
      const start = this.parseDateParam(startDate);
      const end = this.parseDateParam(endDate, true);

      const data = await this.analyticsService.getSalesAnalytics(start, end);
      return { success: true, data };
    } catch (error: any) {
      return { success: false, error: error.message };
    }
  }

  @Get('products')
  async getProductAnalytics(
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    try {
      const start = this.parseDateParam(startDate);
      const end = this.parseDateParam(endDate, true);

      const data = await this.analyticsService.getProductAnalytics(start, end);
      return { success: true, data };
    } catch (error: any) {
      return { success: false, error: error.message };
    }
  }

  @Get('profitability')
  async getProfitabilityAnalytics(
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    try {
      const start = this.parseDateParam(startDate);
      const end = this.parseDateParam(endDate, true);

      const data = await this.analyticsService.getProfitabilityAnalysis(
        start,
        end,
      );
      return { success: true, data };
    } catch (error: any) {
      return { success: false, error: error.message };
    }
  }

  @Get('payments')
  async getPaymentAnalytics(
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    try {
      const start = this.parseDateParam(startDate);
      const end = this.parseDateParam(endDate, true);

      const data = await this.analyticsService.getPaymentAnalytics(start, end);
      return { success: true, data };
    } catch (error: any) {
      return { success: false, error: error.message };
    }
  }

  @Get('temporal')
  async getTemporalAnalytics(
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
  ) {
    try {
      const start = this.parseDateParam(startDate);
      const end = this.parseDateParam(endDate, true);

      const data = await this.analyticsService.getTemporalAnalytics(start, end);
      return { success: true, data };
    } catch (error: any) {
      return { success: false, error: error.message };
    }
  }
}
