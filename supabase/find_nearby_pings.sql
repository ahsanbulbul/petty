DROP FUNCTION find_nearby_pings(double precision,double precision,double precision) first

-- Migrate any existing function that uses image_data
CREATE OR REPLACE FUNCTION find_nearby_pings(
  search_lat double precision,
  search_lng double precision,
  search_radius double precision default 5000
)
RETURNS TABLE (
  id uuid,
  title text,
  pet_type text,
  gender text,
  description text,
  location text,
  "timestamp" timestamptz,
  is_lost boolean,
  images text[],
  contact_info text,
  created_at timestamptz,
  updated_at timestamptz,
  distance float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
  p.title,
  p.pet_type,
  p.gender,
    p.description,
    ST_AsEWKT(p.location) as location,
    p.timestamp,
    p.is_lost,
    p.images,
    p.contact_info,
    p.created_at,
    p.updated_at,
    ST_Distance(
      p.location::geography,
      ST_SetSRID(ST_MakePoint(search_lng, search_lat), 4326)::geography
    ) as distance
  FROM pet_pings p
  WHERE ST_DWithin(
    p.location::geography,
    ST_SetSRID(ST_MakePoint(search_lng, search_lat), 4326)::geography,
    search_radius
  )
  ORDER BY distance;
END;
$$;