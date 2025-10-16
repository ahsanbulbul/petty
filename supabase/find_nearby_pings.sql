-- Function to find nearby pings
create or replace function find_nearby_pings(
  search_lat double precision,
  search_lng double precision,
  search_radius double precision default 5000
)
returns setof pet_pings
language plpgsql
as $$
begin
  return query
  select *
  from pet_pings
  where ST_DWithin(
    location::geography,
    ST_SetSRID(ST_MakePoint(search_lng, search_lat), 4326)::geography,
    search_radius
  )
  order by location <-> ST_SetSRID(ST_MakePoint(search_lng, search_lat), 4326)::geography;
end;
$$;