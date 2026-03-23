-- Axellion Pro - Complete Database Schema Migration
-- Tables: users, categories, master_categories, requests, leads, messages, ratings
-- Timestamp: 20260303233532

-- ============================================================
-- STEP 1: Core Tables (no foreign keys)
-- ============================================================

-- Users table (public profile, linked to auth.users)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('client', 'master', 'admin')),
    name TEXT,
    phone TEXT,
    phone_verified BOOLEAN DEFAULT false,
    email TEXT,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'blocked')),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Categories table
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    price_range_text TEXT,
    lead_price NUMERIC,
    active BOOLEAN DEFAULT true
);

-- ============================================================
-- STEP 2: Dependent Tables (with foreign keys)
-- ============================================================

-- Master-Categories junction table
CREATE TABLE IF NOT EXISTS public.master_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    master_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.categories(id) ON DELETE CASCADE
);

-- Requests table
CREATE TABLE IF NOT EXISTS public.requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES public.categories(id),
    description TEXT,
    media_url TEXT,
    address_full TEXT,
    area_name TEXT,
    budget_option TEXT,
    status TEXT DEFAULT 'searching' CHECK (status IN ('searching', 'assigned', 'answered', 'relisted', 'archived', 'cancelled')),
    assigned_master_id UUID REFERENCES public.users(id),
    assigned_at TIMESTAMPTZ,
    response_deadline TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Leads table
CREATE TABLE IF NOT EXISTS public.leads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID REFERENCES public.requests(id) ON DELETE CASCADE,
    master_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    purchased_at TIMESTAMPTZ DEFAULT now(),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'relisted')),
    was_paid BOOLEAN DEFAULT false
);

-- Messages table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID REFERENCES public.requests(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    message_text TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Ratings table
CREATE TABLE IF NOT EXISTS public.ratings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_id UUID REFERENCES public.requests(id) ON DELETE CASCADE,
    master_id UUID REFERENCES public.users(id),
    client_id UUID REFERENCES public.users(id),
    stars INTEGER CHECK (stars >= 1 AND stars <= 5),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- STEP 3: Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);
CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone);
CREATE INDEX IF NOT EXISTS idx_categories_active ON public.categories(active);
CREATE INDEX IF NOT EXISTS idx_master_categories_master_id ON public.master_categories(master_id);
CREATE INDEX IF NOT EXISTS idx_master_categories_category_id ON public.master_categories(category_id);
CREATE INDEX IF NOT EXISTS idx_requests_client_id ON public.requests(client_id);
CREATE INDEX IF NOT EXISTS idx_requests_status ON public.requests(status);
CREATE INDEX IF NOT EXISTS idx_requests_assigned_master_id ON public.requests(assigned_master_id);
CREATE INDEX IF NOT EXISTS idx_leads_master_id ON public.leads(master_id);
CREATE INDEX IF NOT EXISTS idx_leads_request_id ON public.leads(request_id);
CREATE INDEX IF NOT EXISTS idx_messages_request_id ON public.messages(request_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_ratings_master_id ON public.ratings(master_id);
CREATE INDEX IF NOT EXISTS idx_ratings_request_id ON public.ratings(request_id);

-- ============================================================
-- STEP 4: Functions (MUST be before RLS policies)
-- ============================================================

-- Trigger function: auto-create public.users row when auth user is created
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.users (id, email, name, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', ''),
        COALESCE(NEW.raw_user_meta_data->>'role', 'client')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

-- Helper function: get current user role (used in RLS)
CREATE OR REPLACE FUNCTION public.get_current_user_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
    SELECT role FROM public.users WHERE id = auth.uid() LIMIT 1;
$$;

-- ============================================================
-- STEP 5: Enable Row Level Security on all tables
-- ============================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.master_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- STEP 6: RLS Policies
-- ============================================================

-- ---- users table ----
DROP POLICY IF EXISTS "users_read_own" ON public.users;
CREATE POLICY "users_read_own"
    ON public.users FOR SELECT
    TO authenticated
    USING (id = auth.uid());

DROP POLICY IF EXISTS "users_update_own" ON public.users;
CREATE POLICY "users_update_own"
    ON public.users FOR UPDATE
    TO authenticated
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "users_insert_own" ON public.users;
CREATE POLICY "users_insert_own"
    ON public.users FOR INSERT
    TO authenticated
    WITH CHECK (id = auth.uid());

-- Admin can read all users
DROP POLICY IF EXISTS "admin_read_all_users" ON public.users;
CREATE POLICY "admin_read_all_users"
    ON public.users FOR SELECT
    TO authenticated
    USING (public.get_current_user_role() = 'admin');

-- Admin can update all users
DROP POLICY IF EXISTS "admin_update_all_users" ON public.users;
CREATE POLICY "admin_update_all_users"
    ON public.users FOR UPDATE
    TO authenticated
    USING (public.get_current_user_role() = 'admin')
    WITH CHECK (public.get_current_user_role() = 'admin');

-- ---- categories table ----
DROP POLICY IF EXISTS "categories_public_read" ON public.categories;
CREATE POLICY "categories_public_read"
    ON public.categories FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "admin_manage_categories" ON public.categories;
CREATE POLICY "admin_manage_categories"
    ON public.categories FOR ALL
    TO authenticated
    USING (public.get_current_user_role() = 'admin')
    WITH CHECK (public.get_current_user_role() = 'admin');

-- ---- master_categories table ----
DROP POLICY IF EXISTS "master_categories_read" ON public.master_categories;
CREATE POLICY "master_categories_read"
    ON public.master_categories FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "master_manage_own_categories" ON public.master_categories;
CREATE POLICY "master_manage_own_categories"
    ON public.master_categories FOR ALL
    TO authenticated
    USING (master_id = auth.uid())
    WITH CHECK (master_id = auth.uid());

-- ---- requests table ----
DROP POLICY IF EXISTS "clients_manage_own_requests" ON public.requests;
CREATE POLICY "clients_manage_own_requests"
    ON public.requests FOR ALL
    TO authenticated
    USING (client_id = auth.uid())
    WITH CHECK (client_id = auth.uid());

DROP POLICY IF EXISTS "masters_read_requests" ON public.requests;
CREATE POLICY "masters_read_requests"
    ON public.requests FOR SELECT
    TO authenticated
    USING (public.get_current_user_role() = 'master');

DROP POLICY IF EXISTS "masters_update_assigned_requests" ON public.requests;
CREATE POLICY "masters_update_assigned_requests"
    ON public.requests FOR UPDATE
    TO authenticated
    USING (assigned_master_id = auth.uid())
    WITH CHECK (assigned_master_id = auth.uid());

DROP POLICY IF EXISTS "admin_manage_all_requests" ON public.requests;
CREATE POLICY "admin_manage_all_requests"
    ON public.requests FOR ALL
    TO authenticated
    USING (public.get_current_user_role() = 'admin')
    WITH CHECK (public.get_current_user_role() = 'admin');

-- ---- leads table ----
DROP POLICY IF EXISTS "masters_manage_own_leads" ON public.leads;
CREATE POLICY "masters_manage_own_leads"
    ON public.leads FOR ALL
    TO authenticated
    USING (master_id = auth.uid())
    WITH CHECK (master_id = auth.uid());

DROP POLICY IF EXISTS "admin_manage_all_leads" ON public.leads;
CREATE POLICY "admin_manage_all_leads"
    ON public.leads FOR ALL
    TO authenticated
    USING (public.get_current_user_role() = 'admin')
    WITH CHECK (public.get_current_user_role() = 'admin');

-- ---- messages table ----
DROP POLICY IF EXISTS "users_read_request_messages" ON public.messages;
CREATE POLICY "users_read_request_messages"
    ON public.messages FOR SELECT
    TO authenticated
    USING (
        sender_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.requests r
            WHERE r.id = request_id
            AND (r.client_id = auth.uid() OR r.assigned_master_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS "users_send_messages" ON public.messages;
CREATE POLICY "users_send_messages"
    ON public.messages FOR INSERT
    TO authenticated
    WITH CHECK (sender_id = auth.uid());

DROP POLICY IF EXISTS "admin_manage_all_messages" ON public.messages;
CREATE POLICY "admin_manage_all_messages"
    ON public.messages FOR ALL
    TO authenticated
    USING (public.get_current_user_role() = 'admin')
    WITH CHECK (public.get_current_user_role() = 'admin');

-- ---- ratings table ----
DROP POLICY IF EXISTS "users_read_ratings" ON public.ratings;
CREATE POLICY "users_read_ratings"
    ON public.ratings FOR SELECT
    TO authenticated
    USING (true);

DROP POLICY IF EXISTS "clients_create_ratings" ON public.ratings;
CREATE POLICY "clients_create_ratings"
    ON public.ratings FOR INSERT
    TO authenticated
    WITH CHECK (client_id = auth.uid());

DROP POLICY IF EXISTS "admin_manage_all_ratings" ON public.ratings;
CREATE POLICY "admin_manage_all_ratings"
    ON public.ratings FOR ALL
    TO authenticated
    USING (public.get_current_user_role() = 'admin')
    WITH CHECK (public.get_current_user_role() = 'admin');

-- ============================================================
-- STEP 7: Triggers
-- ============================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- STEP 8: Seed Data (categories)
-- ============================================================

DO $$
BEGIN
    INSERT INTO public.categories (id, name, price_range_text, lead_price, active) VALUES
        (gen_random_uuid(), 'Plumbing', '500 - 5,000 ₽', 150, true),
        (gen_random_uuid(), 'Electrical Work', '1,000 - 10,000 ₽', 200, true),
        (gen_random_uuid(), 'Appliance Repair', '500 - 3,000 ₽', 120, true),
        (gen_random_uuid(), 'Furniture Assembly', '300 - 2,000 ₽', 100, true),
        (gen_random_uuid(), 'Cleaning', '1,000 - 8,000 ₽', 130, true),
        (gen_random_uuid(), 'Moving & Delivery', '2,000 - 15,000 ₽', 180, true),
        (gen_random_uuid(), 'Painting & Decoration', '3,000 - 30,000 ₽', 250, true),
        (gen_random_uuid(), 'Computer Repair', '500 - 5,000 ₽', 140, true)
    ON CONFLICT (id) DO NOTHING;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Seed data insertion failed: %', SQLERRM;
END $$;
