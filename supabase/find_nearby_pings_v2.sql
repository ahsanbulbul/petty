-- Function to find nearby pings with formatted location
drop function if exists find_nearby_pings(double precision, double precision, double precision);

create or replace function find_nearby_pings(
  search_lat double precision,
  search_lng double precision,
  search_radius double precision default 5000
)
returns table (
  id uuid,
  pet_name text,
  pet_type text,
  description text,
  location text,
  "timestamp" timestamptz,
  is_lost boolean,
  image_data bytea,
  contact_info text,
  created_at timestamptz,
  updated_at timestamptz,
  distance float)
language plpgsql
as $$
begin
  return query
  select 
    p.id,
    p.pet_name,
    p.pet_type,
    p.description,
    ST_AsEWKT(p.location) as location,
    p.timestamp,
    p.is_lost,
    p.image_data,
    p.contact_info,
    p.created_at,
    p.updated_at,
    ST_Distance(
      p.location::geography,
      ST_SetSRID(ST_MakePoint(search_lng, search_lat), 4326)::geography
    ) as distance
  from pet_pings p
  where ST_DWithin(
    p.location::geography,
    ST_SetSRID(ST_MakePoint(search_lng, search_lat), 4326)::geography,
    search_radius
  )
  order by distance;
end;
$$;