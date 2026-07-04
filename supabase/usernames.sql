-- ════════════════════════════════════════════════════════════
-- margem · login por usuário + senha
-- Rode UMA vez no Supabase: Dashboard → SQL Editor → New query
-- → cole este arquivo inteiro → Run.
-- Sem isso o login por usuário não resolve (o atalho por e-mail continua).
-- ════════════════════════════════════════════════════════════

create table if not exists public.usernames (
  user_id    uuid primary key references auth.users(id) on delete cascade,
  username   text unique not null,
  updated_at timestamptz not null default now()
);
alter table public.usernames enable row level security;

-- o dono lê e escreve só o próprio usuário
create policy "own username" on public.usernames
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- login: resolve usuário → e-mail (roda antes de autenticar, precisa ser anon)
create or replace function public.email_for_username(uname text)
returns text
language sql security definer set search_path = public, auth as $$
  select u.email
  from auth.users u
  join public.usernames n on n.user_id = u.id
  where lower(n.username) = lower(trim(uname))
  limit 1;
$$;
grant execute on function public.email_for_username(text) to anon, authenticated;

-- cadastro/migração: o usuário está livre?
create or replace function public.username_available(uname text)
returns boolean
language sql security definer set search_path = public as $$
  select not exists (
    select 1 from public.usernames where lower(username) = lower(trim(uname))
  );
$$;
grant execute on function public.username_available(text) to anon, authenticated;
