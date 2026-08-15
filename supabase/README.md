# Supabase setup

1. Open your Supabase project.
2. Open **SQL Editor**.
3. Open `supabase/schema.sql` from this repository and run the complete SQL.
4. Confirm Storage has a public bucket named `apks`.
5. In the frontend, replace `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY` with the project's public URL and anon/publishable key.
6. Never use or expose the `service_role`/secret key in the browser.

## Result

`index.html` uploads `.apk` files to `apks` and generates a public direct-download URL with `getPublicUrl()`.

## Important

The current frontend permits anonymous uploads. This is convenient for a public uploader but can consume Storage quota if abused. For a production public service, add authentication and/or CAPTCHA/rate limiting.
