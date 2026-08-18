-- LibreForme Duo : permettre à un membre de quitter son groupe en sécurité.
-- Ce script ne supprime ni le groupe ni les performances déjà enregistrées.

create or replace function public.leave_my_group()
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  removed_count integer;
begin
  delete from public.group_members
  where user_id = auth.uid();

  get diagnostics removed_count = row_count;
  return removed_count > 0;
end;
$$;

revoke all on function public.leave_my_group() from public;
grant execute on function public.leave_my_group() to authenticated;

notify pgrst, 'reload schema';

