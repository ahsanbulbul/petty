-- Create a function to check storage bucket
create or replace function check_storage_bucket()
returns boolean
language plpgsql
security definer
as $$
declare
  bucket_exists boolean;
begin
  -- Check if bucket exists
  select exists(
    select 1 from storage.buckets 
    where id = 'pet-images'
  ) into bucket_exists;
  
  return bucket_exists;
end;
$$;