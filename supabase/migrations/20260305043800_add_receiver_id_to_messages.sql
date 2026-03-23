-- Add receiver_id column to messages table for unread tracking
-- Timestamp: 20260305043800

ALTER TABLE public.messages
ADD COLUMN IF NOT EXISTS receiver_id UUID REFERENCES public.users(id) ON DELETE SET NULL;

-- Index for efficient unread queries using receiver_id
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON public.messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_unread_v2 ON public.messages(receiver_id, request_id, read_at);
