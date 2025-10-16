-- Enable PostGIS for geospatial functionality
create extension if not exists postgis;

-- Create pet_pings table
create table if not exists pet_pings (
  id uuid default gen_random_uuid() primary key,
  pet_name text not null,
  pet_type text not null,
  description text not null,
  location geography(Point) not null,
  timestamp timestamptz not null default now(),
  is_lost boolean not null,
  image_data text, -- Changed from bytea to text for base64 storage
  contact_info text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Create index for geospatial queries
create index if not exists pet_pings_location_idx on pet_pings using gist(location);

-- Enable Row Level Security
alter table pet_pings enable row level security;

-- Create policy to allow anyone to read
create policy "Anyone can read pet_pings"
  on pet_pings
  for select
  using (true);

-- Create policy to allow anyone to create pet_pings
create policy "Anyone can create pet_pings"
  on pet_pings
  for insert
  with check (true);

-- Create policy to allow updates
create policy "Anyone can update pet_pings"
  on pet_pings
  for update
  using (true);

-- Optional: Create function to find nearby pings
create or replace function find_nearby_pings(
  lat double precision,
  lng double precision,
  radius_meters double precision default 5000
)
returns setof pet_pings
language sql
stable
as $$
  select *
  from pet_pings
  where ST_DWithin(
    location,
    ST_MakePoint(lng, lat)::geography,
    radius_meters
  )
  order by location <-> ST_MakePoint(lng, lat)::geography;
$$;