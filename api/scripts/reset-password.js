// scripts/reset-password.js
import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!url || !key) {
  console.error('Erro: SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY não definidos no .env');
  process.exit(1);
}

const supabase = createClient(url, key);

async function run() {
  try {
    const userEmail = 'teste@gmail.com';
    const newPassword = 'Teste123';

    const resp = await supabase.auth.admin.listUsers();

    // Compatibilidade com diferentes formatos de retorno
    // v2: resp.data.users -> array, outras versões podem retornar resp.users
    const users = resp?.data?.users ?? resp?.users ?? [];

    if (!Array.isArray(users)) {
      console.warn('Formato inesperado retornado por listUsers:', Object.keys(resp || {}));
    }

    const user = Array.isArray(users) ? users.find(u => u.email === userEmail) : undefined;
    if (!user) {
      console.log('Usuário não encontrado. Verifique email e se o usuário existe no Supabase.');
      return;
    }

    const { data, error } = await supabase.auth.admin.updateUserById(user.id, { password: newPassword });
    if (error) {
      console.error('Erro ao atualizar senha:', error);
      return;
    }
    console.log('Senha atualizada com sucesso para userId', user.id);

    // Tentar autenticar com a nova senha usando a chave anônima (se disponível)
    const anonKey = process.env.SUPABASE_ANON_KEY;
    if (!anonKey) {
      console.warn('SUPABASE_ANON_KEY não definido; pulando tentativa de login de verificação.');
      return;
    }

    try {
      const userClient = createClient(url, anonKey);
      const signin = await userClient.auth.signInWithPassword({ email: userEmail, password: newPassword });
      if (signin.error) {
        console.error('Falha no login de verificação:', signin.error);
      } else {
        console.log('Login de verificação bem-sucedido. Session presente?', !!signin.data?.session);
      }
    } catch (err) {
      console.error('Erro ao tentar login de verificação:', err);
    }
  } catch (err) {
    console.error('Erro no script reset-password:', err);
  }
}

run();