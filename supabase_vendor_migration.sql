-- ==============================================================================
-- EcoWise Multi-Vendor Architecture Migration
-- ==============================================================================

-- 1. Extend profiles table with role and vendor verification fields
ALTER TABLE profiles 
  ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user' CHECK (role IN ('admin', 'vendor', 'user')),
  ADD COLUMN IF NOT EXISTS vendor_status TEXT DEFAULT 'none' CHECK (vendor_status IN ('none', 'pending', 'approved', 'rejected')),
  ADD COLUMN IF NOT EXISTS contact_number TEXT,
  ADD COLUMN IF NOT EXISTS rejection_reason TEXT,
  ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS reviewed_by UUID REFERENCES profiles(id);

-- Ensure the existing admin account is assigned the 'admin' role
UPDATE profiles 
SET role = 'admin' 
WHERE email = 'admin@ecowise.com' OR id IN (
  SELECT id FROM auth.users WHERE email = 'admin@ecowise.com'
);

-- 2. Link stores to vendors with approval status & deletion requests
ALTER TABLE stores 
  ADD COLUMN IF NOT EXISTS vendor_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS category TEXT,
  ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS deletion_requested BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS deletion_reason TEXT,
  ADD COLUMN IF NOT EXISTS deletion_requested_at TIMESTAMPTZ;

-- All legacy/existing stores remain approved (vendor_id = NULL means official/admin store)
UPDATE stores SET is_approved = TRUE WHERE is_approved IS NULL;

-- 3. Dedicated vendor_applications table for administrative review
CREATE TABLE IF NOT EXISTS vendor_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  owner_name TEXT NOT NULL,
  email TEXT NOT NULL,
  contact_number TEXT NOT NULL,
  store_name TEXT NOT NULL,
  store_address TEXT NOT NULL,
  store_description TEXT,
  store_category TEXT,
  store_type TEXT DEFAULT 'physical',
  store_image_url TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  rejection_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES profiles(id),
  store_id UUID REFERENCES stores(id) ON DELETE SET NULL
);

-- 4. Fast Indexes
CREATE INDEX IF NOT EXISTS idx_stores_vendor_id ON stores(vendor_id);
CREATE INDEX IF NOT EXISTS idx_stores_is_approved ON stores(is_approved);
CREATE INDEX IF NOT EXISTS idx_vendor_applications_status ON vendor_applications(status);
CREATE INDEX IF NOT EXISTS idx_vendor_applications_user_id ON vendor_applications(user_id);

-- 5. Trigger to automatically assign vendor role from auth.users metadata
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (
    id, 
    email, 
    name, 
    role, 
    vendor_status,
    contact_number,
    profile_completed,
    onboarding_completed
  )
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'name', ''),
    COALESCE(new.raw_user_meta_data->>'role', 'user'),
    CASE 
      WHEN new.raw_user_meta_data->>'role' = 'vendor' THEN 'pending' 
      ELSE 'none' 
    END,
    new.raw_user_meta_data->>'contact_number',
    CASE WHEN new.raw_user_meta_data->>'role' = 'vendor' THEN TRUE ELSE FALSE END,
    CASE WHEN new.raw_user_meta_data->>'role' = 'vendor' THEN TRUE ELSE FALSE END
  )
  ON CONFLICT (id) DO UPDATE SET
    role = CASE 
      WHEN EXCLUDED.role = 'vendor' THEN 'vendor' 
      ELSE profiles.role 
    END,
    vendor_status = CASE 
      WHEN EXCLUDED.role = 'vendor' THEN 'pending' 
      ELSE profiles.vendor_status 
    END,
    contact_number = COALESCE(EXCLUDED.contact_number, profiles.contact_number);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
