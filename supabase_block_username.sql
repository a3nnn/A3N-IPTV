-- ============================================================
--  A3N IPTV - block a username on ONE device only
--  In the devices table, type usernames in "blocked_usernames"
--  (comma separated, e.g.  ahmad1, ahmad2). That device can't sign
--  in with them; other usernames work. The "message" column is
--  shown to the person. (block_user was removed from the table.)
--  Paste in Supabase > SQL Editor > Run.
-- ============================================================

alter table public.devices add column if not exists blocked_usernames text;

CREATE OR REPLACE FUNCTION public.checkin(p_device_id text, p_username text, p_device_name text, p_os text, p_app_version text, p_opened boolean DEFAULT false, p_country text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_isp text DEFAULT NULL::text) RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $function$
declare r public.devices;
  blocked boolean;
  msg text;
  hdrs json;
  v_ip text;
  begin begin hdrs := current_setting('request.headers', true)::json;
  exception when others then hdrs := null;
  end;
  v_ip := coalesce( nullif(trim(split_part(hdrs ->> 'x-forwarded-for', ',', 1)), ''), hdrs ->> 'cf-connecting-ip', hdrs ->> 'x-real-ip' );
  if p_device_id is null or length(p_device_id) < 16 or length(p_device_id) > 64 then return json_build_object('blocked', false);
  end if;
  insert into public.devices (device_id, username, device_name, os, app_version, ip, country, city, isp) values (p_device_id, left(coalesce(p_username, ''), 100), left(p_device_name, 100), left(p_os, 200), left(p_app_version, 20), left(v_ip, 64), left(p_country, 80), left(p_city, 80), left(p_isp, 120)) on conflict (device_id) do update set username = case when excluded.username <> '' then excluded.username else devices.username end, device_name = excluded.device_name, os = excluded.os, app_version = excluded.app_version, ip = coalesce(excluded.ip, devices.ip), country = coalesce(excluded.country, devices.country), city = coalesce(excluded.city, devices.city), isp = coalesce(excluded.isp, devices.isp), last_seen = now(), open_count = devices.open_count + case when p_opened then 1 else 0 end returning * into r;
  blocked := r.block_device or ( r.username <> '' and exists ( select 1 from unnest(string_to_array(coalesce(r.blocked_usernames, ''), ',')) as b(u) where lower(trim(b.u)) = lower(r.username) ) );
  if blocked then msg := r.message;
  end if;
  return json_build_object('blocked', blocked, 'message', msg);
  end;
  $function$;
