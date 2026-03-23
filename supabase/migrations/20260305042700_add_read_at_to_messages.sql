-- Add read_at column to messages table for tracking read state
-- Timestamp: 20260305042700

-- Add read_at column (idempotent)
ALTER TABLE public.messages
ADD COLUMN IF NOT EXISTS read_at TIMESTAMPTZ DEFAULT NULL;

-- Add index for efficient unread queries
CREATE INDEX IF NOT EXISTS idx_messages_read_at ON public.messages(read_at);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_unread ON public.messages(request_id, sender_id, read_at);
