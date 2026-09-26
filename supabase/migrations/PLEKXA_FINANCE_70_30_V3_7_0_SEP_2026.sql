-- PLEKXA Finance 70/30 policy — production-compatible migration v3.7.0
-- IMPORTANT: Run this entire file as one query in Supabase SQL Editor; do not run a highlighted fragment.
-- Net revenue = gross revenue less permitted direct deductions.
-- Plekxa retains 70%; 30% enters the relevant Index pool.
-- The rates are snapshotted on each revenue entry so future policy changes
-- do not alter the economics recorded for that entry.

BEGIN;

-- Fail early with a useful message if the finance foundation has not been installed.
DO $$
BEGIN
  IF to_regclass('public.asset_revenue_entries') IS NULL THEN
    RAISE EXCEPTION 'Missing public.asset_revenue_entries. Install the Project Hub / commission-index-finance foundation first.';
  END IF;
  IF to_regclass('public.asset_registry') IS NULL THEN
    RAISE EXCEPTION 'Missing public.asset_registry. Install the Project Hub foundation first.';
  END IF;
  IF to_regclass('public.asset_contributors') IS NULL THEN
    RAISE EXCEPTION 'Missing public.asset_contributors. Install the Project Hub foundation first.';
  END IF;
  IF to_regclass('public.creator_revenue_allocations') IS NULL THEN
    RAISE EXCEPTION 'Missing public.creator_revenue_allocations. Install the commission-index-finance foundation first.';
  END IF;
END
$$;

ALTER TABLE public.asset_revenue_entries
  ADD COLUMN IF NOT EXISTS plekxa_share_rate numeric(7,4) NOT NULL DEFAULT 70.0000,
  ADD COLUMN IF NOT EXISTS index_pool_rate numeric(7,4) NOT NULL DEFAULT 30.0000;

-- Scope the constraint check to this table, rather than relying on a global name match.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'asset_revenue_entries_split_rate_check'
      AND conrelid = 'public.asset_revenue_entries'::regclass
  ) THEN
    ALTER TABLE public.asset_revenue_entries
      ADD CONSTRAINT asset_revenue_entries_split_rate_check
      CHECK (
        plekxa_share_rate >= 0
        AND plekxa_share_rate <= 100
        AND index_pool_rate >= 0
        AND index_pool_rate <= 100
        AND plekxa_share_rate + index_pool_rate = 100
      );
  END IF;
END
$$;

-- Amounts are derived from the same net-revenue formula already used by
-- net_distributable. We repeat the base expression because PostgreSQL generated
-- columns cannot safely depend on another generated column across versions.
ALTER TABLE public.asset_revenue_entries
  ADD COLUMN IF NOT EXISTS plekxa_share_amount numeric(14,2)
    GENERATED ALWAYS AS (
      round(
        greatest(
          0,
          gross_revenue
          - distribution_fees
          - collection_fees
          - banking_fees
          - transaction_fees
          - taxes
          - direct_third_party_costs
        ) * plekxa_share_rate / 100.0,
        2
      )
    ) STORED,
  ADD COLUMN IF NOT EXISTS index_pool_amount numeric(14,2)
    GENERATED ALWAYS AS (
      round(
        greatest(
          0,
          gross_revenue
          - distribution_fees
          - collection_fees
          - banking_fees
          - transaction_fees
          - taxes
          - direct_third_party_costs
        ) * index_pool_rate / 100.0,
        2
      )
    ) STORED;

-- Replace only the calculation function. Existing paid/available allocations are
-- not rewritten. When a period is newly calculated/recalculated, creator earnings
-- are based on the 30% Index pool rather than 100% of net revenue.
CREATE OR REPLACE FUNCTION public.plekxa_recalculate_index_period(p_index_id uuid, p_start date, p_end date, p_currency char(3))
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_index_pool numeric := 0;
  a record;
  c record;
  v_amount numeric;
  n integer := 0;
BEGIN
  SELECT coalesce(sum(r.index_pool_amount), 0)
  INTO v_index_pool
  FROM public.asset_revenue_entries AS r
  INNER JOIN public.asset_registry AS ar
    ON ar.id = r.asset_id
  WHERE ar.index_id = p_index_id
    AND r.period_start = p_start
    AND r.period_end = p_end
    AND r.currency = p_currency
    AND r.status IN ('approved', 'allocated', 'paid');

  -- Only provisional calculations may be regenerated. Available/paid rows remain intact.
  DELETE FROM public.creator_revenue_allocations
  WHERE index_id = p_index_id
    AND period_start = p_start
    AND period_end = p_end
    AND currency = p_currency
    AND status = 'calculated';

  FOR a IN
    SELECT id, index_participation_percentage
    FROM public.asset_registry
    WHERE index_id = p_index_id
  LOOP
    FOR c IN
      SELECT *
      FROM public.asset_contributors
      WHERE asset_id = a.id
    LOOP
      v_amount := round(
        v_index_pool
        * coalesce(a.index_participation_percentage, 0) / 100.0
        * coalesce(nullif(to_jsonb(c)->>'master_share','')::numeric, nullif(to_jsonb(c)->>'ownership_percentage','')::numeric, 0) / 100.0,
        2
      );

      INSERT INTO public.creator_revenue_allocations (
        revenue_entry_id,
        period_start,
        period_end,
        asset_id,
        index_id,
        contributor_id,
        creator_name,
        asset_index_percentage,
        contributor_asset_percentage,
        effective_index_percentage,
        index_period_revenue,
        amount,
        currency,
        status
      )
      VALUES (
        NULL,
        p_start,
        p_end,
        a.id,
        p_index_id,
        c.id,
        coalesce(to_jsonb(c)->>'contributor_name', to_jsonb(c)->>'name', 'Contributor'),
        coalesce(a.index_participation_percentage, 0),
        coalesce(nullif(to_jsonb(c)->>'master_share','')::numeric, nullif(to_jsonb(c)->>'ownership_percentage','')::numeric, 0),
        coalesce(a.index_participation_percentage, 0) * coalesce(nullif(to_jsonb(c)->>'master_share','')::numeric, nullif(to_jsonb(c)->>'ownership_percentage','')::numeric, 0) / 100.0,
        v_index_pool,
        v_amount,
        p_currency,
        'calculated'
      );

      n := n + 1;
    END LOOP;
  END LOOP;

  RETURN n;
END
$$;

COMMENT ON COLUMN public.asset_revenue_entries.plekxa_share_rate IS
  'Plekxa retention percentage snapshotted for this revenue entry; current default 70%.';
COMMENT ON COLUMN public.asset_revenue_entries.index_pool_rate IS
  'Percentage of net revenue entering the Index pool; current default 30%.';
COMMENT ON COLUMN public.asset_revenue_entries.plekxa_share_amount IS
  'Plekxa retained amount after permitted direct deductions.';
COMMENT ON COLUMN public.asset_revenue_entries.index_pool_amount IS
  'Amount entering the Index pool after permitted direct deductions and Plekxa retention.';

NOTIFY pgrst, 'reload schema';

COMMIT;
