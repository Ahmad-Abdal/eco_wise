-- ==============================================================================
-- EcoWise Row Level Security (RLS) & Storage Policies
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 0. ENSURE ADMIN PROFILE EXISTS IN PROFILES TABLE
-- ------------------------------------------------------------------------------
INSERT INTO public.profiles (id, email, name, role, profile_completed, onboarding_completed)
SELECT id, email, 'Admin', 'admin', true, true
FROM auth.users
WHERE email = 'admin@ecowise.com'
ON CONFLICT (id) DO UPDATE SET role = 'admin', email = 'admin@ecowise.com';

UPDATE public.profiles SET role = 'admin' WHERE email = 'admin@ecowise.com';


-- ------------------------------------------------------------------------------
-- 1. STORAGE BUCKETS & STORAGE OBJECTS RLS
-- ------------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('store-images', 'store-images', true),
  ('product-images', 'product-images', true),
  ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Public View Objects" ON storage.objects;
DROP POLICY IF EXISTS "Allow Store Images Upload" ON storage.objects;
DROP POLICY IF EXISTS "Allow Store Images Update" ON storage.objects;
DROP POLICY IF EXISTS "Allow Store Images Delete" ON storage.objects;
DROP POLICY IF EXISTS "Allow Product Images Upload" ON storage.objects;
DROP POLICY IF EXISTS "Allow Product Images Update" ON storage.objects;
DROP POLICY IF EXISTS "Allow Product Images Delete" ON storage.objects;
DROP POLICY IF EXISTS "Allow Avatars Upload" ON storage.objects;
DROP POLICY IF EXISTS "Allow Avatars Update" ON storage.objects;

-- 1.1 Allow public read access to all images
CREATE POLICY "Public View Objects"
ON storage.objects FOR SELECT
USING (bucket_id IN ('store-images', 'product-images', 'avatars'));

-- 1.2 Store Images: allow insert/update/delete
CREATE POLICY "Allow Store Images Upload"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'store-images');

CREATE POLICY "Allow Store Images Update"
ON storage.objects FOR UPDATE
USING (bucket_id = 'store-images');

CREATE POLICY "Allow Store Images Delete"
ON storage.objects FOR DELETE
USING (bucket_id = 'store-images');

-- 1.3 Product Images: allow insert/update/delete
CREATE POLICY "Allow Product Images Upload"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'product-images');

CREATE POLICY "Allow Product Images Update"
ON storage.objects FOR UPDATE
USING (bucket_id = 'product-images');

CREATE POLICY "Allow Product Images Delete"
ON storage.objects FOR DELETE
USING (bucket_id = 'product-images');

-- 1.4 Avatars: allow insert/update
CREATE POLICY "Allow Avatars Upload"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'avatars');

CREATE POLICY "Allow Avatars Update"
ON storage.objects FOR UPDATE
USING (bucket_id = 'avatars');


-- ------------------------------------------------------------------------------
-- 2. VENDOR APPLICATIONS TABLE RLS
-- ------------------------------------------------------------------------------
ALTER TABLE vendor_applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow vendor application insert" ON vendor_applications;
DROP POLICY IF EXISTS "Allow vendor application select" ON vendor_applications;
DROP POLICY IF EXISTS "Allow vendor application update" ON vendor_applications;

CREATE POLICY "Allow vendor application insert"
ON vendor_applications FOR INSERT
WITH CHECK (true);

