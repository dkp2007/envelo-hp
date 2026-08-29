-- Add bill_url column to transactions for uploaded receipts/invoices
alter table public.transactions
  add column if not exists bill_url text;

-- Create storage bucket for bill uploads
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'bills',
  'bills',
  false,
  10485760, -- 10 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
) on conflict (id) do nothing;

-- RLS: users can only access their own bill files
-- Files are stored under {user_id}/{filename} so the policy checks the path prefix

-- Allow authenticated users to upload to their own folder
create policy "Users can upload own bills"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'bills'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Allow authenticated users to view their own bills
create policy "Users can view own bills"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'bills'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Allow authenticated users to delete their own bills
create policy "Users can delete own bills"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'bills'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
