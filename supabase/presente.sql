-- ════════════════════════════════════════════════════════════
-- margem · presentear: comprar um desejo de outra pessoa
-- e removê-lo da lista dela.
-- Rode UMA vez no Supabase: Dashboard → SQL Editor → New query
-- → cole este arquivo inteiro → Run.
-- Requer o wishlist.sql já rodado (tabelas wishlists/wishlist_shares).
-- ════════════════════════════════════════════════════════════

create or replace function public.gift_wish_item(p_owner uuid, p_item text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item jsonb;
begin
  -- só quem tem pedido ACEITO pra ver a lista do dono pode presentear
  if not exists (
    select 1 from public.wishlist_shares s
    where s.owner_id = p_owner
      and s.requester_id = auth.uid()
      and s.status = 'accepted'
  ) then
    raise exception 'sem acesso';
  end if;

  select it into v_item
  from public.wishlists w, jsonb_array_elements(w.items) it
  where w.user_id = p_owner and it->>'id' = p_item;

  if v_item is null then
    raise exception 'desejo não encontrado';
  end if;

  update public.wishlists set
    items = (
      select coalesce(jsonb_agg(it), '[]'::jsonb)
      from jsonb_array_elements(items) it
      where it->>'id' <> p_item
    ),
    updated_at = now()
  where user_id = p_owner;

  return v_item;
end;
$$;

revoke all on function public.gift_wish_item(uuid, text) from public;
grant execute on function public.gift_wish_item(uuid, text) to authenticated;
