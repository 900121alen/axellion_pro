-- Add user_vehicles table for storing saved vehicles per client
CREATE TABLE IF NOT EXISTS public.user_vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    make TEXT NOT NULL,
    model TEXT NOT NULL,
    year TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_vehicles_user_id ON public.user_vehicles(user_id);

ALTER TABLE public.user_vehicles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_manage_own_vehicles" ON public.user_vehicles;
CREATE POLICY "users_manage_own_vehicles"
ON public.user_vehicles
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Add vehicle_info column to requests table
ALTER TABLE public.requests
ADD COLUMN IF NOT EXISTS vehicle_info TEXT;
