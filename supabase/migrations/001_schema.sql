-- ============================================================
-- Riforni v3.0 — Migration 001: Schema, RLS, RPCs
-- PostgreSQL 15+ required (column-specific SET NULL syntax)
-- Run: supabase db push   OR   psql -f 001_schema.sql
-- ============================================================

-- Clean slate (idempotent re-run)
DROP TABLE IF EXISTS public.order_items        CASCADE;
DROP TABLE IF EXISTS public.orders             CASCADE;
DROP TABLE IF EXISTS public.product_suppliers  CASCADE;
DROP TABLE IF EXISTS public.products           CASCADE;
DROP TABLE IF EXISTS public.categories         CASCADE;
DROP TABLE IF EXISTS public.suppliers          CASCADE;
DROP TABLE IF EXISTS public.user_profiles      CASCADE;
DROP TABLE IF EXISTS public.restaurants        CASCADE;
DROP TYPE  IF EXISTS public.user_role          CASCADE;
DROP TYPE  IF EXISTS public.order_status       CASCADE;
DROP FUNCTION IF EXISTS public.auth_restaurant_id()                            CASCADE;
DROP FUNCTION IF EXISTS public.create_restaurant(text)                         CASCADE;
DROP FUNCTION IF EXISTS public.create_order(uuid,uuid,text,text,jsonb)         CASCADE;
DROP FUNCTION IF EXISTS public.update_order_status(uuid,public.order_status)   CASCADE;
DROP FUNCTION IF EXISTS public.delete_account()                                CASCADE;

-- No uuid-ossp needed; use built-in gen_random_uuid() (PG 13+)

-- ── Enums ─────────────────────────────────────────────────────
CREATE TYPE public.user_role    AS ENUM ('owner','head_chef','staff');
CREATE TYPE public.order_status AS ENUM ('sent','delivered','cancelled');

-- ── Tables ────────────────────────────────────────────────────

