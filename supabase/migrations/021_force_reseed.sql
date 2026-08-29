-- ============================================================
-- MIGRATION 021: Force re-seed with full demo data
-- ============================================================

CREATE OR REPLACE FUNCTION public.force_reseed(p_user_id uuid)
RETURNS void AS $fn$
DECLARE
  v_user_id uuid := p_user_id;
  v_cat_rent uuid;
  v_cat_food uuid;
  v_cat_fun uuid;
  v_cat_savings uuid;
  v_cat_salary uuid;
  v_cat_freelance uuid;
  v_sub_housing uuid;
  v_sub_utilities uuid;
  v_sub_internet uuid;
  v_sub_maintenance uuid;
  v_sub_groceries uuid;
  v_sub_dining uuid;
  v_sub_delivery uuid;
  v_sub_coffee uuid;
  v_sub_entertainment uuid;
  v_sub_shopping uuid;
  v_sub_travel uuid;
  v_sub_subscriptions uuid;
  v_sub_emergency uuid;
  v_sub_investments uuid;
  v_sub_goals uuid;
  v_sub_base uuid;
  v_sub_bonus uuid;
  v_sub_projects uuid;
  v_sub_consulting uuid;
  v_now date := current_date;
  v_jun1 date := '2025-06-01';
  v_jul1 date := '2025-07-01';
  v_aug1 date := '2025-08-01';
