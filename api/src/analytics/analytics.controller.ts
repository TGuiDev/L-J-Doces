import { Controller, Get, Query, Res, UseGuards } from '@nestjs/common';
import { Response } from 'express';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AnalyticsService } from './analytics.service';
import { AiService } from './ai.service';

console.log('teste')

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
    @Query('stream') stream?: string,
    @Res({ passthrough: true }) res?: Response,
  ) {
    try {
      const payload = await this.buildOperationalSummaryPayload(
        startDate,
        endDate,
      );

      if (stream === 'true' && res) {
        await this.streamOperationalSummary(res, payload);
        return;
      }

      return {
        success: true,
        summary: payload.aiResult.summary,
        aiSource: payload.aiResult.source,
        usedAi: payload.aiResult.source !== 'fallback',
        fallbackReason: payload.aiResult.fallbackReason,
        providerErrors: payload.aiResult.providerErrors,
        rawData: payload.rawData,
      };

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

      console.log('[analytics] Tentando gerar resumo operacional com IA');
      console.log(
        '[analytics] Dados enviados para IA:',
        JSON.stringify(analysisData, null, 2),
      );

      // Gerar resumo com IA
      const aiResult = await this.aiService.generateOperationalSummary(
        analysisData,
        { allowFallback: true },
      );

      console.log('[analytics] Resumo operacional gerado:', {
        aiSource: aiResult.source,
        usedAi: aiResult.source !== 'fallback',
        fallbackReason: aiResult.fallbackReason ?? null,
        summaryPreview: aiResult.summary?.slice(0, 300),
      });

      return {
        success: true,
        summary: aiResult.summary,
        aiSource: aiResult.source,
        usedAi: aiResult.source !== 'fallback',
        fallbackReason: aiResult.fallbackReason,
        providerErrors: aiResult.providerErrors,
        rawData: {
          sales,
          products,
          profitability,
          payments,
          temporal,
        },
      };
    } catch (error: any) {
      console.error('[analytics] Falha ao gerar resumo operacional:', {
        message: error?.message,
        stack: error?.stack,
      });
      return {
        success: false,
        error: error.message || 'Erro ao gerar resumo operacional',
      };
    }
  }

  private async buildOperationalSummaryPayload(
    startDate?: string,
    endDate?: string,
  ) {
    const start = this.parseDateParam(startDate);
    const end = this.parseDateParam(endDate, true);

    const [sales, products, profitability, payments, temporal] =
      await Promise.all([
        this.analyticsService.getSalesAnalytics(start, end),
        this.analyticsService.getProductAnalytics(start, end),
        this.analyticsService.getProfitabilityAnalysis(start, end),
        this.analyticsService.getPaymentAnalytics(start, end),
        this.analyticsService.getTemporalAnalytics(start, end),
      ]);

    const analysisData = {
      salesData: sales,
      productsData: products,
      ordersData: {
        profitability,
        temporal,
      },
      paymentsData: payments,
      dateRange:
        startDate && endDate
          ? `${startDate} a ${endDate}`
          : sales.dateRange || 'Período atual',
    };

    console.log('[analytics] Tentando gerar resumo operacional com IA');
    console.log(
      '[analytics] Dados enviados para IA:',
      JSON.stringify(analysisData, null, 2),
    );

    const aiResult = await this.aiService.generateOperationalSummary(
      analysisData,
      { allowFallback: true },
    );

    console.log('[analytics] Resumo operacional gerado:', {
      aiSource: aiResult.source,
      usedAi: aiResult.source !== 'fallback',
      fallbackReason: aiResult.fallbackReason ?? null,
      summaryPreview: aiResult.summary?.slice(0, 300),
    });

    return {
      aiResult,
      rawData: {
        sales,
        products,
        profitability,
        payments,
        temporal,
      },
    };
  }

  private async streamOperationalSummary(
    res: Response,
    payload: Awaited<
      ReturnType<AnalyticsController['buildOperationalSummaryPayload']>
    >,
  ) {
    res.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
    res.setHeader('Cache-Control', 'no-cache, no-transform');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders?.();

    this.writeSse(res, 'metadata', {
      success: true,
      aiSource: payload.aiResult.source,
      usedAi: payload.aiResult.source !== 'fallback',
      fallbackReason: payload.aiResult.fallbackReason,
      providerErrors: payload.aiResult.providerErrors,
      rawData: payload.rawData,
    });

    for (const chunk of this.splitStreamText(payload.aiResult.summary)) {
      this.writeSse(res, 'chunk', { text: chunk });
      await new Promise((resolve) => setTimeout(resolve, 18));
    }

    this.writeSse(res, 'done', {
      success: true,
      length: payload.aiResult.summary.length,
    });
    res.end();
  }

  private splitStreamText(text: string): string[] {
    const chunks: string[] = [];
    for (let index = 0; index < text.length; index += 90) {
      chunks.push(text.slice(index, index + 90));
    }

    return chunks.length > 0 ? chunks : [''];
  }

  private writeSse(res: Response, event: string, data: unknown) {
    res.write(`event: ${event}\n`);
    res.write(`data: ${JSON.stringify(data)}\n\n`);
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
