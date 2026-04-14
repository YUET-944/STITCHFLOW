-- GATE 3: Database Row Level Security (RLS) implementation for Supabase
-- This SQL enforces rules directly at the postgres block layer so API layer bypasses fail.

-- Enable RLS
ALTER TABLE "measurements" ENABLE ROW LEVEL SECURITY;

-- Write Policy: Only inserted if auth user is the tailor, AND an active link exists.
CREATE POLICY "measurement_write" ON "measurements"
  FOR INSERT WITH CHECK (
    tailor_id::text = auth.uid()::text
    AND EXISTS (
      SELECT 1 FROM tailor_client_links
      WHERE tailor_id::text = auth.uid()::text
        AND client_id = "measurements".client_id
        AND is_active = true
    )
  );

-- Read Policy: Clients can read their own. Tailors can read if link exists.
CREATE POLICY "measurement_read" ON "measurements" 
  FOR SELECT USING (
    client_id::text = auth.uid()::text
    OR (
      tailor_id::text = auth.uid()::text AND EXISTS (
        SELECT 1 FROM tailor_client_links
        WHERE tailor_id::text = auth.uid()::text
          AND client_id = "measurements".client_id
          AND is_active = true
      )
    )
  );
