-- ============================================================
--  A3N IPTV - "online" column on the devices table
--  The apps check in every 10 minutes. A device is online when it
--  checked in during the last 12 minutes (10 + a little margin).
--  Paste in Supabase > SQL Editor > Run. Safe to run again.
-- ============================================================

-- The old view is no longer used.
drop view if exists public.devices_overview;

-- true = the app is open on this device right now.
alter table public.devices add column if not exists online boolean not null default false;

-- Every check-in (and any edit of the row) works the value out again.
create or replace function public.devices_set_online()
returns trigger
language plpgsql
as $$
begin
  new.online := new.last_seen > now() - interval '12 minutes';
  return new;
end;
$$;

drop trigger if exists devices_online on public.devices;
create trigger devices_online
  before insert or update on public.devices
  for each row execute function public.devices_set_online();

-- Once a minute, devices that stopped checking in go offline.
create extension if not exists pg_cron with schema pg_catalog;

select cron.unschedule(jobid) from cron.job where jobname = 'devices-online';
select cron.schedule(
  'devices-online',
  '* * * * *',
  $job$update public.devices set online = false where online and last_seen <= now() - interval '12 minutes'$job$
);

-- Set it right away for every device.
update public.devices set online = (last_seen > now() - interval '12 minutes');
