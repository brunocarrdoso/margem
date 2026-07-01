-- ════════════════════════════════════════════════════════════
-- margem · carrinho de desejos + compartilhamento
-- Rode UMA vez no Supabase: Dashboard → SQL Editor → New query
-- → cole este arquivo inteiro → Run.
-- Sem isso o carrinho funciona só localmente (sem sync/compartilhar).
-- ════════════════════════════════════════════════════════════

create table if not exists public.wishlists (
  user_id uuid primary key references auth.users(id) on delete cascade,
  items jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.wishlists enable row level security;

create table if not exists public.wishlist_shares (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references auth.users(id) on delete cascade,
  requester_email text not null,
  owner_email text not null,
  owner_id uuid references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted','refused')),
  created_at timestamptz not null default now()
);
alter table public.wishlist_shares enable row level security;
create unique index if not exists wishlist_shares_uniq
  on public.wishlist_shares (requester_id, lower(owner_email));

-- wishlists: o dono faz tudo
create policy "wishlist own" on public.wishlists
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- wishlists: quem teve pedido aceito pode LER a lista do dono
create policy "wishlist shared read" on public.wishlists
  for select using (exists (
    select 1 from public.wishlist_shares s
    where s.owner_id = wishlists.user_id
      and s.requester_id = auth.uid()
      and s.status = 'accepted'
  ));

-- shares: quem pediu vê / cria / remove os próprios pedidos
create policy "share requester select" on public.wishlist_shares
  for select using (requester_id = auth.uid());
create policy "share requester insert" on public.wishlist_shares
  for insert with check (requester_id = auth.uid() and status = 'pending' and owner_id is null);
create policy "share requester delete" on public.wishlist_shares
  for delete using (requester_id = auth.uid());

-- shares: o dono (identificado pelo e-mail) vê e responde
create policy "share owner select" on public.wishlist_shares
  for select using (lower(owner_email) = lower(auth.jwt()->>'email'));
create policy "share owner respond" on public.wishlist_shares
  for update using (lower(owner_email) = lower(auth.jwt()->>'email'))
  with check (owner_id = auth.uid());
