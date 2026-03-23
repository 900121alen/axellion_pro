-- Add preferred_date and preferred_time columns to requests table
ALTER TABLE public.requests
ADD COLUMN IF NOT EXISTS preferred_date TEXT,
ADD COLUMN IF NOT EXISTS preferred_time TEXT DEFAULT 'Flexible';
