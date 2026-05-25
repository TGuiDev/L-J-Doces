import { Controller, Post, Get, Body, UseGuards, Req, Query, BadRequestException } from '@nestjs/common';
import { Request } from 'express';
import { AuthService } from './auth.service';
import { SignUpDto, SignInDto, ResendConfirmationDto } from './dto/auth.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('signup')
  async signUp(@Body() signUpDto: SignUpDto) {
    console.log('[SignUp] Iniciando registro com dados:', {
      name: signUpDto.name,
      email: signUpDto.email,
      passwordLength: signUpDto.password?.length,
      confirmPasswordMatch: signUpDto.password === signUpDto.confirmPassword,
    });

    try {
      const result = await this.authService.signUp(signUpDto);
      console.log('[SignUp] Sucesso:', { userId: result?.user?.id });
      return result;
    } catch (error) {
      console.error('[SignUp] Erro:', error instanceof Error ? error.message : error);
      throw error;
    }
  }

  @Post('signin')
  async signIn(@Body() signInDto: SignInDto) {
    return this.authService.signIn(signInDto);
  }

  @Post('resend-confirmation')
  async resendConfirmation(@Body() resendDto: ResendConfirmationDto) {
    console.log('[ResendConfirmation] Iniciando reenvio para:', resendDto.email);
    try {
      const result = await this.authService.resendConfirmationEmail(resendDto.email);
      console.log('[ResendConfirmation] Sucesso');
      return result;
    } catch (error) {
      console.error('[ResendConfirmation] Erro:', error instanceof Error ? error.message : error);
      throw error;
    }
  }

  @Post('reset-password')
  async resetPassword(@Body() body: { email: string }) {
    console.log('[ResetPassword] Iniciando redefinição para:', body.email);
    try {
      const result = await this.authService.resetPassword(body.email);
      console.log('[ResetPassword] Sucesso');
      return result;
    } catch (error) {
      console.error('[ResetPassword] Erro:', error instanceof Error ? error.message : error);
      throw error;
    }
  }

  @Post('google')
  async googleAuth(@Body() body: any) {
    console.log('[Controller.GoogleAuth] Iniciando Google Auth');
    console.log('[Controller.GoogleAuth] BODY INTEIRO:', body);

    const idToken = body?.idToken;

    console.log('[Controller.GoogleAuth] idToken length:', idToken?.length);

    try {
      const result = await this.authService.googleAuth(idToken);
      console.log('[Controller.GoogleAuth] Sucesso:', { userId: result?.user?.id });
      return result;
    } catch (error) {
      console.error('[Controller.GoogleAuth] Erro:', error instanceof Error ? error.message : error);
      throw error;
    }
  }

  @Post('update-password')
  @UseGuards(JwtAuthGuard)
  async updatePassword(@Body() body: { password: string }, @Req() req: any) {
    console.log('[UpdatePassword] Iniciando atualização de senha');
    try {
      const userId = req.user.sub;
      const result = await this.authService.updatePassword(userId, body.password);
      console.log('[UpdatePassword] Sucesso');
      return result;
    } catch (error) {
      console.error('[UpdatePassword] Erro:', error instanceof Error ? error.message : error);
      throw error;
    }
  }

  @Post('confirm-reset-password')
  async confirmResetPassword(
    @Body()
    body: {
      password: string;
      code?: string;
      accessToken?: string;
      refreshToken?: string;
    },
  ) {
    console.log('[ConfirmResetPassword] Iniciando redefinicao por link');
    try {
      const result = await this.authService.confirmResetPassword(body);
      console.log('[ConfirmResetPassword] Sucesso');
      return result;
    } catch (error) {
      console.error('[ConfirmResetPassword] Erro:', error instanceof Error ? error.message : error);
      throw error;
    }
  }

  @Get('profile')
  @UseGuards(JwtAuthGuard)
  async getProfile(@Req() req: any) {
    const userId = req.user.sub;
    return this.authService.getProfile(userId);
  }

  @Post('profile/update')
  @UseGuards(JwtAuthGuard)
  async updateProfile(@Req() req: any, @Body() body: { name?: string; picture?: string; phone?: string; password?: string }) {
    const userId = req.user.sub;
    return this.authService.updateProfile(userId, {
      name: body.name,
      picture: body.picture,
      phone: body.phone,
      password: body.password,
    });
  }
}
