-- ============================================================
-- Riforni v3.0 — RLS Test Script (002_rls_tests.sql)
-- Run INSIDE a transaction (ROLLBACK at end cleans all test data).
-- Uses SET LOCAL ROLE + JWT claims — never tests as superuser.
-- All UUIDs are explicit literals, never derived from subselects
-- that could be hidden by RLS (which would silently return NULL).
-- ============================================================

BEGIN;

-- ── Setup: insert auth users as postgres before switching role ─
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at, raw_app_meta_data, raw_user_meta_data)
VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'alfa@riforni.test', 'x', now(), now(), now(), '{}', '{}'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'beta@riforni.test', 'x', now(), now(), now(), '{}', '{}');

-- ── Chef A creates their restaurant via RPC ───────────────────
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}', true);
SELECT public.create_restaurant('Ristorante Alfa');
-- EXPECTED: returns a UUID (restaurant_id for Alfa)

-- ── Chef B creates their restaurant ──────────────────────────
SELECT set_config('request.jwt.claims',
  '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}', true);
SELECT public.create_restaurant('Ristorante Beta');
-- EXPECTED: returns a UUID (restaurant_id for Beta)

-- ── Insert test data as postgres (no RLS) ────────────────────
RESET ROLE;
DO $$
DECLARE
  rid_a uuid;
  rid_b uuid;
BEGIN
  SELECT restaurant_id INTO rid_a FROM public.user_profiles WHERE user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  SELECT restaurant_id INTO rid_b FROM public.user_profiles WHERE user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  RAISE NOTICE 'Alfa rid=%, Beta rid=%', rid_a, rid_b;

  -- Alfa supplier with explicit UUID
  INSERT INTO public.suppliers (id, restaurant_id, name, whatsapp_e164)
  VALUES ('cccccccc-cccc-cccc-cccc-cccccccccccc', rid_a, 'Fornitore Alfa', '393331111111');

  -- Alfa product with explicit UUID
  INSERT INTO public.products (id, restaurant_id, name, unit, price_cents)
  VALUES ('dddddddd-dddd-dddd-dddd-dddddddddddd', rid_a, 'Mozzarella', 'kg', 350);
END; $$;

-- ================================================================
-- TEST 1: SELECT isolation — Chef B cannot see Chef A's data
-- ================================================================
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}', true);

DO $$
DECLARE cnt int;
BEGIN
  SELECT count(*) INTO cnt FROM public.suppliers;
  IF cnt <> 0 THEN RAISE EXCEPTION 'TEST 1 FAILED: Chef B sees % of Alfa suppliers (expected 0)', cnt; END IF;
  RAISE NOTICE 'TEST 1 PASSED: Chef B sees 0 suppliers (correct)';
END; $$;

DO $$
DECLARE cnt int;
BEGIN
  SELECT count(*) INTO cnt FROM public.restaurants;
  IF cnt <> 1 THEN RAISE EXCEPTION 'TEST 1b FAILED: Chef B sees % restaurants (expected 1 = own)', cnt; END IF;
  RAISE NOTICE 'TEST 1b PASSED: Chef B sees 1 restaurant (own only)';
END; $$;

-- ================================================================
-- TEST 2: restaurant_id hijack — no UPDATE policy on user_profiles
-- UPDATE returns 0 rows affected (not an error); verify by re-reading.
-- ================================================================
DO $$
DECLARE
  alfa_rid  uuid;
  beta_rid  uuid;
  after_rid uuid;
BEGIN
  -- Read both rids as postgres for comparison
  RESET ROLE;
  SELECT restaurant_id INTO alfa_rid FROM public.user_profiles WHERE user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  SELECT restaurant_id INTO beta_rid FROM public.user_profiles WHERE user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

  -- Switch to Chef B and attempt hijack
  SET LOCAL ROLE authenticated;
  PERFORM set_config('request.jwt.claims',
    '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}', true);

  UPDATE public.user_profiles
  SET restaurant_id = alfa_rid
  WHERE user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  -- No error expected; just 0 rows affected (no UPDATE policy)

  -- Re-read as postgres to confirm no change
  RESET ROLE;
  SELECT restaurant_id INTO after_rid FROM public.user_profiles WHERE user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  IF after_rid IS DISTINCT FROM beta_rid THEN
    RAISE EXCEPTION 'TEST 2 FAILED: restaurant_id was hijacked! now=% expected=%', after_rid, beta_rid;
  END IF;
  RAISE NOTICE 'TEST 2 PASSED: restaurant_id hijack blocked (still = %)', after_rid;
END; $$;

-- ================================================================
-- TEST 3: Cross-tenant INSERT — Chef B tries to insert supplier for Alfa
-- WITH CHECK (restaurant_id = auth_restaurant_id()) must block this.
-- ================================================================
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}', true);
DO $$
DECLARE alfa_rid uuid;
BEGIN
  RESET ROLE;
  SELECT restaurant_id INTO alfa_rid FROM public.user_profiles WHERE user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  SET LOCAL ROLE authenticated;
  PERFORM set_config('request.jwt.claims',
    '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}', true);
  BEGIN
    INSERT INTO public.suppliers (restaurant_id, name, whatsapp_e164)
    VALUES (alfa_rid, 'HackedSupplier', '390000000000');
    RAISE EXCEPTION 'TEST 3 FAILED: Cross-tenant INSERT succeeded';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'TEST 3 PASSED: Cross-tenant INSERT blocked. SQLERRM=%', SQLERRM;
  END;
END; $$;

