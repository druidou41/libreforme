-- LibreForme Duo v12 — Boutique, crédits et récompenses
-- Ce script conserve toutes les données existantes.

create table if not exists public.rewards (
  id text primary key,
  name text not null,
  type text not null check (type in ('theme','title','effect','badge')),
  cost integer not null check (cost >= 0),
  value text not null,
  description text not null default '',
  active boolean not null default true
);

create table if not exists public.user_rewards (
  user_id uuid not null references public.profiles(id) on delete cascade,
  reward_id text not null references public.rewards(id) on delete cascade,
  purchased_at timestamptz not null default now(),
  equipped boolean not null default false,
  primary key (user_id,reward_id)
);

insert into public.rewards(id,name,type,cost,value,description) values
 ('theme_violet','Cyber Violet','theme',40,'violet','Interface violette et électrique'),
 ('theme_toxic','Toxic Green','theme',60,'toxic','Interface verte radioactive'),
 ('theme_crimson','Crimson Arena','theme',80,'crimson','Interface rouge compétitive'),
 ('title_walker','Marcheur rapide','title',25,'Marcheur rapide','Titre affiché sur ton profil'),
 ('title_machine','Machine à répétitions','title',45,'Machine à répétitions','Pour les amateurs de séries'),
 ('title_elite','Athlète élite','title',100,'Athlète élite','Titre prestigieux'),
 ('badge_fire','Badge Flamme','badge',30,'🔥','Badge de profil'),
 ('badge_lightning','Badge Éclair','badge',50,'⚡','Badge de profil'),
 ('effect_confetti','Validation Confettis','effect',35,'confetti','Effet après un effort'),
 ('effect_energy','Explosion Énergie','effect',70,'energy','Effet gaming après validation')
on conflict (id) do update set name=excluded.name,type=excluded.type,cost=excluded.cost,value=excluded.value,description=excluded.description,active=true;

alter table public.rewards enable row level security;
alter table public.user_rewards enable row level security;
drop policy if exists "rewards_visible" on public.rewards;
drop policy if exists "own_rewards_visible" on public.user_rewards;
create policy "rewards_visible" on public.rewards for select to authenticated using (active=true);
create policy "own_rewards_visible" on public.user_rewards for select to authenticated using (user_id=auth.uid());
grant select on public.rewards,public.user_rewards to authenticated;

create or replace function public.my_total_xp()
returns integer language sql stable security definer set search_path=public as $$
  select coalesce(sum(
    case when type='walk'
      then round(coalesce((details->>'distance')::numeric,0)*10)
      else round(coalesce((details->>'sets')::numeric,0)*coalesce((details->>'reps')::numeric,0)/2)
    end
  ),0)::integer from public.activities where user_id=auth.uid();
$$;

create or replace function public.my_credit_balance()
returns integer language sql stable security definer set search_path=public as $$
  select greatest(0,floor(public.my_total_xp()/10.0)::integer-coalesce((
    select sum(r.cost) from public.user_rewards ur join public.rewards r on r.id=ur.reward_id where ur.user_id=auth.uid()
  ),0));
$$;

create or replace function public.purchase_reward(selected_reward text)
returns integer language plpgsql security definer set search_path=public as $$
declare price integer;balance integer;
begin
  if auth.uid() is null then raise exception 'Utilisateur non connecté'; end if;
  select cost into price from rewards where id=selected_reward and active=true;
  if price is null then raise exception 'Récompense introuvable'; end if;
  if exists(select 1 from user_rewards where user_id=auth.uid() and reward_id=selected_reward) then raise exception 'Récompense déjà obtenue'; end if;
  balance:=public.my_credit_balance();
  if balance<price then raise exception 'Crédits insuffisants'; end if;
  insert into user_rewards(user_id,reward_id) values(auth.uid(),selected_reward);
  return balance-price;
end$$;

create or replace function public.equip_reward(selected_reward text)
returns void language plpgsql security definer set search_path=public as $$
declare reward_type text;
begin
  select r.type into reward_type from user_rewards ur join rewards r on r.id=ur.reward_id
  where ur.user_id=auth.uid() and ur.reward_id=selected_reward;
  if reward_type is null then raise exception 'Récompense non possédée'; end if;
  update user_rewards ur set equipped=false from rewards r where ur.reward_id=r.id and ur.user_id=auth.uid() and r.type=reward_type;
  update user_rewards set equipped=true where user_id=auth.uid() and reward_id=selected_reward;
end$$;

grant execute on function public.my_total_xp(),public.my_credit_balance(),public.purchase_reward(text),public.equip_reward(text) to authenticated;

