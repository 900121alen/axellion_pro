-- Add vehicle_id column to requests table as a reference to user_vehicles
ALTER TABLE public.requests
ADD COLUMN IF NOT EXISTS vehicle_id UUID REFERENCES public.user_vehicles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_requests_vehicle_id ON public.requests(vehicle_id);
