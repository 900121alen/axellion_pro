-- Add service_name and category_name columns to requests table
-- These store the human-readable category and service selected by the client

ALTER TABLE public.requests
ADD COLUMN IF NOT EXISTS category_name TEXT,
ADD COLUMN IF NOT EXISTS service_name TEXT;
