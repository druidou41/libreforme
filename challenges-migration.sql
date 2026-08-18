-- LibreForme Duo v14 — niveaux, défis et palmarès
-- Conserve les comptes, groupes, activités et anciennes données.
create table if not exists public.challenges (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups(id) on delete cascade,
  created_by uuid not null references public.profiles(id) on delete cascade,
  name text not null check(char_length(name) between 2 and 60),
  mode text not null check(mode in('coop','duel')),
  metric text not null check(metric in('reps','distance','xp')),
  target numeric not null check(target>0),
  reward_text text check(char_length(reward_text)<=100),
  starts_at date not null default current_date,
  ends_at date not null,
  created_at timestamptz not null default now(),
  check(ends_at>=starts_at)
);
alter table public.challenges enable row level security;
drop policy if exists "team_challenges_read" on public.challenges;
drop policy if exists "team_challenges_create" on public.challenges;
drop policy if exists "creator_challenges_update" on public.challenges;
drop policy if exists "creator_challenges_delete" on public.challenges;
create policy "team_challenges_read" on public.challenges for select to authenticated using(public.is_group_member(group_id));
create policy "team_challenges_create" on public.challenges for insert to authenticated with check(created_by=auth.uid() and public.is_group_member(group_id));
create policy "creator_challenges_update" on public.challenges for update to authenticated using(created_by=auth.uid()) with check(created_by=auth.uid() and public.is_group_member(group_id));
create policy "creator_challenges_delete" on public.challenges for delete to authenticated using(created_by=auth.uid());
grant select,insert,update,delete on public.challenges to authenticated;

