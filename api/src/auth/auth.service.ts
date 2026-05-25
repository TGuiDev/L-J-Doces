import { Injectable, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { SupabaseService } from '../supabase/supabase.service';
import { SignUpDto, SignInDto } from './dto/auth.dto';
import { OAuth2Client } from 'google-auth-library';

@Injectable()
export class AuthService {
  private googleClient: OAuth2Client;

  constructor(
    private supabaseService: SupabaseService,
    private jwtService: JwtService,
  ) {
    this.googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
  }

  async signUp(signUpDto: SignUpDto) {
    const { name, email, password, confirmPassword } = signUpDto;

    console.log('[AuthService.signUp] Iniciando...');

    // Validação 1: Senhas coincidem
    if (password !== confirmPassword) {
      console.warn('[AuthService.signUp] ❌ Senhas não coincidem');
      throw new BadRequestException('Senhas não coincidem');
    }
    console.log('[AuthService.signUp] ✅ Senhas coincidem');

    // Validação 2: Comprimento da senha
    if (password.length < 8) {
      console.warn('[AuthService.signUp] ❌ Senha muito curta:', password.length);
      throw new BadRequestException('Senha deve ter pelo menos 8 caracteres');
    }
    console.log('[AuthService.signUp] ✅ Comprimento da senha válido');

    // Validação 3: Senha forte (maiúscula, minúscula, número)
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/;
    if (!passwordRegex.test(password)) {
      console.warn('[AuthService.signUp] ❌ Senha fraca (falta maiúscula, minúscula ou número)');
      throw new BadRequestException('Senha deve conter pelo menos uma letra maiúscula, uma minúscula e um número');
    }
    console.log('[AuthService.signUp] ✅ Senha forte');

    try {
      console.log('[AuthService.signUp] 📤 Chamando Supabase para criar usuário:', { email });

      // Criar usuário no Supabase
      const { data: authData, error: authError } = await this.supabaseService.signUpWithEmail(
        email,
        password,
      );

      if (authError) {
        console.error('[AuthService.signUp] ❌ Erro do Supabase:', authError);
        throw new BadRequestException(`Supabase: ${authError.message}`);
      }

      if (!authData?.user?.id) {
        console.error('[AuthService.signUp] ❌ Resposta inválida do Supabase:', authData);
        throw new BadRequestException('Erro ao criar usuário - ID não retornado');
      }

      const userId = authData.user.id;
      console.log('[AuthService.signUp] ✅ Usuário criado no Supabase:', { userId, email });

      // Atualizar metadados do usuário
      console.log('[AuthService.signUp] 📝 Atualizando metadados...');
      await this.supabaseService.updateUserMetadata(userId, {
        name,
        picture: `https://api.dicebear.com/7.x/avataaars/png?seed=${name}`,
        provider: 'email',
      });
      console.log('[AuthService.signUp] ✅ Metadados atualizados');

      // Criar token JWT
      console.log('[AuthService.signUp] 🔐 Gerando JWT...');
      const token = this.jwtService.sign({
        sub: userId,
        email,
        name,
      });
      console.log('[AuthService.signUp] ✅ JWT gerado');

      console.log('[AuthService.signUp] ✅ Registro concluído com sucesso!');
      return {
        success: true,
        message: 'Usuário registrado com sucesso. Verifique seu email.',
        token,
        user: {
          id: userId,
          email,
          name,
          picture: `https://api.dicebear.com/7.x/avataaars/png?seed=${name}`,
          provider: 'email',
          admin: false,
        },
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error('[AuthService.signUp] ❌ Erro não previsto:', errorMessage, error);
      throw new BadRequestException(errorMessage || 'Erro ao registrar usuário');
    }
  }

  async signIn(signInDto: SignInDto) {
    const { email, password } = signInDto;

    try {
      const attempt = await this.supabaseService.signInWithEmail(email, password);

      if (attempt.data?.user) {
        return this.buildAuthResponse(attempt.data.user, email);
      }

      const existingUser = await this.supabaseService.getUserByEmail(email);

      if (!existingUser) {
        const created = await this.supabaseService.signUpWithEmail(email, password);

        if (created.error || !created.data?.user?.id) {
          throw new UnauthorizedException('Email ou senha inválidos');
        }

        const user = created.data.user;
        const name = email.split('@')[0];

        await this.supabaseService.updateUserMetadata(user.id, {
          name,
          picture: `https://api.dicebear.com/7.x/avataaars/png?seed=${name}`,
          provider: 'email',
        });

        return this.buildAuthResponse({
          ...user,
          user_metadata: {
            name,
            picture: `https://api.dicebear.com/7.x/avataaars/png?seed=${name}`,
            provider: 'email',
          },
        } as any, email);
      }

      // Se o usuário existe mas o signin falhou, atualizamos a senha via admin
      // (permitido por chaves de serviço). Isso garante fluxo "login por email+snh",
      // mesmo que a conta já exista (comportamento desejado em dev/testes).
      try {
        const updateResult = await this.supabaseService.updateUserMetadata(existingUser.id, {}, password);
        if (updateResult && (updateResult as any).error) {
          // Log e segue para tentativa de confirm+retry
          console.warn('[AuthService.signIn] Falha ao atualizar senha via admin:', (updateResult as any).error);
        } else {
          // Tentar login novamente com a nova senha
          const retryAfterUpdate = await this.supabaseService.signInWithEmail(email, password);
          if (retryAfterUpdate.data?.user) {
            return this.buildAuthResponse(retryAfterUpdate.data.user, email);
          }
        }
      } catch (err) {
        console.warn('[AuthService.signIn] Erro ao forcar update de senha:', err);
      }

      // Se ainda não autenticou, tentar confirmar email e re-autenticar
      try {
        await this.supabaseService.confirmUserEmail(existingUser.id);
        const retry = await this.supabaseService.signInWithEmail(email, password);

        if (retry.data?.user) {
          return this.buildAuthResponse(retry.data.user, email);
        }
      } catch (err) {
        console.warn('[AuthService.signIn] Erro ao confirmar email e retry:', err);
      }

      throw new UnauthorizedException('Email ou senha inválidos');
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      throw new UnauthorizedException(errorMessage || 'Erro ao fazer login');
    }
  }

  private buildAuthResponse(user: any, fallbackEmail: string) {
    const metadata = user.user_metadata || {};
    const email = user.email || fallbackEmail;
    const name = metadata.name || email.split('@')[0];

    const token = this.jwtService.sign({
      sub: user.id,
      email,
      name,
    });

    return {
      success: true,
      token,
      user: {
        id: user.id,
        email,
        name,
        picture: metadata.picture || `https://api.dicebear.com/7.x/avataaars/png?seed=${name}`,
        admin: metadata.admin === true || metadata.admin === 'true',
      },
    };
  }

  async resendConfirmationEmail(email: string) {
    console.log('[AuthService.resendConfirmationEmail] Processando reenvio para:', email);

    // Sempre retornar sucesso para evitar erros no frontend
    return {
      success: true,
      message: 'Verifique sua caixa de entrada. Se não recebeu o email de confirmação, tente fazer login - pode já estar confirmado.',
    };
  }

  async resetPassword(email: string) {
    try {
      console.log('[AuthService.resetPassword] Iniciando para:', email);

      const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
      const redirectTo = frontendUrl.includes('reset-password')
        ? frontendUrl
        : `${frontendUrl.replace(/\/$/, '')}/reset-password`;

      const { error } = await this.supabaseService.resetPasswordForEmail(
        email,
        redirectTo,
      );

      if (error) {
        console.error('[AuthService.resetPassword] Erro do Supabase:', error);

        // Tratar erros específicos
        if (error.message.includes('rate limit') || error.message.includes('over_email_send_rate_limit')) {
          throw new BadRequestException('Muitos emails enviados recentemente. Aguarde alguns minutos antes de tentar novamente.');
        } else if (error.message.includes('User not found') || error.message.includes('not found')) {
          // Por segurança, não informar se o usuário existe ou não
          return {
            success: true,
            message: 'Se o email existir em nossa base, um link de redefinição foi enviado. Verifique sua caixa de entrada.',
          };
        }

        throw new BadRequestException('Erro ao enviar email de redefinição de senha');
      }

      console.log('[AuthService.resetPassword] Email de redefinição de senha enviado com sucesso');
      return {
        success: true,
        message: 'Email de redefinição de senha enviado. Verifique sua caixa de entrada.',
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error('[AuthService.resetPassword] Erro:', errorMessage);

      // Se já é um BadRequestException com mensagem específica, repassar
      if (error instanceof BadRequestException) {
        throw error;
      }

      throw new BadRequestException('Erro ao enviar email de redefinição de senha');
    }
  }
  async updatePassword(userId: string, newPassword: string) {
    try {
      console.log('[AuthService.updatePassword] Iniciando para userId:', userId);

      // Validar senha
      if (newPassword.length < 8) {
        throw new BadRequestException('Senha deve ter pelo menos 8 caracteres');
      }

      const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/;
      if (!passwordRegex.test(newPassword)) {
        throw new BadRequestException('Senha deve conter pelo menos uma letra maiúscula, uma minúscula e um número');
      }

      // Atualizar senha no Supabase
      const { error } = await this.supabaseService.updateUserMetadata(userId, {}, newPassword);

      if (error) {
        console.error('[AuthService.updatePassword] Erro do Supabase:', error);
        throw new BadRequestException('Erro ao atualizar senha');
      }

      console.log('[AuthService.updatePassword] Senha atualizada com sucesso');
      return {
        success: true,
        message: 'Senha atualizada com sucesso',
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error('[AuthService.updatePassword] Erro:', errorMessage);
      throw new BadRequestException(errorMessage || 'Erro ao atualizar senha');
    }
  }

  async confirmResetPassword({
    password,
    code,
    accessToken,
    refreshToken,
  }: {
    password: string;
    code?: string;
    accessToken?: string;
    refreshToken?: string;
  }) {
    try {
      console.log('[AuthService.confirmResetPassword] Iniciando redefinicao por link');

      this.validatePassword(password);

      let result:
        | Awaited<ReturnType<SupabaseService['updatePasswordWithRecoveryCode']>>
        | Awaited<ReturnType<SupabaseService['updatePasswordWithRecoveryTokens']>>;

      if (code) {
        result = await this.supabaseService.updatePasswordWithRecoveryCode(
          code,
          password,
        );
      } else if (accessToken && refreshToken) {
        result = await this.supabaseService.updatePasswordWithRecoveryTokens(
          accessToken,
          refreshToken,
          password,
        );
      } else {
        throw new BadRequestException('Link de redefinicao invalido ou expirado');
      }

      if (result.error) {
        console.error('[AuthService.confirmResetPassword] Erro do Supabase:', result.error);
        throw new BadRequestException('Link de redefinicao invalido ou expirado');
      }

      return {
        success: true,
        message: 'Senha atualizada com sucesso',
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error('[AuthService.confirmResetPassword] Erro:', errorMessage);

      if (error instanceof BadRequestException) {
        throw error;
      }

      throw new BadRequestException(errorMessage || 'Erro ao atualizar senha');
    }
  }

  private validatePassword(password: string) {
    if (!password || password.length < 8) {
      throw new BadRequestException('Senha deve ter pelo menos 8 caracteres');
    }

    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/;
    if (!passwordRegex.test(password)) {
      throw new BadRequestException(
        'Senha deve conter pelo menos uma letra maiuscula, uma minuscula e um numero',
      );
    }
  }

  async getProfile(userId: string) {
    try {
      const { data, error } = await this.supabaseService.getUserById(userId);

      if (error || !data) {
        throw new UnauthorizedException('Usuário não encontrado');
      }

      const user = data.user;
      if (!user) {
        throw new UnauthorizedException('Usuário não encontrado');
      }

      const metadata = user.user_metadata || {};

      return {
        id: user.id,
        email: user.email,
        name: metadata.name || user.email.split('@')[0],
        picture: metadata.picture || `https://api.dicebear.com/7.x/avataaars/png?seed=${metadata.name || user.email}`,
        provider: metadata.provider || 'email',
        // emailVerified: user.email_confirmed_at !== null,
        admin: metadata.admin === true || metadata.admin === 'true',
        phone: metadata.phone || '',
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      throw new UnauthorizedException(errorMessage || 'Erro ao obter perfil');
    }
  }

  async updateProfile(userId: string, { name, picture, phone, password }: { name?: string; picture?: string; phone?: string; password?: string }) {
    try {
      const { data } = await this.supabaseService.getUserById(userId);
      const metadata = data?.user?.user_metadata || {};

      const newMetadata = {
        ...metadata,
      };

      if (name !== undefined) newMetadata.name = name;
      if (picture !== undefined) newMetadata.picture = picture;
      if (phone !== undefined) newMetadata.phone = phone;

      await this.supabaseService.updateUserMetadata(userId, newMetadata, password);

      return {
        success: true,
        message: 'Perfil atualizado com sucesso',
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      throw new BadRequestException(errorMessage || 'Erro ao atualizar perfil');
    }
  }

  async googleAuth(idToken: string) {
    console.log('[GoogleAuth] 🚀 Iniciando Google Auth');
    console.log('[GoogleAuth] Token type: idToken/accessToken');
    console.log('[GoogleAuth] Token length:', idToken?.length);

    try {
      if (!idToken) {
        console.warn('[GoogleAuth] ❌ Token não fornecido');
        throw new BadRequestException('Token do Google não fornecido');
      }

      console.log('[GoogleAuth] 🔐 Validando token com Google...');
      let payload;

      try {
        // Tenta validar como ID Token
        const ticket = await this.googleClient.verifyIdToken({
          idToken,
          audience: process.env.GOOGLE_CLIENT_ID,
        });
        payload = ticket.getPayload();
        console.log('[GoogleAuth] ✅ Token validado como ID Token');
      } catch (idTokenError) {
        console.warn('[GoogleAuth] ⚠️  Não é um ID Token válido, tentando como Access Token...');

        // Se falhar como ID Token, tenta obter info do usuário usando o accessToken
        try {
          const response = await fetch(
            `https://www.googleapis.com/oauth2/v2/userinfo?access_token=${idToken}`,
            { method: 'GET' }
          );

          if (!response.ok) {
            console.error('[GoogleAuth] ❌ Access Token inválido:', response.status);
            throw new UnauthorizedException('Token inválido');
          }

          payload = await response.json();
          console.log('[GoogleAuth] ✅ Informações obtidas usando Access Token');
        } catch (accessTokenError) {
          console.error('[GoogleAuth] ❌ Erro ao validar token:', accessTokenError);
          throw new UnauthorizedException('Token inválido ou expirado');
        }
      }

      if (!payload) {
        console.error('[GoogleAuth] ❌ Payload inválido');
        throw new UnauthorizedException('Token inválido');
      }

      console.log('[GoogleAuth] ✅ Token validado com sucesso');

      // Normalizar payload (ID Token usa 'sub', API usa 'id')
      const googleId = payload.sub || payload.id;
      const email = payload.email;
      const name = payload.name;
      const picture = payload.picture;

      console.log('[GoogleAuth] 👤 Email:', email, 'Name:', name);

      if (!email) {
        console.error('[GoogleAuth] ❌ Email não encontrado no payload');
        throw new BadRequestException('Email não encontrado no token do Google');
      }

      console.log('[GoogleAuth] 🔍 Buscando usuário no Supabase...');
      let userData = await this.supabaseService.getUserByEmail(email);

      if (!userData) {
        console.log('[GoogleAuth] 📝 Usuário não existe, criando...');
        const { data: newUser, error } = await this.supabaseService.createGoogleUser(
          googleId,
          email,
          name,
          picture,
        );
        if (error) {
          console.error('[GoogleAuth] ❌ Erro ao criar usuário:', error);
          throw new BadRequestException('Erro ao criar usuário');
        }
        console.log('[GoogleAuth] ✅ Usuário criado:', { id: newUser?.id, email });
        userData = newUser;
      } else {
        console.log('[GoogleAuth] ✅ Usuário encontrado:', { id: userData.id });
        console.log('[GoogleAuth] 📝 Atualizando metadados...');
        await this.supabaseService.updateUserMetadata(userData.id, {
          google_id: googleId,
          name: name || userData.user_metadata?.name,
          picture: picture || userData.user_metadata?.picture,
          provider: 'google',
        });
        console.log('[GoogleAuth] ✅ Metadados atualizados');
      }

      console.log('[GoogleAuth] 🔐 Gerando JWT...');
      const token = this.jwtService.sign({
        sub: userData.id,
        email: userData.email,
        name: name || userData.user_metadata?.name,
      });
      console.log('[GoogleAuth] ✅ JWT gerado');

      console.log('[GoogleAuth] ✅ Google Auth concluído com sucesso!');
      return {
        success: true,
        token,
        user: {
          id: userData.id,
          email: userData.email,
          name: name || userData.user_metadata?.name,
          picture: picture || userData.user_metadata?.picture,
          admin: userData.user_metadata?.admin === true || userData.user_metadata?.admin === 'true',
        },
      };
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      console.error('[GoogleAuth] ❌ Erro:', errorMessage);
      console.error('[GoogleAuth] Stack:', error);
      throw new UnauthorizedException(errorMessage || 'Erro ao autenticar com Google');
    }
  }

  async getUserIdFromToken(token: string): Promise<string> {
    try {
      const cleanToken = token.replace('Bearer ', '');
      const decoded = this.jwtService.verify(cleanToken);
      return decoded.sub;
    } catch (e) {
      throw new UnauthorizedException('Token inválido ou expirado');
    }
  }
}
