-- Function to convert existing binary image data to base64
create or replace function migrate_images_to_base64()
returns void
language plpgsql
as $$
begin
    -- Create a temporary column
    alter table pet_pings add column if not exists image_data_new text;
    
    -- Convert existing binary data to base64
    update pet_pings 
    set image_data_new = encode(image_data::bytea, 'base64')
    where image_data is not null;
    
    -- Drop the old column and rename the new one
    alter table pet_pings drop column image_data;
    alter table pet_pings rename column image_data_new to image_data;
end;
$$;