CREATE POLICY "Allow vendor application select"
ON vendor_applications FOR SELECT
USING (
  auth.uid() = user_id 
  OR (auth.jwt()->>'email') = 'admin@ecowise.com'
  OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "Allow vendor application update"
ON vendor_applications FOR UPDATE
USING (
  (auth.jwt()->>'email') = 'admin@ecowise.com'
  OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);


-- ------------------------------------------------------------------------------
-- 3. STORES TABLE RLS & DELETION REQUEST COLUMNS
-- ------------------------------------------------------------------------------
ALTER TABLE stores 
  ADD COLUMN IF NOT EXISTS vendor_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS category TEXT,
  ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS deletion_requested BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS deletion_reason TEXT,
  ADD COLUMN IF NOT EXISTS deletion_requested_at TIMESTAMPTZ;

ALTER TABLE stores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow store select" ON stores;
DROP POLICY IF EXISTS "Allow store insert" ON stores;
DROP POLICY IF EXISTS "Allow store update" ON stores;
DROP POLICY IF EXISTS "Allow store delete" ON stores;

CREATE POLICY "Allow store select"
ON stores FOR SELECT
USING (
  is_approved = true 
  OR vendor_id = auth.uid() 
  OR (auth.jwt()->>'email') = 'admin@ecowise.com'
  OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "Allow store insert"
ON stores FOR INSERT
WITH CHECK (true);

CREATE POLICY "Allow store update"
ON stores FOR UPDATE
USING (
  vendor_id = auth.uid() 
  OR (auth.jwt()->>'email') = 'admin@ecowise.com'
  OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "Allow store delete"
ON stores FOR DELETE
USING (
  (auth.jwt()->>'email') = 'admin@ecowise.com'
  OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);


-- ------------------------------------------------------------------------------
-- 4. PRODUCTS TABLE RLS
-- ------------------------------------------------------------------------------
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow product select" ON products;
DROP POLICY IF EXISTS "Allow product insert" ON products;
DROP POLICY IF EXISTS "Allow product update" ON products;
DROP POLICY IF EXISTS "Allow product delete" ON products;

CREATE POLICY "Allow product select"
ON products FOR SELECT
USING (true);

CREATE POLICY "Allow product insert"
ON products FOR INSERT
WITH CHECK (
  EXISTS (SELECT 1 FROM stores WHERE stores.id = products.store_id AND stores.vendor_id = auth.uid())
  OR (auth.jwt()->>'email') = 'admin@ecowise.com'
  OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "Allow product update"
ON products FOR UPDATE
USING (
  EXISTS (SELECT 1 FROM stores WHERE stores.id = products.store_id AND stores.vendor_id = auth.uid())
  OR (auth.jwt()->>'email') = 'admin@ecowise.com'
  OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "Allow product delete"
ON products FOR DELETE
USING (
  EXISTS (SELECT 1 FROM stores WHERE stores.id = products.store_id AND stores.vendor_id = auth.uid())
  OR (auth.jwt()->>'email') = 'admin@ecowise.com'
  OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);


-- ------------------------------------------------------------------------------
-- 5. PROFILES TABLE RLS
-- ------------------------------------------------------------------------------
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow profiles select" ON profiles;
DROP POLICY IF EXISTS "Allow profiles insert" ON profiles;
DROP POLICY IF EXISTS "Allow profiles update" ON profiles;

CREATE POLICY "Allow profiles select"
ON profiles FOR SELECT
USING (true);

CREATE POLICY "Allow profiles insert"
ON profiles FOR INSERT
WITH CHECK (auth.uid() = id OR true);

CREATE POLICY "Allow profiles update"
ON profiles FOR UPDATE
USING (
  auth.uid() = id 
  OR (auth.jwt()->>'email') = 'admin@ecowise.com'
  OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
);


-- ------------------------------------------------------------------------------
-- 6. SUPPORTING TABLES RLS
-- ------------------------------------------------------------------------------
ALTER TABLE IF EXISTS wishlist ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow wishlist all" ON wishlist;
CREATE POLICY "Allow wishlist all" ON wishlist FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE IF EXISTS scans ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow scans all" ON scans;
CREATE POLICY "Allow scans all" ON scans FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE IF EXISTS notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow notifications all" ON notifications;
CREATE POLICY "Allow notifications all" ON notifications FOR ALL USING (true) WITH CHECK (true);

ALTER TABLE IF EXISTS store_ratings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow store_ratings all" ON store_ratings;
CREATE POLICY "Allow store_ratings all" ON store_ratings FOR ALL USING (true) WITH CHECK (true);


-- ------------------------------------------------------------------------------
-- 7. STORED PROCEDURES FOR ADMIN APPROVAL & REJECTION (SECURITY DEFINER)
-- Bypasses RLS to guarantee atomic approval and rejection
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_approve_vendor(
  target_user_id UUID, 
  target_app_id UUID DEFAULT NULL, 
  target_store_id UUID DEFAULT NULL
)
RETURNS void AS $$
BEGIN
  -- 1. Update profiles to vendor role and approved status
  UPDATE public.profiles
  SET role = 'vendor',
      vendor_status = 'approved',
      rejection_reason = NULL,
      reviewed_at = NOW()
  WHERE id = target_user_id;

  -- 2. Update vendor_applications
  IF target_app_id IS NOT NULL THEN
    UPDATE public.vendor_applications
    SET status = 'approved',
        reviewed_at = NOW()
    WHERE id = target_app_id;
  ELSE
    UPDATE public.vendor_applications
    SET status = 'approved',
        reviewed_at = NOW()
    WHERE user_id = target_user_id;
  END IF;

  -- 3. Approve stores
  IF target_store_id IS NOT NULL THEN
    UPDATE public.stores
    SET is_approved = true
    WHERE id = target_store_id;
  ELSE
    UPDATE public.stores
    SET is_approved = true
    WHERE vendor_id = target_user_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.admin_reject_vendor(
  target_user_id UUID, 
  reason TEXT, 
  target_app_id UUID DEFAULT NULL, 
  target_store_id UUID DEFAULT NULL
)
RETURNS void AS $$
BEGIN
  -- 1. Update profiles to vendor role and rejected status
  UPDATE public.profiles
  SET role = 'vendor',
      vendor_status = 'rejected',
      rejection_reason = reason,
      reviewed_at = NOW()
  WHERE id = target_user_id;

  -- 2. Update vendor_applications
  IF target_app_id IS NOT NULL THEN
    UPDATE public.vendor_applications
    SET status = 'rejected',
        rejection_reason = reason,
        reviewed_at = NOW()
    WHERE id = target_app_id;
  ELSE
    UPDATE public.vendor_applications
    SET status = 'rejected',
        rejection_reason = reason,
        reviewed_at = NOW()
    WHERE user_id = target_user_id;
  END IF;

  -- 3. Disapprove store
  IF target_store_id IS NOT NULL THEN
    UPDATE public.stores
    SET is_approved = false
    WHERE id = target_store_id;
  ELSE
    UPDATE public.stores
    SET is_approved = false
    WHERE vendor_id = target_user_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