BEGIN
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'user_id required'; END IF;

  -- Delete existing data
  DELETE FROM public.transactions WHERE user_id = v_user_id;
  DELETE FROM public.budgets WHERE user_id = v_user_id;
  DELETE FROM public.categories WHERE user_id = v_user_id;
  DELETE FROM public.savings_goals WHERE user_id = v_user_id;
  DELETE FROM public.notifications WHERE user_id = v_user_id;

  -- EXPENSE CATEGORIES
  INSERT INTO public.categories (user_id, name, icon, color, type) VALUES (v_user_id, 'Rent', '🏠', '#202124', 'expense') RETURNING id INTO v_cat_rent;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Housing', '🏠', '#202124', v_cat_rent, 'expense') RETURNING id INTO v_sub_housing;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Utilities', '💡', '#f472b6', v_cat_rent, 'expense') RETURNING id INTO v_sub_utilities;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Internet', '🌐', '#4285F4', v_cat_rent, 'expense') RETURNING id INTO v_sub_internet;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Maintenance', '🔧', '#fb923c', v_cat_rent, 'expense') RETURNING id INTO v_sub_maintenance;

  INSERT INTO public.categories (user_id, name, icon, color, type) VALUES (v_user_id, 'Food', '🍔', '#D7F34A', 'expense') RETURNING id INTO v_cat_food;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Groceries', '🛒', '#2e7d32', v_cat_food, 'expense') RETURNING id INTO v_sub_groceries;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Dining Out', '🍽️', '#fb923c', v_cat_food, 'expense') RETURNING id INTO v_sub_dining;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Delivery', '🛵', '#e91e63', v_cat_food, 'expense') RETURNING id INTO v_sub_delivery;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Coffee', '☕', '#795548', v_cat_food, 'expense') RETURNING id INTO v_sub_coffee;

  INSERT INTO public.categories (user_id, name, icon, color, type) VALUES (v_user_id, 'Fun', '🎮', '#4285F4', 'expense') RETURNING id INTO v_cat_fun;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Entertainment', '🎬', '#a78bfa', v_cat_fun, 'expense') RETURNING id INTO v_sub_entertainment;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Shopping', '🛍️', '#fb923c', v_cat_fun, 'expense') RETURNING id INTO v_sub_shopping;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Travel', '🚗', '#9c27b0', v_cat_fun, 'expense') RETURNING id INTO v_sub_travel;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Subscriptions', '📱', '#f472b6', v_cat_fun, 'expense') RETURNING id INTO v_sub_subscriptions;

  INSERT INTO public.categories (user_id, name, icon, color, type) VALUES (v_user_id, 'Savings', '💰', '#2e7d32', 'expense') RETURNING id INTO v_cat_savings;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Emergency Fund', '🛡️', '#d32f2f', v_cat_savings, 'expense') RETURNING id INTO v_sub_emergency;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Investments', '📈', '#1565c0', v_cat_savings, 'expense') RETURNING id INTO v_sub_investments;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Goals', '🎯', '#fb923c', v_cat_savings, 'expense') RETURNING id INTO v_sub_goals;

  -- INCOME CATEGORIES
  INSERT INTO public.categories (user_id, name, icon, color, type) VALUES (v_user_id, 'Salary', '💼', '#2e7d32', 'income') RETURNING id INTO v_cat_salary;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Base Pay', '💰', '#2e7d32', v_cat_salary, 'income') RETURNING id INTO v_sub_base;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Bonus', '🎁', '#fb923c', v_cat_salary, 'income') RETURNING id INTO v_sub_bonus;

  INSERT INTO public.categories (user_id, name, icon, color, type) VALUES (v_user_id, 'Freelance', '💻', '#4285F4', 'income') RETURNING id INTO v_cat_freelance;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Projects', '🛠️', '#4285F4', v_cat_freelance, 'income') RETURNING id INTO v_sub_projects;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Consulting', '🤝', '#9c27b0', v_cat_freelance, 'income') RETURNING id INTO v_sub_consulting;

  -- BUDGETS (August 2025)
  INSERT INTO public.budgets (user_id, category_id, amount, spent, month) VALUES
    (v_user_id, v_cat_rent, 20000, 12000, v_aug1),
    (v_user_id, v_cat_food, 12000, 8200, v_aug1),
    (v_user_id, v_cat_fun, 8000, 4250, v_aug1),
    (v_user_id, v_cat_savings, 15000, 8000, v_aug1);

  -- TRANSACTIONS - JUNE 2025
  INSERT INTO public.transactions (user_id, name, amount, type, date, category_id) VALUES
    (v_user_id, 'Monthly Salary', 55000, 'income', v_jun1, v_sub_base),
    (v_user_id, 'Rent Payment', -12000, 'expense', v_jun1, v_sub_housing),
    (v_user_id, 'Electricity Bill', -1800, 'expense', '2025-06-03', v_sub_utilities),
    (v_user_id, 'Internet Bill', -999, 'expense', '2025-06-05', v_sub_internet),
    (v_user_id, 'Groceries - Big Bazaar', -3200, 'expense', '2025-06-07', v_sub_groceries),
    (v_user_id, 'Swiggy Order', -650, 'expense', '2025-06-09', v_sub_delivery),
    (v_user_id, 'Dining Out - Barbeque Nation', -1800, 'expense', '2025-06-12', v_sub_dining),
    (v_user_id, 'Netflix Subscription', -649, 'expense', '2025-06-15', v_sub_subscriptions),
    (v_user_id, 'Amazon Shopping', -2400, 'expense', '2025-06-18', v_sub_shopping),
    (v_user_id, 'Movie Tickets - PVR', -500, 'expense', '2025-06-20', v_sub_entertainment),
    (v_user_id, 'Uber Rides', -1200, 'expense', '2025-06-22', v_sub_travel),
    (v_user_id, 'Coffee - Starbucks', -350, 'expense', '2025-06-25', v_sub_coffee),
    (v_user_id, 'Emergency Fund SIP', -5000, 'expense', '2025-06-28', v_sub_emergency),
    (v_user_id, 'Freelance Project - Website', 12000, 'income', '2025-06-20', v_sub_projects);

  -- TRANSACTIONS - JULY 2025
  INSERT INTO public.transactions (user_id, name, amount, type, date, category_id) VALUES
    (v_user_id, 'Monthly Salary', 56000, 'income', v_jul1, v_sub_base),
    (v_user_id, 'Rent Payment', -12000, 'expense', v_jul1, v_sub_housing),
    (v_user_id, 'Electricity Bill', -2100, 'expense', '2025-07-03', v_sub_utilities),
    (v_user_id, 'Internet Bill', -999, 'expense', '2025-07-05', v_sub_internet),
    (v_user_id, 'Groceries - DMart', -4500, 'expense', '2025-07-07', v_sub_groceries),
    (v_user_id, 'Zomato Orders', -1200, 'expense', '2025-07-10', v_sub_delivery),
    (v_user_id, 'Dining Out - KFC', -800, 'expense', '2025-07-12', v_sub_dining),
    (v_user_id, 'Spotify Subscription', -199, 'expense', '2025-07-14', v_sub_subscriptions),
    (v_user_id, 'Flipkart Purchase', -3500, 'expense', '2025-07-16', v_sub_shopping),
    (v_user_id, 'Concert Tickets', -2000, 'expense', '2025-07-18', v_sub_entertainment),
    (v_user_id, 'Ola Rides', -900, 'expense', '2025-07-20', v_sub_travel),
    (v_user_id, 'Coffee - Blue Tokai', -500, 'expense', '2025-07-22', v_sub_coffee),
    (v_user_id, 'Mutual Fund SIP', -8000, 'expense', '2025-07-25', v_sub_investments),
    (v_user_id, 'Freelance Consulting', 15000, 'income', '2025-07-15', v_sub_consulting),
    (v_user_id, 'Maintenance Bill', -500, 'expense', '2025-07-28', v_sub_maintenance);

  -- TRANSACTIONS - AUGUST 2025 (current month)
  INSERT INTO public.transactions (user_id, name, amount, type, date, category_id) VALUES
    (v_user_id, 'Monthly Salary', 58000, 'income', v_aug1, v_sub_base),
    (v_user_id, 'Rent Payment', -12000, 'expense', v_aug1, v_sub_housing),
    (v_user_id, 'Electricity Bill', -2200, 'expense', '2025-08-02', v_sub_utilities),
    (v_user_id, 'Internet Bill', -999, 'expense', '2025-08-03', v_sub_internet),
    (v_user_id, 'Groceries - Zepto', -3800, 'expense', '2025-08-05', v_sub_groceries),
    (v_user_id, 'Big Bazaar Shopping', -2100, 'expense', '2025-08-07', v_sub_groceries),
    (v_user_id, 'Swiggy Orders', -900, 'expense', '2025-08-09', v_sub_delivery),
    (v_user_id, 'Dining Out - Pizza Hut', -1200, 'expense', '2025-08-11', v_sub_dining),
    (v_user_id, 'Netflix + Spotify', -848, 'expense', '2025-08-13', v_sub_subscriptions),
    (v_user_id, 'Myntra Shopping', -1800, 'expense', '2025-08-15', v_sub_shopping),
    (v_user_id, 'Movie - Stree 2', -400, 'expense', '2025-08-17', v_sub_entertainment),
    (v_user_id, 'Uber + Ola', -1500, 'expense', '2025-08-19', v_sub_travel),
    (v_user_id, 'Coffee - CCD', -280, 'expense', '2025-08-21', v_sub_coffee),
    (v_user_id, 'Emergency Fund SIP', -5000, 'expense', '2025-08-23', v_sub_emergency),
    (v_user_id, 'Laptop Fund', -3000, 'expense', '2025-08-25', v_sub_goals),
    (v_user_id, 'Freelance Project - App', 8000, 'income', '2025-08-10', v_sub_projects),
    (v_user_id, 'Bonus - Performance', 5000, 'income', '2025-08-28', v_sub_bonus);

  -- SAVINGS GOALS
  INSERT INTO public.savings_goals (user_id, name, target, current, icon, deadline) VALUES
    (v_user_id, 'New Laptop', 80000, 32000, '💻', '2025-12-31'),
    (v_user_id, 'Emergency Fund', 100000, 42000, '🛡️', '2026-03-31'),
    (v_user_id, 'Goa Trip', 30000, 10200, '🏖️', '2025-11-30');

  RAISE NOTICE 'Full demo data seeded for user %', v_user_id;
END;
$fn$ LANGUAGE plpgsql SECURITY DEFINER;
