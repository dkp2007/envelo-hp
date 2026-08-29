-- ============================================================
-- MIGRATION 023: Debug helper + verify data exists
-- ============================================================

CREATE OR REPLACE FUNCTION public.check_data(p_user_id uuid)
RETURNS jsonb AS $fn$
DECLARE
  result jsonb;
BEGIN
  SELECT jsonb_build_object(
    'categories', (SELECT count(*) FROM public.categories WHERE user_id = p_user_id),
    'transactions', (SELECT count(*) FROM public.transactions WHERE user_id = p_user_id),
    'budgets', (SELECT count(*) FROM public.budgets WHERE user_id = p_user_id),
    'savings_goals', (SELECT count(*) FROM public.savings_goals WHERE user_id = p_user_id),
    'categories_sample', (SELECT jsonb_agg(jsonb_build_object('id', id, 'name', name, 'type', type)) FROM public.categories WHERE user_id = p_user_id LIMIT 5),
    'transactions_sample', (SELECT jsonb_agg(jsonb_build_object('id', id, 'name', name, 'amount', amount, 'type', type, 'date', date, 'category_id', category_id)) FROM public.transactions WHERE user_id = p_user_id LIMIT 5)
  ) INTO result;
  RETURN result;
END;
$fn$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant access
GRANT EXECUTE ON FUNCTION public.check_data(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.check_data(uuid) TO anon;
