-- 002_rls_policies.sql
-- Auto em Dia - Row Level Security e políticas de acesso.
-- Regra: um usuário só enxerga/modifica seus próprios dados.

-- ============================================================
-- Habilitar RLS em todas as tabelas de negócio.
-- ============================================================
alter table public.users              enable row level security;
alter table public.vehicles           enable row level security;
alter table public.maintenance_records enable row level security;
alter table public.reminders          enable row level security;
alter table public.expenses           enable row level security;
alter table public.subscriptions      enable row level security;

-- ============================================================
-- users: somente o próprio usuário vê/edita o próprio perfil.
-- ============================================================
drop policy if exists users_select_own on public.users;
create policy users_select_own on public.users
  for select using (auth.uid() = id);

drop policy if exists users_insert_own on public.users;
create policy users_insert_own on public.users
  for insert with check (auth.uid() = id);

drop policy if exists users_update_own on public.users;
create policy users_update_own on public.users
  for update using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists users_delete_own on public.users;
create policy users_delete_own on public.users
  for delete using (auth.uid() = id);

-- ============================================================
-- vehicles: somente o dono (user_id = auth.uid()).
-- ============================================================
drop policy if exists vehicles_select_own on public.vehicles;
create policy vehicles_select_own on public.vehicles
  for select using (auth.uid() = user_id);

drop policy if exists vehicles_insert_own on public.vehicles;
create policy vehicles_insert_own on public.vehicles
  for insert with check (auth.uid() = user_id);

drop policy if exists vehicles_update_own on public.vehicles;
create policy vehicles_update_own on public.vehicles
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists vehicles_delete_own on public.vehicles;
create policy vehicles_delete_own on public.vehicles
  for delete using (auth.uid() = user_id);

-- ============================================================
-- Função auxiliar: verifica se o usuário é dono do veículo.
-- ============================================================
create or replace function public.owns_vehicle(p_vehicle_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.vehicles
    where id = p_vehicle_id and user_id = auth.uid()
  );
$$;

revoke all on function public.owns_vehicle(uuid) from public, anon;
grant execute on function public.owns_vehicle(uuid) to authenticated;

-- ============================================================
-- maintenance_records: o usuário só acessa registros de veículos seus.
-- ============================================================
drop policy if exists mr_select_own on public.maintenance_records;
create policy mr_select_own on public.maintenance_records
  for select using (public.owns_vehicle(vehicle_id));

drop policy if exists mr_insert_own on public.maintenance_records;
create policy mr_insert_own on public.maintenance_records
  for insert with check (public.owns_vehicle(vehicle_id));

drop policy if exists mr_update_own on public.maintenance_records;
create policy mr_update_own on public.maintenance_records
  for update using (public.owns_vehicle(vehicle_id))
  with check (public.owns_vehicle(vehicle_id));

drop policy if exists mr_delete_own on public.maintenance_records;
create policy mr_delete_own on public.maintenance_records
  for delete using (public.owns_vehicle(vehicle_id));

-- ============================================================
-- reminders: mesma regra de ownership por veículo.
-- ============================================================
drop policy if exists rem_select_own on public.reminders;
create policy rem_select_own on public.reminders
  for select using (public.owns_vehicle(vehicle_id));

drop policy if exists rem_insert_own on public.reminders;
create policy rem_insert_own on public.reminders
  for insert with check (public.owns_vehicle(vehicle_id));

drop policy if exists rem_update_own on public.reminders;
create policy rem_update_own on public.reminders
  for update using (public.owns_vehicle(vehicle_id))
  with check (public.owns_vehicle(vehicle_id));

drop policy if exists rem_delete_own on public.reminders;
create policy rem_delete_own on public.reminders
  for delete using (public.owns_vehicle(vehicle_id));

-- ============================================================
-- expenses: mesma regra de ownership por veículo.
-- ============================================================
drop policy if exists exp_select_own on public.expenses;
create policy exp_select_own on public.expenses
  for select using (public.owns_vehicle(vehicle_id));

drop policy if exists exp_insert_own on public.expenses;
create policy exp_insert_own on public.expenses
  for insert with check (public.owns_vehicle(vehicle_id));

drop policy if exists exp_update_own on public.expenses;
create policy exp_update_own on public.expenses
  for update using (public.owns_vehicle(vehicle_id))
  with check (public.owns_vehicle(vehicle_id));

drop policy if exists exp_delete_own on public.expenses;
create policy exp_delete_own on public.expenses
  for delete using (public.owns_vehicle(vehicle_id));

-- ============================================================
-- subscriptions: somente o próprio usuário vê sua assinatura.
-- ============================================================
drop policy if exists sub_select_own on public.subscriptions;
create policy sub_select_own on public.subscriptions
  for select using (auth.uid() = user_id);

drop policy if exists sub_insert_own on public.subscriptions;
create policy sub_insert_own on public.subscriptions
  for insert with check (auth.uid() = user_id);

drop policy if exists sub_update_own on public.subscriptions;
create policy sub_update_own on public.subscriptions
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists sub_delete_own on public.subscriptions;
create policy sub_delete_own on public.subscriptions
  for delete using (auth.uid() = user_id);

-- ============================================================
-- Storage: bucket público para fotos de veículos.
-- O nome segue o app: 'vehicle-photos'. Políticas de acesso abaixo
-- garantem que cada usuário só gerencia arquivos na sua pasta.
-- ============================================================
insert into storage.buckets (id, name, public)
values ('vehicle-photos', 'vehicle-photos', true)
on conflict (id) do nothing;

drop policy if exists vehicle_photos_select on storage.objects;
create policy vehicle_photos_select on storage.objects
  for select using (
    bucket_id = 'vehicle-photos'
  );

drop policy if exists vehicle_photos_insert_own on storage.objects;
create policy vehicle_photos_insert_own on storage.objects
  for insert with check (
    bucket_id = 'vehicle-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists vehicle_photos_update_own on storage.objects;
create policy vehicle_photos_update_own on storage.objects
  for update using (
    bucket_id = 'vehicle-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists vehicle_photos_delete_own on storage.objects;
create policy vehicle_photos_delete_own on storage.objects
  for delete using (
    bucket_id = 'vehicle-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
