# EcoWise Multi-Vendor Architecture — Project Context & Status

**Date:** 2026-11-24  
**Workspace:** `c:\Users\03366\ecowise`  
**Git Branch:** `vendor` (uncommitted working changes ready for testing/commit)

---

## 1. Where We Are Right Now

The multi-vendor feature set (3 roles: `admin`, `vendor`, `user`) has been implemented across authentication, admin approval, vendor portal, store CRUD, and product CRUD.

- **Latest State on Device (`SM-A305F`):**
  - Vendor registration, admin approval routing, and pending/rejected screens are wired up.
  - A test vendor account (`vendorteststore@gmail.com`, `vendor_id: f771ad83-e683-4ed7-a0aa-72a4dd005a67`) has an approved store **`Eco pak`** created in Supabase (`id: 80a4c745-593e-438d-b4e3-a61e9b10b046`, `store_type: physical`, `is_approved: true`).
  - The Riverpod `Provider.autoDispose` crash (`Cannot use the Ref of Provider<VendorStoreController> after it has been disposed`) during store creation has been fixed in `lib/vendor/providers/vendor_dashboard_providers.dart`, and the duplicate store created during retries was removed from Supabase.
  - The accidental `Store Category` field was removed from store forms so store fields match the original `AddStoreScreen` / `EditStoreScreen` design (category remains exclusively on products).
  - `flutter analyze lib/vendor` and `flutter analyze lib/user/providers/nearby_stores_providers.dart lib/admin/models/store.dart` pass with **0 compile errors** (only pre-existing deprecation/lint info notices).

---

## 2. What Is Done

### A. Database & RLS Scripts (Local SQL Files)
- `supabase_vendor_migration.sql`
  - Extends `profiles` (`role`, `vendor_status`, `contact_number`, `rejection_reason`, `reviewed_at`, `reviewed_by`).
  - Extends `stores` (`vendor_id`, `category`, `is_approved`, plus newly added `deletion_requested`, `deletion_reason`, `deletion_requested_at`).
  - Creates `vendor_applications` table and indexes.
  - Adds `handle_new_user()` trigger on `auth.users` to assign `'vendor'` role and `'pending'` status from signup metadata.
