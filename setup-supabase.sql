create extension if not exists pgcrypto;
create table public.profiles(id uuid primary key references auth.users(id) on delete cascade,display_name text not null,created_at timestamptz default now());
create table public.groups(id uuid primary key default gen_random_uuid(),name text not null,invite_code text unique not null,owner_id uuid references public.profiles(id),created_at timestamptz default now());
create table public.group_members(group_id uuid references public.groups(id) on delete cascade,user_id uuid references public.profiles(id) on delete cascade,joined_at timestamptz default now(),primary key(group_id,user_id));
create table public.activities(id uuid primary key default gen_random_uuid(),group_id uuid references public.groups(id) on delete cascade,user_id uuid references public.profiles(id) on delete cascade,type text check(type in('walk','pushup','abs','dumbbell_left','dumbbell_right','other')),details jsonb default '{}',note text,performed_at date default current_date,created_at timestamptz default now());
create function public.new_profile() returns trigger language plpgsql security definer set search_path=public as $$begin insert into profiles(id,display_name) values(new.id,coalesce(new.raw_user_meta_data->>'display_name',split_part(new.email,'@',1)));return new;end$$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.new_profile();
create function public.create_group(group_name text) returns uuid language plpgsql security definer set search_path=public as $$declare g uuid;c text;begin c:=upper(substr(encode(gen_random_bytes(6),'hex'),1,6));insert into groups(name,invite_code,owner_id) values(group_name,c,auth.uid()) returning id into g;insert into group_members values(g,auth.uid(),now());return g;end$$;
create function public.join_group(join_code text) returns uuid language plpgsql security definer set search_path=public as $$declare g uuid;begin select id into g from groups where invite_code=upper(join_code);if g is null then raise exception 'Code introuvable';end if;insert into group_members values(g,auth.uid(),now());return g;end$$;
alter table profiles enable row level security;alter table groups enable row level security;alter table group_members enable row level security;alter table activities enable row level security;
create policy "profiles team" on profiles for select using(id=auth.uid() or exists(select 1 from group_members a join group_members b on a.group_id=b.group_id where a.user_id=auth.uid() and b.user_id=profiles.id));
create policy "groups members" on groups for select using(exists(select 1 from group_members where group_id=groups.id and user_id=auth.uid()));
create policy "members team" on group_members for select using(exists(select 1 from group_members m where m.group_id=group_members.group_id and m.user_id=auth.uid()));
create policy "activities team read" on activities for select using(exists(select 1 from group_members where group_id=activities.group_id and user_id=auth.uid()));
create policy "activities own insert" on activities for insert with check(user_id=auth.uid() and exists(select 1 from group_members where group_id=activities.group_id and user_id=auth.uid()));
create policy "activities own update" on activities for update using(user_id=auth.uid());create policy "activities own delete" on activities for delete using(user_id=auth.uid());
grant execute on function create_group(text),join_group(text) to authenticated;

