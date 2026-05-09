import { Module } from '@nestjs/common';
import { SupabaseModule } from '../supabase/supabase.module';
import { AnalyticsService } from './analytics.service';
import { AiService } from './ai.service';
import { AnalyticsController } from './analytics.controller';

@Module({
  imports: [SupabaseModule],
  providers: [AnalyticsService, AiService],
  controllers: [AnalyticsController],
  exports: [AnalyticsService, AiService],
})
export class AnalyticsModule {}