- `supabase_enable_rls.sql`
  - Ensures `admin@ecowise.com` exists in `public.profiles` with `role = 'admin'`.
  - Configures storage bucket & RLS policies for `store-images`, `product-images`, and `avatars`.
  - Configures table RLS for `vendor_applications`, `stores` (vendor cannot delete directly; only admin can `DELETE`), `products` (vendor has full CRUD on their own store's products), and `profiles`.
  - Defines `admin_approve_vendor` and `admin_reject_vendor` (`SECURITY DEFINER` RPCs).

### B. Authentication & Role-Based Routing
- `lib/authentication/splash_screen.dart` & `lib/user/screens/sign_in_screen.dart`: Routes users based on `profiles.role` and `vendor_status` (`admin` -> `AdminHomeScreen`, approved `vendor` -> `VendorHomeScreen`, pending -> `VendorPendingScreen`, rejected -> `VendorRejectedScreen`, `user` -> onboarding/home). Clears stale SnackBars on navigation.
- `lib/vendor/providers/vendor_auth_provider.dart` & `lib/vendor/screens/vendor_register_screen.dart`: Supports vendor signup (and upgrading an existing user account), uploads store image with fallback, fixed 1.3px chip overflow, clears SnackBars on dispose.
- `lib/vendor/screens/vendor_pending_screen.dart` & `lib/vendor/screens/vendor_rejected_screen.dart`: Status screens for unapproved vendors with sign-out support.
- Logout icons added to `lib/admin/screens/admin_dashboard_screen.dart`, `lib/user/screens/home_screen.dart`, and `lib/vendor/screens/vendor_home_screen.dart`.

### C. Admin Vendor & Store Review
- `lib/admin/screens/admin_home_screen.dart`: Added `Vendors` bottom-nav tab.
- `lib/admin/providers/admin_vendor_providers.dart`: Filterable list (`all`, `pending`, `approved`, `rejected`) cross-checked with `profiles` (`role = 'vendor'`), permanent `adminVendorControllerProvider`, RPC-first approve/reject logic.
- `lib/admin/screens/admin_vendor_requests_screen.dart` & `lib/admin/screens/admin_vendor_detail_screen.dart`: Admin UI to inspect applications and approve/reject with mounted widget `ref.invalidate`.
- `lib/admin/screens/admin_stores_screen.dart` & `lib/admin/screens/store_detail_screen.dart`: Added `"Deletion Requested"` badge on store cards and `"Vendor Requested Store Removal"` review banner with **Approve & Delete** (`deleteStoreAndProducts`) and **Decline Request** (`declineStoreDeletion`) actions.
- Admin store/product creation remains disabled per project constraint (`// OLD ADMIN STORE CREATION – DISABLED...`, `// OLD ADMIN PRODUCT CREATION – DISABLED...`).

### D. Vendor Portal — Store & Product CRUD
- **Models:** `lib/admin/models/store.dart` & `lib/admin/models/store_model.dart` preserved with original fields plus `vendorId`, `isApproved`, and safe-default `deletionRequested` / `deletionReason`.
- **Providers:** `lib/vendor/providers/vendor_dashboard_providers.dart` provides `currentVendorStoreProvider`, `vendorStoreProductsProvider`, `vendorMetricsProvider`, and permanent `vendorStoreControllerProvider` (`createStore`, `updateStore`, `requestStoreDeletion`, `cancelStoreDeletion`, `deleteProduct`).
- **Vendor Home:** `lib/vendor/screens/vendor_home_screen.dart` shows "+ Create Your Store" empty state when no store exists, or full dashboard (store card, product count & avg eco score metrics, Add Product / Manage Items actions, product preview, removal request banner/controls).
- **Add / Edit Store:** `lib/vendor/screens/vendor_add_store_screen.dart` & `lib/vendor/screens/vendor_edit_store_screen.dart` match original admin design (image picker, store name, Physical/Online toggle, `PickLocationScreen` map picker, website, phone, opening hours, description; no category field). Edit screen includes **Request Store Removal** (requires admin approval).
- **Add / View / Edit / Delete Products:**
  - `lib/vendor/screens/vendor_add_product_screen.dart`: Image picker, category selector (`productCategories`), price, `EcoScoreCalculator`, `addProductNotifierProvider` (uploads to `product-images` + triggers background MiniLM AI embedding via `AiApiService.embedProduct`), and QR code dialog (`QrImageView`).
  - `lib/vendor/screens/vendor_products_screen.dart`: Lists vendor products with Add, Edit, and Delete (with confirmation).
  - `lib/vendor/screens/vendor_edit_product_screen.dart`: Full edit form + background AI re-embedding.

---

## 3. Known Gaps & What Still Needs to Be Done

### 1. Run Missing Store Deletion Columns in Supabase SQL Editor (Blocking for Store Removal Flow)
Live REST inspection showed `deletion_requested` **does not exist yet** on the remote `stores` table (`HTTP 400: Bad Request`). `createStore` works now because `'deletion_requested'` was removed from insert payloads, **but** tapping **"Request Store Removal"** or **"Cancel Removal Request"** will fail until these columns are added in Supabase:

```sql
ALTER TABLE stores
  ADD COLUMN IF NOT EXISTS deletion_requested BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS deletion_reason TEXT,
  ADD COLUMN IF NOT EXISTS deletion_requested_at TIMESTAMPTZ;
```

### 2. Verify/Update `store_summary` SQL View in Supabase
Several screens/providers read from the `store_summary` view rather than `stores` directly:
- `lib/admin/providers/store_list_providers.dart` (`AdminStoresScreen`)
- `lib/user/providers/nearby_stores_providers.dart`
- `lib/user/providers/store_detail_providers.dart`
- `lib/user/providers/chatbot_providers.dart`

**Action needed:** Confirm in Supabase SQL Editor that `store_summary` includes `vendor_id`, `is_approved`, and (once added) `deletion_requested` / `deletion_reason` — otherwise the `"Deletion Requested"` badge on `AdminStoresScreen` will stay hidden even after a vendor requests deletion, and `storeListProvider` / `nearbyStoresProvider` should be verified against live store rows.

### 3. End-to-End Device Testing Checklist
- [ ] Hot restart / open app as approved vendor (`vendorteststore@gmail.com`) and verify `VendorHomeScreen` loads `Eco pak`.
- [ ] Test **Edit Store** (`VendorEditStoreScreen`) — update phone, hours, description, or map location and confirm changes persist.
- [ ] Test **Add Product** (`VendorAddProductScreen`) — verify `product-images` upload, eco score calculation, QR code modal, and AI embedding (`AiApiService.embedProduct`).
- [ ] Test **Edit Product** & **Delete Product** from `VendorProductsScreen`.
- [ ] *(After running SQL above)* Test **Request Store Removal** from Vendor -> **Decline Request** from Admin -> **Request Store Removal** -> **Approve & Delete** from Admin.
- [ ] Test **User Side** — verify `Eco pak` and its products appear in user browse/nearby/search screens and QR scanner resolves the new product.

### 4. Final Verification & Git Hygiene
- [ ] Run full `flutter analyze` across the entire repo and `flutter build apk --debug` to ensure clean release compilation.
- [ ] Review modified files (`git diff`), including `lib/core/config/supabase_config.dart`, before committing to the `vendor` branch.
