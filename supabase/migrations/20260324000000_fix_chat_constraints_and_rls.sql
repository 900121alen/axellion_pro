-- Allow image and voice message types

ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS messages_message_type_check;

ALTER TABLE public.messages ADD CONSTRAINT messages_message_type_check CHECK (message_type IN ('text', 'image', 'voice', 'schedule_proposal', 'schedule_confirmed', 'schedule_declined'));

-- Allow masters who purchased the lead to update the request (Fixes the RLS blocking the Accept button)

DROP POLICY IF EXISTS "masters_update_requests" ON public.requests;

DROP POLICY IF EXISTS "masters_update_assigned_requests" ON public.requests;

CREATE POLICY "masters_update_requests"

    ON public.requests FOR UPDATE

    TO authenticated

    USING (

        assigned_master_id = auth.uid() OR

        EXISTS (

            SELECT 1 FROM public.leads l

            WHERE l.request_id = public.requests.id AND l.master_id = auth.uid()

        )

    )

    WITH CHECK (

        assigned_master_id = auth.uid() OR

        EXISTS (

            SELECT 1 FROM public.leads l

            WHERE l.request_id = public.requests.id AND l.master_id = auth.uid()

        )

    );
