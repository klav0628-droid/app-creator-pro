-- APK Link Generator: Supabase Storage + RLS
-- Run this entire file in Supabase SQL Editor.

begin;

-- Public APK bucket: 500 MiB maximum, APK MIME type only.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('apks','apks',true,524288000,array['application/vnd.android.package-archive']::text[])
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

-- Optional metadata table for future admin/statistics features.
create table if not exists public.apk_files (
  id uuid primary key default gen_random_uuid(),
  object_path text not null unique,
  original_name text not null,
  mime_type text not null default 'application/vnd.android.package-archive',
  size_bytes bigint,
  created_at timestamptz not null default now()
);

alter table public.apk_files enable row level security;

-- Keep metadata private. Service-role/admin code can manage it.
drop policy if exists "apk_files_public_read" on public.apk_files;
drop policy if exists "apk_files_public_insert" on public.apk_files;

-- Storage RLS. Anonymous upload is intentional because the current frontend
-- has no login. No anonymous update/delete policy is created.
drop policy if exists "APK anonymous insert" on storage.objects;
drop policy if exists "APK authenticated insert" on storage.objects;
drop policy if exists "APK public read" on storage.objects;
drop policy if exists "APK authenticated update" on storage.objects;
drop policy if exists "APK authenticated delete" on storage.objects;

create policy "APK anonymous insert"
on storage.objects for insert to anon
with check (
  bucket_id = 'apks'
  and lower(storage.extension(name)) = 'apk'
  and (metadata->>'mimetype') = 'application/vnd.android.package-archive'
);

create policy "APK authenticated insert"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'apks'
  and lower(storage.extension(name)) = 'apk'
  and (metadata->>'mimetype') = 'application/vnd.android.package-archive'
);

-- Anyone can download files from this intentionally public APK bucket.
create policy "APK public read"
on storage.objects for select to public
using (bucket_id = 'apks');

-- Authenticated users may manage only objects they own.
create policy "APK authenticated update"
on storage.objects for update to authenticated
using (bucket_id = 'apks' and owner_id = (select auth.uid()::text))
with check (bucket_id = 'apks' and owner_id = (select auth.uid()::text));

create policy "APK authenticated delete"
on storage.objects for delete to authenticated
using (bucket_id = 'apks' and owner_id = (select auth.uid()::text));

commit;

-- SECURITY NOTE:
-- Anonymous uploads can be abused and consume Storage quota. Before broad public
-- launch, add authentication and/or CAPTCHA/rate limiting. Never put a
-- service_role/secret key in frontend code or GitHub.
