-- Create request_photos bucket for storing service request images
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'request_photos',
    'request_photos',
    true,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic', 'image/heif']
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- RLS: Anyone can view public request photos
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage'
        AND tablename = 'objects'
        AND policyname = 'request_photos_public_read'
    ) THEN
        CREATE POLICY "request_photos_public_read" ON storage.objects
        FOR SELECT TO public
        USING (bucket_id = 'request_photos');
    END IF;
END $$;

-- RLS: Authenticated users can upload to their own folder
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage'
        AND tablename = 'objects'
        AND policyname = 'request_photos_authenticated_upload'
    ) THEN
        CREATE POLICY "request_photos_authenticated_upload" ON storage.objects
        FOR INSERT TO authenticated
        WITH CHECK (
            bucket_id = 'request_photos'
            AND (storage.foldername(name))[1] = auth.uid()::text
        );
    END IF;
END $$;

-- RLS: Users can delete their own photos
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'storage'
        AND tablename = 'objects'
        AND policyname = 'request_photos_owner_delete'
    ) THEN
        CREATE POLICY "request_photos_owner_delete" ON storage.objects
        FOR DELETE TO authenticated
        USING (
            bucket_id = 'request_photos'
            AND (storage.foldername(name))[1] = auth.uid()::text
        );
    END IF;
END $$;
