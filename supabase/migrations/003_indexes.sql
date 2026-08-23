-- 003_indexes.sql
-- Auto em Dia - Índices de performance.

-- Chaves estrangeiras e filtros frequentes:
create index if not exists idx_vehicles_user_id        on public.vehicles(user_id);

create index if not exists idx_mr_vehicle_id           on public.maintenance_records(vehicle_id);
create index if not exists idx_mr_service_date         on public.maintenance_records(service_date desc);
create index if not exists idx_mr_next_due             on public.maintenance_records(next_date, next_mileage);

create index if not exists idx_reminders_vehicle_id    on public.reminders(vehicle_id);
create index if not exists idx_reminders_due_date      on public.reminders(due_date);
create index if not exists idx_reminders_due_mileage   on public.reminders(due_mileage);
create index if not exists idx_reminders_completed     on public.reminders(completed);

create index if not exists idx_expenses_vehicle_id     on public.expenses(vehicle_id);
create index if not exists idx_expenses_date           on public.expenses(expense_date desc);
create index if not exists idx_expenses_category       on public.expenses(category);

create index if not exists idx_subscriptions_user_id   on public.subscriptions(user_id);
create index if not exists idx_subscriptions_status    on public.subscriptions(status);