CREATE TABLE public.restaurants (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name       text NOT NULL CHECK (char_length(trim(name)) BETWEEN 1 AND 120),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- user_profiles: written ONLY by SECURITY DEFINER RPCs, never from client.
CREATE TABLE public.user_profiles (
  user_id       uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  restaurant_id uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  role          public.user_role NOT NULL DEFAULT 'owner',
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_up_rest ON public.user_profiles(restaurant_id);

CREATE TABLE public.suppliers (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  name          text NOT NULL CHECK (char_length(trim(name)) > 0),
  -- E.164 digits only, no '+', e.g. 393331234567 (mobile) or 390212345678 (landline)
  -- Leading zero of Italian landlines is preserved: 02xxx -> 390xxxx
  whatsapp_e164 text NOT NULL,
  email         text,
  notes         text,
  is_active     boolean NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (restaurant_id, id)   -- required for composite FKs from product_suppliers/orders
);
CREATE INDEX idx_sup_rest ON public.suppliers(restaurant_id);

CREATE TABLE public.categories (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  name          text NOT NULL,
  emoji         text,
  sort_order    int  NOT NULL DEFAULT 0,
  UNIQUE (restaurant_id, id)
);
CREATE INDEX idx_cat_rest ON public.categories(restaurant_id);

CREATE TABLE public.products (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  category_id   uuid,
  name          text NOT NULL CHECK (char_length(trim(name)) > 0),
  unit          text NOT NULL DEFAULT 'pz',
  price_cents   int  NOT NULL DEFAULT 0 CHECK (price_cents >= 0),
  notes         text,
  is_active     boolean NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (restaurant_id, id),
  -- FIX #2: PG 15+ column-specific SET NULL.
  -- Only category_id is nulled; restaurant_id (NOT NULL) is untouched.
  CONSTRAINT fk_product_category
    FOREIGN KEY (restaurant_id, category_id)
    REFERENCES  public.categories(restaurant_id, id)
    ON DELETE   SET NULL (category_id)
);
CREATE INDEX idx_prod_rest ON public.products(restaurant_id);
CREATE INDEX idx_prod_cat  ON public.products(category_id) WHERE category_id IS NOT NULL;

CREATE TABLE public.product_suppliers (
  product_id    uuid NOT NULL,
  supplier_id   uuid NOT NULL,
  restaurant_id uuid NOT NULL,   -- denormalised; enforces same-tenant via composite FK
  is_default    boolean NOT NULL DEFAULT false,
  supplier_code text,
  PRIMARY KEY (product_id, supplier_id),
  -- FIX #4: composite FKs prevent cross-tenant linking at DB level
  CONSTRAINT fk_ps_prod FOREIGN KEY (restaurant_id, product_id)
    REFERENCES public.products(restaurant_id, id) ON DELETE CASCADE,
  CONSTRAINT fk_ps_sup  FOREIGN KEY (restaurant_id, supplier_id)
    REFERENCES public.suppliers(restaurant_id, id) ON DELETE CASCADE
);
CREATE INDEX idx_ps_sup  ON public.product_suppliers(supplier_id);
CREATE INDEX idx_ps_rest ON public.product_suppliers(restaurant_id);

CREATE TABLE public.orders (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  idempotency_key uuid NOT NULL UNIQUE,   -- client-generated UUID
  -- FIX #3: CASCADE so delete_account() (which deletes restaurant) cascades here
  restaurant_id   uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  supplier_id     uuid,                   -- nullable: kept when supplier soft-deleted
  supplier_name   text NOT NULL,          -- snapshot at order time
  message         text NOT NULL,
  status          public.order_status NOT NULL DEFAULT 'sent',
  created_at      timestamptz NOT NULL DEFAULT now(),
  -- FIX #2: PG 15+ column-specific SET NULL on supplier_id only
  CONSTRAINT fk_order_supplier
    FOREIGN KEY (restaurant_id, supplier_id)
    REFERENCES  public.suppliers(restaurant_id, id)
    ON DELETE   SET NULL (supplier_id)
);
CREATE INDEX idx_ord_rest    ON public.orders(restaurant_id);
CREATE INDEX idx_ord_created ON public.orders(restaurant_id, created_at DESC);

CREATE TABLE public.order_items (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id       uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  product_name   text NOT NULL,         -- snapshot
  -- FIX #5: quantity_milli (x1000) supports fractional quantities (1.5 kg = 1500)
  quantity_milli int  NOT NULL CHECK (quantity_milli > 0),
  unit           text NOT NULL
);
CREATE INDEX idx_oi_ord ON public.order_items(order_id);

-- ============================================================
-- HELPER FUNCTION
-- FIX #1: SECURITY DEFINER breaks the infinite recursion loop.
-- Without this: auth_restaurant_id() is INVOKER -> reads user_profiles
-- -> user_profiles SELECT policy calls auth_restaurant_id() -> infinite loop.
-- With SECURITY DEFINER: the fn runs as its definer (postgres) which is not
-- subject to RLS on user_profiles, so no recursion.
-- ============================================================
CREATE OR REPLACE FUNCTION public.auth_restaurant_id()
RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT restaurant_id FROM public.user_profiles WHERE user_id = auth.uid() LIMIT 1;
$$;
-- No explicit GRANT needed; called only from policies and SECURITY DEFINER RPCs.

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE public.restaurants       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suppliers         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items       ENABLE ROW LEVEL SECURITY;

-- ── restaurants ───────────────────────────────────────────────
CREATE POLICY p_rest_sel ON public.restaurants
  FOR SELECT TO authenticated USING (id = auth_restaurant_id());

-- FIX #3 (restaurants): owner only; no client DELETE
CREATE POLICY p_rest_upd ON public.restaurants
  FOR UPDATE TO authenticated
  USING  (id = auth_restaurant_id()
    AND (SELECT role FROM public.user_profiles WHERE user_id = auth.uid()) = 'owner')
  WITH CHECK (id = auth_restaurant_id());

-- ── user_profiles ─────────────────────────────────────────────
-- FIX #1: USING = (user_id = auth.uid()), NOT auth_restaurant_id() — avoids recursion.
-- FIX #1: SELECT only — no INSERT/UPDATE/DELETE from client (prevents restaurant_id hijack).
CREATE POLICY p_up_sel ON public.user_profiles
  FOR SELECT TO authenticated USING (user_id = auth.uid());

-- ── suppliers ─────────────────────────────────────────────────
CREATE POLICY p_sup_sel ON public.suppliers
  FOR SELECT TO authenticated USING (restaurant_id = auth_restaurant_id());

CREATE POLICY p_sup_ins ON public.suppliers
  FOR INSERT TO authenticated
  WITH CHECK (restaurant_id = auth_restaurant_id()
    AND (SELECT role FROM public.user_profiles WHERE user_id = auth.uid())
        IN ('owner','head_chef'));

-- FIX #7: UPDATE has same owner/head_chef role check as INSERT
CREATE POLICY p_sup_upd ON public.suppliers
  FOR UPDATE TO authenticated
  USING  (restaurant_id = auth_restaurant_id()
    AND (SELECT role FROM public.user_profiles WHERE user_id = auth.uid())
        IN ('owner','head_chef'))
  WITH CHECK (restaurant_id = auth_restaurant_id());
-- No DELETE — use is_active = false (soft delete).

-- ── categories ────────────────────────────────────────────────
CREATE POLICY p_cat_sel ON public.categories
  FOR SELECT TO authenticated USING (restaurant_id = auth_restaurant_id());

CREATE POLICY p_cat_ins ON public.categories
  FOR INSERT TO authenticated
  WITH CHECK (restaurant_id = auth_restaurant_id()
    AND (SELECT role FROM public.user_profiles WHERE user_id = auth.uid())
        IN ('owner','head_chef'));

-- FIX #7: UPDATE has same owner/head_chef role check as INSERT
CREATE POLICY p_cat_upd ON public.categories
  FOR UPDATE TO authenticated
  USING  (restaurant_id = auth_restaurant_id()
    AND (SELECT role FROM public.user_profiles WHERE user_id = auth.uid())
        IN ('owner','head_chef'))
  WITH CHECK (restaurant_id = auth_restaurant_id());
-- Allow DELETE on categories (no is_active; just remove empty categories)

-- ── products ──────────────────────────────────────────────────
CREATE POLICY p_prod_sel ON public.products
  FOR SELECT TO authenticated USING (restaurant_id = auth_restaurant_id());

CREATE POLICY p_prod_ins ON public.products
  FOR INSERT TO authenticated
  WITH CHECK (restaurant_id = auth_restaurant_id()
    AND (SELECT role FROM public.user_profiles WHERE user_id = auth.uid())
        IN ('owner','head_chef'));

-- FIX #7: UPDATE has same owner/head_chef role check as INSERT
CREATE POLICY p_prod_upd ON public.products
  FOR UPDATE TO authenticated
  USING  (restaurant_id = auth_restaurant_id()
    AND (SELECT role FROM public.user_profiles WHERE user_id = auth.uid())
        IN ('owner','head_chef'))
  WITH CHECK (restaurant_id = auth_restaurant_id());
-- No DELETE — use is_active = false.

-- ── product_suppliers ─────────────────────────────────────────
CREATE POLICY p_ps_sel ON public.product_suppliers
  FOR SELECT TO authenticated USING (restaurant_id = auth_restaurant_id());
CREATE POLICY p_ps_ins ON public.product_suppliers
  FOR INSERT TO authenticated WITH CHECK (restaurant_id = auth_restaurant_id());
CREATE POLICY p_ps_upd ON public.product_suppliers
  FOR UPDATE TO authenticated
  USING (restaurant_id = auth_restaurant_id()) WITH CHECK (restaurant_id = auth_restaurant_id());
CREATE POLICY p_ps_del ON public.product_suppliers
  FOR DELETE TO authenticated USING (restaurant_id = auth_restaurant_id());

-- ── orders: client reads only; writes via RPCs ────────────────
CREATE POLICY p_ord_sel ON public.orders
  FOR SELECT TO authenticated USING (restaurant_id = auth_restaurant_id());
-- FIX #7: No client INSERT/UPDATE/DELETE — all via create_order/update_order_status RPCs.

-- ── order_items ───────────────────────────────────────────────
CREATE POLICY p_oi_sel ON public.order_items
  FOR SELECT TO authenticated
  USING (order_id IN (
    SELECT id FROM public.orders WHERE restaurant_id = auth_restaurant_id()
  ));

-- ============================================================
-- RPCs
-- FIX #6: All RPCs: REVOKE from PUBLIC and anon, GRANT to authenticated only.
-- ============================================================

-- ── create_restaurant ─────────────────────────────────────────
-- FIX #10: Called after email confirmation + first login.
-- Atomically creates restaurant + owner profile. Idempotent.
CREATE OR REPLACE FUNCTION public.create_restaurant(p_name text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_rid uuid;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  -- Idempotent: return existing if user already completed onboarding
  SELECT restaurant_id INTO v_rid FROM public.user_profiles WHERE user_id = v_uid;
  IF v_rid IS NOT NULL THEN RETURN v_rid; END IF;
  p_name := trim(p_name);
  IF char_length(p_name) = 0 THEN RAISE EXCEPTION 'Nome ristorante non può essere vuoto'; END IF;
  INSERT INTO public.restaurants (name) VALUES (p_name) RETURNING id INTO v_rid;
  INSERT INTO public.user_profiles (user_id, restaurant_id, role) VALUES (v_uid, v_rid, 'owner');
  RETURN v_rid;
END; $$;
REVOKE ALL ON FUNCTION public.create_restaurant(text) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.create_restaurant(text) TO authenticated;

-- ── create_order ──────────────────────────────────────────────
-- FIX #4a: idempotency check filtered by restaurant_id (cross-tenant key safety)
-- FIX #4b: ON CONFLICT (idempotency_key) DO NOTHING to handle race condition
-- FIX #4c: p_items as jsonb (PostgREST-friendly, no composite type array)
-- FIX #4d: validates items and supplier ownership
-- FIX #5: uses quantity_milli in items
-- p_items format: [{"product_name":"X","quantity_milli":1500,"unit":"kg"}]
CREATE OR REPLACE FUNCTION public.create_order(
  p_idempotency_key uuid,
  p_supplier_id     uuid,      -- NULL allowed (no supplier assigned)
  p_supplier_name   text,
  p_message         text,
  p_items           jsonb
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_rid uuid := auth_restaurant_id();
  v_oid uuid;
BEGIN
  IF v_uid IS NULL OR v_rid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;

  -- Validate items
  IF p_items IS NULL OR jsonb_array_length(p_items) = 0 THEN
    RAISE EXCEPTION 'Order must have at least one item';
  END IF;
  IF EXISTS (
    SELECT 1 FROM jsonb_array_elements(p_items) item
    WHERE (item->>'quantity_milli')::int <= 0
       OR trim(item->>'product_name') = ''
       OR trim(item->>'unit') = ''
  ) THEN
    RAISE EXCEPTION 'Invalid item data (quantity_milli must be > 0, name/unit required)';
  END IF;

  -- Validate supplier belongs to this restaurant (and is active)
  IF p_supplier_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.suppliers
      WHERE id = p_supplier_id AND restaurant_id = v_rid AND is_active = true
    ) THEN RAISE EXCEPTION 'Supplier not found in this restaurant'; END IF;
  END IF;

  -- FIX #4a: Idempotency filtered by restaurant_id to prevent cross-tenant key reuse
  SELECT id INTO v_oid FROM public.orders
  WHERE idempotency_key = p_idempotency_key AND restaurant_id = v_rid;
  IF v_oid IS NOT NULL THEN RETURN v_oid; END IF;

  -- FIX #4b: ON CONFLICT DO NOTHING handles concurrent identical requests
  INSERT INTO public.orders (idempotency_key, restaurant_id, supplier_id, supplier_name, message)
  VALUES (p_idempotency_key, v_rid, p_supplier_id, p_supplier_name, p_message)
  ON CONFLICT (idempotency_key) DO NOTHING
  RETURNING id INTO v_oid;

  -- If another request won the race, fetch existing id
  IF v_oid IS NULL THEN
    SELECT id INTO v_oid FROM public.orders
    WHERE idempotency_key = p_idempotency_key AND restaurant_id = v_rid;
    RETURN v_oid;
  END IF;

  -- Insert items from JSONB (FIX #4c: no composite type, PostgREST-friendly)
  INSERT INTO public.order_items (order_id, product_name, quantity_milli, unit)
  SELECT v_oid,
         trim(item->>'product_name'),
         (item->>'quantity_milli')::int,
         trim(item->>'unit')
  FROM jsonb_array_elements(p_items) AS item;

  RETURN v_oid;
END; $$;
REVOKE ALL ON FUNCTION public.create_order(uuid,uuid,text,text,jsonb) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.create_order(uuid,uuid,text,text,jsonb) TO authenticated;

-- ── update_order_status ───────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_order_status(
  p_order_id uuid,
  p_status   public.order_status
) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  UPDATE public.orders SET status = p_status
  WHERE id = p_order_id AND restaurant_id = auth_restaurant_id();
  IF NOT FOUND THEN RAISE EXCEPTION 'Order not found or access denied'; END IF;
END; $$;
REVOKE ALL ON FUNCTION public.update_order_status(uuid,public.order_status) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.update_order_status(uuid,public.order_status) TO authenticated;

-- ── delete_account ────────────────────────────────────────────
-- FIX #3: orders.restaurant_id is now ON DELETE CASCADE, so deleting restaurant
-- cascades to all orders/items automatically.
--
-- NOTE on Supabase auth user deletion (two options):
--   Option A (this fn): DELETE FROM auth.users may work if Supabase grants
--                       the postgres role rights on auth schema. Test on your project.
--   Option B (recommended for prod): Remove the DELETE FROM auth.users line,
--                       and call Edge Function supabase/functions/delete-account/
--                       which uses supabaseAdmin.auth.admin.deleteUser(uid).
CREATE OR REPLACE FUNCTION public.delete_account()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_uid  uuid := auth.uid();
  v_rid  uuid;
  v_role public.user_role;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
  SELECT restaurant_id, role INTO v_rid, v_role
  FROM public.user_profiles WHERE user_id = v_uid;
  IF v_role = 'owner' AND v_rid IS NOT NULL THEN
    -- CASCADE deletes: user_profiles, suppliers, categories, products,
    -- product_suppliers, orders (now CASCADE not RESTRICT), order_items
    DELETE FROM public.restaurants WHERE id = v_rid;
  ELSE
    DELETE FROM public.user_profiles WHERE user_id = v_uid;
  END IF;
  -- Option A: direct auth.users delete (may require elevated privileges on Supabase)
  -- If this errors with "permission denied", switch to Option B (Edge Function).
  DELETE FROM auth.users WHERE id = v_uid;
END; $$;
REVOKE ALL ON FUNCTION public.delete_account() FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.delete_account() TO authenticated;

-- ============================================================
-- NOTES
-- ============================================================
-- 1. PostgreSQL 15+ is required for "ON DELETE SET NULL (column_name)" syntax.
--    Supabase supports PG 15+; verify your project version in the Dashboard.
-- 2. Supabase FREE tier: projects auto-pause after 1 week of inactivity.
--    To prevent pausing: Dashboard > Database > Extensions > enable pg_cron,
--    then: SELECT cron.schedule('keep-alive','0 12 * * *','SELECT 1');
--    Or upgrade to Pro ($25/mo) for the demo period.
-- 3. Email confirmation: with "Confirm email" ON (default), users cannot log in
--    until they confirm. create_restaurant() must be called AFTER confirmation + login.
--    The Flutter app handles this: OnboardingScreen shows only when session exists.
-- 4. Supabase project region: set to EU (Frankfurt) for GDPR / Italian users.
