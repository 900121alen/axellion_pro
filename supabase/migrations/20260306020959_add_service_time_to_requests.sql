-- Add service_time column to requests table for scheduling feature
-- Timestamp: 20260306020959

ALTER TABLE public.requests
ADD COLUMN IF NOT EXISTS service_time TIMESTAMPTZ;

ALTER TABLE public.requests
ADD COLUMN IF NOT EXISTS service_time_end TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_requests_service_time ON public.requests(service_time);
