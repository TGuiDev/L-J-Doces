import { Injectable } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class SupabaseService {
  private supabase: SupabaseClient;
  private supabaseUrl: string;
  private supabaseAnonKey: string;

  constructor(private configService: ConfigService) {
    const supabaseUrl = this.configService.get<string>('SUPABASE_URL');
    const supabaseKey = this.configService.get<string>('SUPABASE_SERVICE_ROLE_KEY');
    const supabaseAnonKey = this.configService.get<string>('SUPABASE_ANON_KEY');

    this.supabaseUrl = supabaseUrl;
    this.supabaseAnonKey = supabaseAnonKey || supabaseKey;

    this.supabase = createClient(supabaseUrl, supabaseKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });
  }

  getClient(): SupabaseClient {
    return this.supabase;
  }

  private getAuthClient(): SupabaseClient {
    // Cliente isolado para auth; evita sobrescrever sessão no cliente admin compartilhado.
    return createClient(this.supabaseUrl, this.supabaseAnonKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });
  }

  async signUpWithEmail(email: string, password: string) {
    const { data, error } = await this.supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
    });
    const dataAny = data as any;
    const finalUser = data?.user || (dataAny?.id ? dataAny : null);
    return { data: { user: finalUser } as any, error };
  }

  async confirmUserEmail(userId: string) {
    return await this.supabase.auth.admin.updateUserById(userId, {
      email_confirm: true,
    });
  }

  async signInWithEmail(email: string, password: string) {
    const authClient = this.getAuthClient();
    return await authClient.auth.signInWithPassword({
      email,
      password,
    });
  }

  async getUserById(userId: string) {
    return await this.supabase.auth.admin.getUserById(userId);
  }

  async updateUserMetadata(userId: string, metadata: any, password?: string) {
    const updateData: any = { user_metadata: metadata };
    if (password) {
      updateData.password = password;
    }
    return await this.supabase.auth.admin.updateUserById(userId, updateData);
  }

  async deleteUser(userId: string) {
    return await this.supabase.auth.admin.deleteUser(userId);
  }

  async sendConfirmationEmail(userId: string) {
    return { success: true };
  }

  async exchangeCodeForSession(code: string) {
    const authClient = this.getAuthClient();
    return await authClient.auth.exchangeCodeForSession(code);
  }

  async signInWithIdToken(idToken: string) {
    const authClient = this.getAuthClient();
    // Valida o ID token do Google diretamente com Supabase
    const { data, error } = await authClient.auth.signInWithIdToken({
      provider: 'google',
      token: idToken,
    });
    return { data, error };
  }

  async getUserByIdToken(idToken: string) {
    const authClient = this.getAuthClient();
    // Tenta fazer login com ID token
    const { data, error } = await authClient.auth.signInWithIdToken({
      provider: 'google',
      token: idToken,
    });
    return { data, error };
  }

  async getUserByEmail(email: string) {
    // Busca usuário pelo email
    try {
      const { data, error } = await this.supabase.auth.admin.listUsers();
      if (error || !data) return null;
      return data.users.find(u => u.email === email);
    } catch (err) {
      return null;
    }
  }

  async createGoogleUser(
    googleId: string,
    email: string,
    name: string,
    picture: string,
  ) {
    // Criar novo usuário com dados do Google
    try {
      const { data, error } = await this.supabase.auth.admin.createUser({
        email,
        email_confirm: true,
        user_metadata: {
          google_id: googleId,
          name,
          picture,
          provider: 'google',
        },
      });
      console.log('>>> NO CREATE USER, RETURNOU =>', JSON.stringify({ data, error }, null, 2));
      // Garante que se 'data' for o próprio usuário (em versões dif do supabase), nós pegamos data.id ou data.user
      const dataAny = data as any;
      const finalUser = data?.user || (dataAny?.id ? dataAny : null);
      if (!finalUser && !error) {
        console.error('>>> USUARIO NAO VEIO NO DATA', data);
      }
      return { data: finalUser, error };
    } catch (err) {
      return { data: null, error: err };
    }
  }
}
