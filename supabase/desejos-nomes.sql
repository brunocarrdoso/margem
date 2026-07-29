-- ════════════════════════════════════════════════════════════
-- margem · desejos por NOME (não por e-mail)
-- Rode UMA vez no Supabase: Dashboard → SQL Editor → New query
-- → cole este arquivo inteiro → Run.
-- Requer wishlist.sql e usernames.sql já rodados.
-- ════════════════════════════════════════════════════════════

-- guarda o nome de quem pediu e de quem é a lista
alter table public.wishlist_shares add column if not exists requester_name text;
alter table public.wishlist_shares add column if not exists owner_name text;

-- nome (username) a partir do e-mail — pra exibir e pra migrar linhas antigas
create or replace function public.username_for_email(mail text)
returns text
language sql
security definer
set search_path = public, auth
as $$
  select n.username
  from auth.users u
  join public.usernames n on n.user_id = u.id
  where lower(u.email) = lower(trim(mail))
  limit 1;
$$;
grant execute on function public.username_for_email(text) to authenticated;

-- preenche os nomes das linhas que já existiam
update public.wishlist_shares s set
  requester_name = coalesce(s.requester_name, public.username_for_email(s.requester_email)),
  owner_name     = coalesce(s.owner_name,     public.username_for_email(s.owner_email))
where s.requester_name is null or s.owner_name is null;
