-- Add schedule_status to requests and message_type to messages
-- Timestamp: 20260306032523

-- 1. Add schedule_status column to requests
ALTER TABLE public.requests
ADD COLUMN IF NOT EXISTS schedule_status TEXT DEFAULT 'pending'
CHECK (schedule_status IN ('pending', 'confirmed', 'declined'));

-- 2. Add message_type column to messages for system/schedule messages
ALTER TABLE public.messages
ADD COLUMN IF NOT EXISTS message_type TEXT DEFAULT 'text'
CHECK (message_type IN ('text', 'schedule_proposal', 'schedule_confirmed', 'schedule_declined'));

-- 3. Add schedule metadata columns to messages
ALTER TABLE public.messages
ADD COLUMN IF NOT EXISTS schedule_start TIMESTAMPTZ;

ALTER TABLE public.messages
ADD COLUMN IF NOT EXISTS schedule_end TIMESTAMPTZ;

-- 4. Indexes
CREATE INDEX IF NOT EXISTS idx_requests_schedule_status ON public.requests(schedule_status);
CREATE INDEX IF NOT EXISTS idx_messages_message_type ON public.messages(message_type);
