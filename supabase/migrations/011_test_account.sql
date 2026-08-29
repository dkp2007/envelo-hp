-- ============================================================
-- MIGRATION 011: Create test demo account with full data
-- ============================================================
-- First create the test user via Supabase Auth API, then run this.

-- Helper function: seed demo data for the logged-in user
CREATE OR REPLACE FUNCTION public.seed_demo_data()
RETURNS void AS $$
DECLARE
  v_user_id uuid;
  v_cat_rent uuid;
  v_cat_food uuid;
  v_cat_fun uuid;
  v_cat_savings uuid;
  v_cat_salary uuid;
  v_cat_freelance uuid;
  -- Subcategories
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
  v_sub_overtime uuid;
  v_sub_projects uuid;
  v_sub_consulting uuid;
  v_now date := current_date;
  v_jun1 date := '2025-06-01';
  v_jul1 date := '2025-07-01';
  v_aug1 date := '2025-08-01';
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;

  -- Skip if already seeded
  IF EXISTS (SELECT 1 FROM public.categories WHERE user_id = v_user_id) THEN
    RETURN;
  END IF;

  -- ── EXPENSE CATEGORIES ──
  INSERT INTO public.categories (user_id, name, icon, color, type)
  VALUES (v_user_id, 'Rent', '🏠', '#202124', 'expense') RETURNING id INTO v_cat_rent;

  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES
    (v_user_id, 'Housing', '🏠', '#202124', v_cat_rent, 'expense') RETURNING id INTO v_sub_housing,
    (v_user_id, 'Utilities', '💡', '#f472b6', v_cat_rent, 'expense') RETURNING id INTO v_sub_utilities,
    (v_user_id, 'Internet', '🌐', '#4285F4', v_cat_rent, 'expense') RETURNING id INTO v_sub_internet,
    (v_user_id, 'Maintenance', '🔧', '#795548', v_cat_rent, 'expense') RETURNING id INTO v_sub_maintenance;

  INSERT INTO public.categories (user_id, name, icon, color, type)
  VALUES (v_user_id, 'Food', '🍔', '#D7F34A', 'expense') RETURNING id INTO v_cat_food;

  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES
    (v_user_id, 'Groceries', '🛒', '#D7F34A', v_cat_food, 'expense') RETURNING id INTO v_sub_groceries,
    (v_user_id, 'Dining Out', '🍽️', '#fb923c', v_cat_food, 'expense') RETURNING id INTO v_sub_dining,
    (v_user_id, 'Delivery', '🛵', '#f472b6', v_cat_food, 'expense') RETURNING id INTO v_sub_delivery,
    (v_user_id, 'Coffee', '☕', '#795548', v_cat_food, 'expense') RETURNING id INTO v_sub_coffee;

  INSERT INTO public.categories (user_id, name, icon, color, type)
  VALUES (v_user_id, 'Fun', '🎮', '#4285F4', 'expense') RETURNING id INTO v_cat_fun;

  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES
    (v_user_id, 'Entertainment', '🎬', '#a78bfa', v_cat_fun, 'expense') RETURNING id INTO v_sub_entertainment,
    (v_user_id, 'Shopping', '🛍️', '#fb923c', v_cat_fun, 'expense') RETURNING id INTO v_sub_shopping,
    (v_user_id, 'Travel', '✈️', '#4285F4', v_cat_fun, 'expense') RETURNING id INTO v_sub_travel,
    (v_user_id, 'Subscriptions', '📱', '#f472b6', v_cat_fun, 'expense') RETURNING id INTO v_sub_subscriptions;

  INSERT INTO public.categories (user_id, name, icon, color, type)
  VALUES (v_user_id, 'Savings', '💰', '#2e7d32', 'expense') RETURNING id INTO v_cat_savings;

  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES
    (v_user_id, 'Emergency Fund', '🏦', '#2e7d32', v_cat_savings, 'expense') RETURNING id INTO v_sub_emergency,
    (v_user_id, 'Investments', '📈', '#4285F4', v_cat_savings, 'expense') RETURNING id INTO v_sub_investments,
    (v_user_id, 'Goals', '🎯', '#D7F34A', v_cat_savings, 'expense') RETURNING id INTO v_sub_goals;

  -- ── INCOME CATEGORIES ──
  INSERT INTO public.categories (user_id, name, icon, color, type)
  VALUES (v_user_id, 'Salary', '💼', '#2e7d32', 'income') RETURNING id INTO v_cat_salary;

  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES
    (v_user_id, 'Base Salary', '💰', '#2e7d32', v_cat_salary, 'income') RETURNING id INTO v_sub_base,
    (v_user_id, 'Bonus', '🎁', '#388e3c', v_cat_salary, 'income') RETURNING id INTO v_sub_bonus,
    (v_user_id, 'Overtime', '⏰', '#43a047', v_cat_salary, 'income') RETURNING id INTO v_sub_overtime;

  INSERT INTO public.categories (user_id, name, icon, color, type)
  VALUES (v_user_id, 'Freelance', '💻', '#4285F4', 'income') RETURNING id INTO v_cat_freelance;

  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES
    (v_user_id, 'Projects', '📋', '#4285F4', v_cat_freelance, 'income') RETURNING id INTO v_sub_projects,
    (v_user_id, 'Consulting', '🤝', '#5c9aff', v_cat_freelance, 'income') RETURNING id INTO v_sub_consulting;

  -- ── BUDGETS (August 2025) ──
  INSERT INTO public.budgets (user_id, category_id, amount, spent, month) VALUES
    (v_user_id, v_cat_rent, 20000, 12800, v_aug1),
    (v_user_id, v_cat_food, 8000, 5250, v_aug1),
    (v_user_id, v_cat_fun, 10000, 7450, v_aug1),
    (v_user_id, v_cat_savings, 12000, 8000, v_aug1);

  -- ── TRANSACTIONS: JUNE 2025 ──
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date, notes) VALUES
    (v_user_id, v_sub_base, 'June Salary', 55000, 'income', v_jun1, NULL),
    (v_user_id, v_sub_housing, 'House Rent', -12000, 'expense', '2025-06-01', 'Monthly rent'),
    (v_user_id, v_sub_utilities, 'Electricity Bill', -2200, 'expense', '2025-06-05', NULL),
    (v_user_id, v_sub_internet, 'Airtel Fiber', -999, 'expense', '2025-06-03', NULL),
    (v_user_id, v_sub_groceries, 'Big Bazaar Groceries', -3200, 'expense', '2025-06-07', 'Weekly groceries'),
    (v_user_id, v_sub_dining, 'Barbeque Nation', -1800, 'expense', '2025-06-12', 'Dinner with friends'),
    (v_user_id, v_sub_delivery, 'Swiggy Orders', -1450, 'expense', '2025-06-18', NULL),
    (v_user_id, v_sub_entertainment, 'PVR Movie Tickets', -600, 'expense', '2025-06-15', 'Movie night'),
    (v_user_id, v_sub_shopping, 'Myntra Clothes', -2800, 'expense', '2025-06-20', NULL),
    (v_user_id, v_sub_subscriptions, 'Netflix', -649, 'expense', '2025-06-10', NULL),
    (v_user_id, v_sub_subscriptions, 'Spotify', -199, 'expense', '2025-06-10', NULL),
    (v_user_id, v_sub_emergency, 'Emergency Fund', -3000, 'expense', '2025-06-25', NULL),
    (v_user_id, v_sub_investments, 'Mutual Fund SIP', -2500, 'expense', '2025-06-28', NULL),
    (v_user_id, v_sub_maintenance, 'Plumber Visit', -500, 'expense', '2025-06-22', NULL),
    (v_user_id, v_sub_projects, 'Fiverr Project', 8000, 'income', '2025-06-14', 'Website design');

  -- ── TRANSACTIONS: JULY 2025 ──
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date, notes) VALUES
    (v_user_id, v_sub_base, 'July Salary', 58000, 'income', v_jul1, NULL),
    (v_user_id, v_sub_housing, 'House Rent', -12000, 'expense', '2025-07-01', 'Monthly rent'),
    (v_user_id, v_sub_utilities, 'Electricity Bill', -2800, 'expense', '2025-07-05', NULL),
    (v_user_id, v_sub_internet, 'Airtel Fiber', -999, 'expense', '2025-07-03', NULL),
    (v_user_id, v_sub_groceries, 'Reliance Fresh', -3500, 'expense', '2025-07-08', NULL),
    (v_user_id, v_sub_groceries, 'DMart Haul', -2200, 'expense', '2025-07-20', 'Monthly stock-up'),
    (v_user_id, v_sub_dining, 'Cafe Mocha', -850, 'expense', '2025-07-12', NULL),
    (v_user_id, v_sub_delivery, 'Zomato Orders', -1900, 'expense', '2025-07-18', NULL),
    (v_user_id, v_sub_coffee, 'Starbucks', -450, 'expense', '2025-07-15', NULL),
    (v_user_id, v_sub_entertainment, 'Amazon Prime', -1499, 'expense', '2025-07-10', 'Annual subscription'),
    (v_user_id, v_sub_shopping, 'Flipkart Sale', -3500, 'expense', '2025-07-22', 'Electronics'),
    (v_user_id, v_sub_travel, 'Ola Rides', -1200, 'expense', '2025-07-25', NULL),
    (v_user_id, v_sub_subscriptions, 'Netflix', -649, 'expense', '2025-07-10', NULL),
    (v_user_id, v_sub_subscriptions, 'Spotify', -199, 'expense', '2025-07-10', NULL),
    (v_user_id, v_sub_emergency, 'Emergency Fund', -3500, 'expense', '2025-07-26', NULL),
    (v_user_id, v_sub_investments, 'Mutual Fund SIP', -2500, 'expense', '2025-07-28', NULL),
    (v_user_id, v_sub_goals, 'Laptop Fund', -2000, 'expense', '2025-07-30', NULL),
    (v_user_id, v_sub_projects, 'Client Website', 12000, 'income', '2025-07-15', 'Freelance web project');

  -- ── TRANSACTIONS: AUGUST 2025 ──
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date, notes) VALUES
    (v_user_id, v_sub_base, 'August Salary', 58000, 'income', v_aug1, NULL),
    (v_user_id, v_sub_housing, 'House Rent', -12000, 'expense', '2025-08-01', 'Monthly rent'),
    (v_user_id, v_sub_utilities, 'Electricity Bill', -2500, 'expense', '2025-08-05', NULL),
    (v_user_id, v_sub_internet, 'Airtel Fiber', -999, 'expense', '2025-08-03', NULL),
    (v_user_id, v_sub_maintenance, 'AC Service', -800, 'expense', '2025-08-07', NULL),
    (v_user_id, v_sub_groceries, 'Big Bazaar', -2800, 'expense', '2025-08-08', 'Weekly groceries'),
    (v_user_id, v_sub_groceries, 'Zepto Order', -650, 'expense', '2025-08-12', NULL),
    (v_user_id, v_sub_dining, 'Social', -1500, 'expense', '2025-08-14', 'Birthday dinner'),
    (v_user_id, v_sub_dining, 'McDonalds', -380, 'expense', '2025-08-18', NULL),
    (v_user_id, v_sub_delivery, 'Swiggy', -920, 'expense', '2025-08-20', NULL),
    (v_user_id, v_sub_coffee, 'Blue Tokai', -350, 'expense', '2025-08-16', NULL),
    (v_user_id, v_sub_entertainment, 'BookMyShow', -500, 'expense', '2025-08-22', 'Comedy show'),
    (v_user_id, v_sub_shopping, 'Amazon', -1800, 'expense', '2025-08-24', 'Headphones'),
    (v_user_id, v_sub_shopping, 'Decathlon', -2200, 'expense', '2025-08-26', 'Gym gear'),
    (v_user_id, v_sub_travel, 'Uber Rides', -1100, 'expense', '2025-08-19', NULL),
    (v_user_id, v_sub_subscriptions, 'Netflix', -649, 'expense', '2025-08-10', NULL),
    (v_user_id, v_sub_subscriptions, 'Spotify', -199, 'expense', '2025-08-10', NULL),
    (v_user_id, v_sub_emergency, 'Emergency Fund', -4000, 'expense', '2025-08-28', NULL),
    (v_user_id, v_sub_investments, 'Mutual Fund SIP', -2500, 'expense', '2025-08-28', NULL),
    (v_user_id, v_sub_goals, 'Laptop Fund', -1500, 'expense', '2025-08-29', NULL),
    (v_user_id, v_sub_consulting, 'Startup Consulting', 15000, 'income', '2025-08-20', 'Product consulting');

  -- ── SAVINGS GOALS ──
  INSERT INTO public.savings_goals (user_id, name, target, current, icon, deadline) VALUES
    (v_user_id, 'New Laptop', 80000, 32000, '💻', '2025-12-31'),
    (v_user_id, 'Emergency Fund', 200000, 85000, '🏦', '2026-06-30'),
    (v_user_id, 'Goa Trip', 35000, 12000, '🏖️', '2025-12-15');

  -- ── Update profile ──
  INSERT INTO public.profiles (id, full_name)
  VALUES (v_user_id, 'Demo User')
  ON CONFLICT (id) DO UPDATE SET full_name = 'Demo User';

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
