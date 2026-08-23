-- 001_initial_schema.sql
-- Auto em Dia - Schema inicial (Supabase / PostgreSQL)
-- Execute no Supabase SQL Editor na ordem: 001 → 002 → 003.

-- Extensão para uuid (geralmente já habilitada no Supabase).
create extension if not exists "uuid-ossp";

-- Função de updated_at genérica.
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

-- ============================================================
-- 1) users (perfil do usuário, linkado com auth.users)
-- ============================================================
create table if not exists public.users (
  id          uuid primary key references auth.users(id) on delete cascade,
  name        text not null default '',
  email       text not null default '',
  plan        text not null default 'free' check (plan in ('free', 'premium')),
  created_at  timestamptz not null default now()
);

-- ============================================================
-- 2) vehicles
-- ============================================================
create table if not exists public.vehicles (
  id              uuid primary key default uuid_generate_v4(),
  user_id         uuid not null references public.users(id) on delete cascade,
  brand           text not null,
  model           text not null,
  year            integer not null check (year >= 1900 and year <= (extract(year from now()) + 1)::int),
  fuel            text not null,
  plate           text,
  current_mileage integer not null default 0 check (current_mileage >= 0),
  photo_url       text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

drop trigger if exists trg_vehicles_updated_at on public.vehicles;
create trigger trg_vehicles_updated_at
  before update on public.vehicles
  for each row execute function public.set_updated_at();

-- ============================================================
-- 3) maintenance_records
-- ============================================================
create table if not exists public.maintenance_records (
  id            uuid primary key default uuid_generate_v4(),
  vehicle_id    uuid not null references public.vehicles(id) on delete cascade,
  category      text not null,
  description   text not null,
  service_date  date not null,
  mileage       integer check (mileage is null or mileage >= 0),
  cost          numeric(10,2) check (cost is null or cost >= 0),
  notes         text,
  next_mileage  integer check (next_mileage is null or next_mileage >= 0),
  next_date     date,
  created_at    timestamptz not null default now()
);

-- ============================================================
-- 4) reminders
-- ============================================================
create table if not exists public.reminders (
  id                   uuid primary key default uuid_generate_v4(),
  vehicle_id           uuid not null references public.vehicles(id) on delete cascade,
  title                text not null,
  category             text,
  due_date             date,
  due_mileage          integer check (due_mileage is null or due_mileage >= 0),
  completed            boolean not null default false,
  notification_enabled boolean not null default true,
  created_at           timestamptz not null default now(),
  -- Pelo menos um critério de vencimento (data ou km) deve existir.
  constraint reminders_due_present check (due_date is not null or due_mileage is not null)
);

-- ============================================================
-- 5) expenses
-- ============================================================
create table if not exists public.expenses (
  id          uuid primary key default uuid_generate_v4(),
  vehicle_id  uuid not null references public.vehicles(id) on delete cascade,
  category    text not null,
  description text not null,
  amount      numeric(10,2) not null check (amount >= 0),
  expense_date date not null,
  created_at  timestamptz not null default now()
);

-- ============================================================
-- 6) subscriptions
-- ============================================================
create table if not exists public.subscriptions (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references public.users(id) on delete cascade,
  product_id  text not null,
  status      text not null default 'pending'
              check (status in ('pending', 'active', 'expired', 'cancelled')),
  started_at  timestamptz not null default now(),
  expires_at  timestamptz,
  created_at  timestamptz not null default now()
);

-- ============================================================
-- Função admin para exclusão de conta (service role / RPC).
-- O app chama `select delete_current_user()` e o usuário é removido
-- do auth.users + dados em cascata.
-- ============================================================
create or replace function public.delete_current_user()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_current_user() from public, anon;
grant execute on function public.delete_current_user() to authenticated;

-- Comentário: função definida como SECURITY DEFINER para ter permissão de
-- deletar em auth.users. Graças às políticas de CASCADE, todos os dados do
-- usuário são removidos automaticamente.
