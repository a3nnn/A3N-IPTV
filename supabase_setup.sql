-- ============================================================
--  A3N IPTV Player - usage tracking & remote block
--  Paste ALL of this in Supabase > SQL Editor > Run
--  Safe to run again any time: it only adds what is missing.
-- ============================================================

-- One row per device that opened the app.
create table if not exists public.devices (
  device_id    text primary key,
  username     text not null default '',
  device_name  text,
  os           text,
  app_version  text,
  ip           text,      -- taken from the connection itself
  country      text,      -- approximate, from the IP
  city         text,      -- approximate, from the IP
  isp          text,      -- internet provider, from the IP
  first_seen   timestamptz not null default now(),
  last_seen    timestamptz not null default now(),
  open_count   integer not null default 1,
  block_device boolean not null default false,  -- tick = block THIS device only
  block_user   boolean not null default false,  -- tick = block this USERNAME on every device
  message      text                             -- optional message shown to the blocked user
);

-- Windows / Android TV, worked out from the "os" the app sends.
-- (Added separately so it also gets added to an existing table.)
alter table public.devices
  add column if not exists platform text
  generated always as (
    case
      when os ilike 'android%' then 'Android TV'
      when os ilike 'windows%' then 'Windows'
      else 'Other'
    end
  ) stored;

-- Nobody can read or edit the table through the public API.
-- Only you (from the Supabase dashboard) can see it.
alter table public.devices enable row level security;
revoke all on table public.devices from anon, authenticated;

-- The only thing the app is allowed to do: report itself and ask "am I blocked?"
create or replace function public.checkin(
  p_device_id   text,
  p_username    text,
  p_device_name text,
  p_os          text,
  p_app_version text,
  p_opened      boolean default false,
  p_country     text default null,
  p_city        text default null,
  p_isp         text default null
) returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  r       public.devices;
  blocked boolean;
  msg     text;
  hdrs    json;
  v_ip    text;
begin
  begin
    hdrs := current_setting('request.headers', true)::json;
  exception when others then
    hdrs := null;
  end;
  v_ip := coalesce(
    nullif(trim(split_part(hdrs ->> 'x-forwarded-for', ',', 1)), ''),
    hdrs ->> 'cf-connecting-ip',
    hdrs ->> 'x-real-ip'
  );

  if p_device_id is null or length(p_device_id) < 16 or length(p_device_id) > 64 then
    return json_build_object('blocked', false);
  end if;

  insert into public.devices (device_id, username, device_name, os, app_version, ip, country, city, isp)
  values (p_device_id,
          left(coalesce(p_username, ''), 100),
          left(p_device_name, 100),
          left(p_os, 200),
          left(p_app_version, 20),
          left(v_ip, 64),
          left(p_country, 80),
          left(p_city, 80),
          left(p_isp, 120))
  on conflict (device_id) do update set
    username    = case when excluded.username <> '' then excluded.username else devices.username end,
    device_name = excluded.device_name,
    os          = excluded.os,
    app_version = excluded.app_version,
    ip          = coalesce(excluded.ip, devices.ip),
    country     = coalesce(excluded.country, devices.country),
    city        = coalesce(excluded.city, devices.city),
    isp         = coalesce(excluded.isp, devices.isp),
    last_seen   = now(),
    open_count  = devices.open_count + case when p_opened then 1 else 0 end
  returning * into r;

  blocked := r.block_device or (
    r.username <> '' and exists (
      select 1 from public.devices d where d.username = r.username and d.block_user
    )
  );

  if blocked then
    msg := coalesce(
      r.message,
      (select d.message from public.devices d
        where d.username = r.username and d.block_user and d.message is not null
        limit 1)
    );
  end if;

  return json_build_object('blocked', blocked, 'message', msg);
end;
$$;

revoke all on function public.checkin(text, text, text, text, text, boolean, text, text, text) from public;
grant execute on function public.checkin(text, text, text, text, text, boolean, text, text, text) to anon;

-- Handy view for you: newest first, with an "online now" column.
drop view if exists public.devices_overview;
create view public.devices_overview as
  select username, platform, device_name,
         (last_seen > now() - interval '20 minutes') as online_now,
         ip, country, city, isp,
         last_seen, first_seen, open_count, app_version,
         block_device, block_user, message, os, device_id
  from public.devices
  order by last_seen desc;

revoke all on public.devices_overview from anon, authenticated;
