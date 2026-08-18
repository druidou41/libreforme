-- LibreForme Duo — correction sécurisée de la suppression
create or replace function public.delete_my_activity(activity_id uuid)
returns boolean
language plpgsql
security definer
set search_path=public
as $$
declare deleted_count integer;
begin
  if auth.uid() is null then
    raise exception 'Utilisateur non connecté';
  end if;

  delete from public.activities
  where id=activity_id
    and user_id=auth.uid();

  get diagnostics deleted_count = row_count;
  return deleted_count > 0;
end;
$$;

grant execute on function public.delete_my_activity(uuid) to authenticated;

-- Force l’API Supabase à détecter immédiatement la nouvelle fonction.
notify pgrst, 'reload schema';