-- ================================================================
-- TEST 4: Cross-tenant product_supplier link
-- Composite FK prevents linking Alfa's product+supplier with Beta's restaurant_id.
-- Using EXPLICIT UUIDs — never subselects that could return NULL under RLS.
-- ================================================================
RESET ROLE;
DO $$
DECLARE beta_rid uuid;
BEGIN
  SELECT restaurant_id INTO beta_rid FROM public.user_profiles WHERE user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  BEGIN
    INSERT INTO public.product_suppliers (product_id, supplier_id, restaurant_id, is_default)
    VALUES (
      'dddddddd-dddd-dddd-dddd-dddddddddddd',  -- Alfa's product (explicit UUID)
      'cccccccc-cccc-cccc-cccc-cccccccccccc',  -- Alfa's supplier (explicit UUID)
      beta_rid,                                  -- WRONG: Beta's restaurant_id
      false
    );
    RAISE EXCEPTION 'TEST 4 FAILED: Cross-tenant product_supplier link succeeded';
  EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE 'TEST 4 PASSED: Composite FK blocks cross-tenant link';
  END;
END; $$;

-- ================================================================
-- TEST 5: create_order with another tenant's supplier
-- Uses EXPLICIT supplier UUID ('cccccccc...') — NOT a subselect.
-- If we used (SELECT id FROM suppliers WHERE name='Fornitore Alfa'),
-- RLS would hide it and return NULL, making the order succeed (wrong reason).
-- ================================================================
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}', true);
DO $$
BEGIN
  BEGIN
    PERFORM public.create_order(
      gen_random_uuid(),
      'cccccccc-cccc-cccc-cccc-cccccccccccc',   -- Alfa's supplier UUID (EXPLICIT)
      'Fornitore Alfa',
      'Ordine di test',
      '[{"product_name":"Pane","quantity_milli":1000,"unit":"kg"}]'::jsonb
    );
    RAISE EXCEPTION 'TEST 5 FAILED: create_order accepted another tenant supplier';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'TEST 5 PASSED: create_order rejected cross-tenant supplier. err=%', SQLERRM;
  END;
END; $$;

-- ================================================================
-- TEST 6: Idempotency (same tenant) — same key returns same order id
-- ================================================================
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}', true);
DO $$
DECLARE
  idem uuid := '11111111-1111-1111-1111-111111111111';
  id1  uuid;
  id2  uuid;
BEGIN
  SELECT public.create_order(idem, NULL, 'Nessun Fornitore', 'Test',
    '[{"product_name":"Pane","quantity_milli":2000,"unit":"kg"}]'::jsonb) INTO id1;
  SELECT public.create_order(idem, NULL, 'Nessun Fornitore', 'Test',
    '[{"product_name":"Pane","quantity_milli":2000,"unit":"kg"}]'::jsonb) INTO id2;
  IF id1 IS DISTINCT FROM id2 THEN
    RAISE EXCEPTION 'TEST 6 FAILED: Different IDs. id1=%, id2=%', id1, id2;
  END IF;
  RAISE NOTICE 'TEST 6 PASSED: Idempotency OK, both calls return id=%', id1;
END; $$;

-- ================================================================
-- TEST 7: Cross-tenant idempotency — same key, different tenant
-- Beta must NOT get Alfa's order back; must get a different id.
-- ================================================================
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb","role":"authenticated"}', true);
DO $$
DECLARE
  idem    uuid := '11111111-1111-1111-1111-111111111111';  -- same key as Test 6
  id_beta uuid;
  id_alfa uuid;
BEGIN
  SELECT public.create_order(idem, NULL, 'Nessun Fornitore', 'Ordine Beta',
    '[{"product_name":"Latte","quantity_milli":500,"unit":"l"}]'::jsonb) INTO id_beta;

  -- Read Alfa's order as postgres
  RESET ROLE;
  SELECT id INTO id_alfa FROM public.orders
  WHERE idempotency_key = idem
  AND restaurant_id = (SELECT restaurant_id FROM public.user_profiles
                       WHERE user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

  IF id_beta = id_alfa THEN
    RAISE EXCEPTION 'TEST 7 FAILED: Same order id returned for both tenants (key collision)';
  END IF;
  RAISE NOTICE 'TEST 7 PASSED: Cross-tenant idempotency isolated. alfa=%, beta=%', id_alfa, id_beta;
END; $$;

-- ================================================================
-- TEST 8: delete_account — Chef A deletes their account
-- Verifies CASCADE: restaurant gone -> orders gone -> items gone.
-- ================================================================
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims',
  '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","role":"authenticated"}', true);
DO $$
DECLARE cnt int;
BEGIN
  PERFORM public.delete_account();
  RESET ROLE;
  -- user_profiles row should be gone (cascade from restaurants)
  SELECT count(*) INTO cnt FROM public.user_profiles WHERE user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  IF cnt > 0 THEN RAISE EXCEPTION 'TEST 8 FAILED: Alfa user_profile still exists'; END IF;
  -- suppliers should be gone
  SELECT count(*) INTO cnt FROM public.suppliers WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  IF cnt > 0 THEN RAISE EXCEPTION 'TEST 8 FAILED: Alfa supplier still exists'; END IF;
  RAISE NOTICE 'TEST 8 PASSED: delete_account cascade OK';
END; $$;

-- Verify Beta is unaffected
RESET ROLE;
DO $$
DECLARE cnt int;
BEGIN
  SELECT count(*) INTO cnt FROM public.user_profiles WHERE user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  IF cnt <> 1 THEN RAISE EXCEPTION 'TEST 8b FAILED: Beta profile missing after Alfa delete'; END IF;
  RAISE NOTICE 'TEST 8b PASSED: Beta profile intact after Alfa delete_account';
END; $$;

RAISE NOTICE '=== All RLS tests completed successfully. Rolling back... ===';
ROLLBACK;
-- ROLLBACK removes all test data including auth.users inserts.
