-- ============================================================
-- MIGRATION 012: Fix seed function to work from SQL Editor
-- ============================================================
-- Usage from SQL Editor:
--   SELECT public.seed_demo_data('df7b3acf-3da3-4946-8e8b-f684a9b310db');
-- Or from the app (logged in):
--   SELECT public.seed_demo_data();

CREATE OR REPLACE FUNCTION public.seed_demo_data(p_user_id uuid DEFAULT NULL)
RETURNS void AS $fn$
DECLARE
  v_user_id uuid;
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
  v_sub_overtime uuid;
  v_sub_projects uuid;
  v_sub_consulting uuid;
  v_jun1 date := '2025-06-01';
  v_jul1 date := '2025-07-01';
  v_aug1 date := '2025-08-01';
BEGIN
  -- Use provided user_id, or fall back to auth.uid()
  v_user_id := COALESCE(p_user_id, auth.uid());
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'Not authenticated. Pass user_id as parameter when calling from SQL Editor.'; END IF;
  IF EXISTS (SELECT 1 FROM public.categories WHERE user_id = v_user_id LIMIT 1) THEN RETURN; END IF;

  -- EXPENSE PARENTS
  INSERT INTO public.categories (user_id, name, icon, color, type) VALUES (v_user_id, 'Rent', E'\U0001F3E0', '#202124', 'expense') RETURNING id INTO v_cat_rent;
  INSERT INTO public.categories (user_id, name, icon, color, type) VALUES (v_user_id, 'Food', E'\U0001F354', '#D7F34A', 'expense') RETURNING id INTO v_cat_food;
  INSERT INTO public.categories (user_id, name, icon, color, type) VALUES (v_user_id, 'Fun', E'\U0001F3AE', '#4285F4', 'expense') RETURNING id INTO v_cat_fun;
  INSERT INTO public.categories (user_id, name, icon, color, type) VALUES (v_user_id, 'Savings', E'\U0001F4B0', '#2e7d32', 'expense') RETURNING id INTO v_cat_savings;

  -- RENT SUBS
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Housing', E'\U0001F3E0', '#202124', v_cat_rent, 'expense') RETURNING id INTO v_sub_housing;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Utilities', E'\U0001F4A1', '#f472b6', v_cat_rent, 'expense') RETURNING id INTO v_sub_utilities;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Internet', E'\U0001F310', '#4285F4', v_cat_rent, 'expense') RETURNING id INTO v_sub_internet;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Maintenance', E'\U0001F527', '#795548', v_cat_rent, 'expense') RETURNING id INTO v_sub_maintenance;

  -- FOOD SUBS
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Groceries', E'\U0001F6D2', '#D7F34A', v_cat_food, 'expense') RETURNING id INTO v_sub_groceries;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Dining Out', E'\U0001F37D\uFE0F', '#fb923c', v_cat_food, 'expense') RETURNING id INTO v_sub_dining;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Delivery', E'\U0001F6F5', '#f472b6', v_cat_food, 'expense') RETURNING id INTO v_sub_delivery;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Coffee', E'\u2615', '#795548', v_cat_food, 'expense') RETURNING id INTO v_sub_coffee;

  -- FUN SUBS
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Entertainment', E'\U0001F3AC', '#a78bfa', v_cat_fun, 'expense') RETURNING id INTO v_sub_entertainment;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Shopping', E'\U0001F6CD\uFE0F', '#fb923c', v_cat_fun, 'expense') RETURNING id INTO v_sub_shopping;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Travel', E'\u2708\uFE0F', '#4285F4', v_cat_fun, 'expense') RETURNING id INTO v_sub_travel;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Subscriptions', E'\U0001F4F1', '#f472b6', v_cat_fun, 'expense') RETURNING id INTO v_sub_subscriptions;

  -- SAVINGS SUBS
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Emergency Fund', E'\U0001F3E6', '#2e7d32', v_cat_savings, 'expense') RETURNING id INTO v_sub_emergency;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Investments', E'\U0001F4C8', '#4285F4', v_cat_savings, 'expense') RETURNING id INTO v_sub_investments;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Goals', E'\U0001F3AF', '#D7F34A', v_cat_savings, 'expense') RETURNING id INTO v_sub_goals;

  -- INCOME PARENTS
  INSERT INTO public.categories (user_id, name, icon, color, type) VALUES (v_user_id, 'Salary', E'\U0001F4BC', '#2e7d32', 'income') RETURNING id INTO v_cat_salary;
  INSERT INTO public.categories (user_id, name, icon, color, type) VALUES (v_user_id, 'Freelance', E'\U0001F4BB', '#4285F4', 'income') RETURNING id INTO v_cat_freelance;

  -- SALARY SUBS
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Base Salary', E'\U0001F4B0', '#2e7d32', v_cat_salary, 'income') RETURNING id INTO v_sub_base;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Bonus', E'\U0001F381', '#388e3c', v_cat_salary, 'income') RETURNING id INTO v_sub_bonus;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Overtime', E'\u23F0', '#43a047', v_cat_salary, 'income') RETURNING id INTO v_sub_overtime;

  -- FREELANCE SUBS
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Projects', E'\U0001F4CB', '#4285F4', v_cat_freelance, 'income') RETURNING id INTO v_sub_projects;
  INSERT INTO public.categories (user_id, name, icon, color, parent_id, type) VALUES (v_user_id, 'Consulting', E'\U0001F91D', '#5c9aff', v_cat_freelance, 'income') RETURNING id INTO v_sub_consulting;

  -- BUDGETS (August)
  INSERT INTO public.budgets (user_id, category_id, amount, spent, month) VALUES (v_user_id, v_cat_rent, 20000, 12800, v_aug1);
  INSERT INTO public.budgets (user_id, category_id, amount, spent, month) VALUES (v_user_id, v_cat_food, 8000, 5250, v_aug1);
  INSERT INTO public.budgets (user_id, category_id, amount, spent, month) VALUES (v_user_id, v_cat_fun, 10000, 7450, v_aug1);
  INSERT INTO public.budgets (user_id, category_id, amount, spent, month) VALUES (v_user_id, v_cat_savings, 12000, 8000, v_aug1);

  -- JUNE TRANSACTIONS
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_base, 'June Salary', 55000, 'income', v_jun1);
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_housing, 'House Rent', -12000, 'expense', '2025-06-01');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_utilities, 'Electricity Bill', -2200, 'expense', '2025-06-05');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_internet, 'Airtel Fiber', -999, 'expense', '2025-06-03');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_groceries, 'Big Bazaar Groceries', -3200, 'expense', '2025-06-07');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_dining, 'Barbeque Nation', -1800, 'expense', '2025-06-12');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_delivery, 'Swiggy Orders', -1450, 'expense', '2025-06-18');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_entertainment, 'PVR Movie Tickets', -600, 'expense', '2025-06-15');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_shopping, 'Myntra Clothes', -2800, 'expense', '2025-06-20');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_subscriptions, 'Netflix', -649, 'expense', '2025-06-10');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_subscriptions, 'Spotify', -199, 'expense', '2025-06-10');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_emergency, 'Emergency Fund', -3000, 'expense', '2025-06-25');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_investments, 'Mutual Fund SIP', -2500, 'expense', '2025-06-28');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_maintenance, 'Plumber Visit', -500, 'expense', '2025-06-22');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_projects, 'Fiverr Project', 8000, 'income', '2025-06-14');

  -- JULY TRANSACTIONS
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_base, 'July Salary', 58000, 'income', v_jul1);
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_housing, 'House Rent', -12000, 'expense', '2025-07-01');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_utilities, 'Electricity Bill', -2800, 'expense', '2025-07-05');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_internet, 'Airtel Fiber', -999, 'expense', '2025-07-03');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_groceries, 'Reliance Fresh', -3500, 'expense', '2025-07-08');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_groceries, 'DMart Haul', -2200, 'expense', '2025-07-20');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_dining, 'Cafe Mocha', -850, 'expense', '2025-07-12');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_delivery, 'Zomato Orders', -1900, 'expense', '2025-07-18');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_coffee, 'Starbucks', -450, 'expense', '2025-07-15');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_entertainment, 'Amazon Prime', -1499, 'expense', '2025-07-10');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_shopping, 'Flipkart Sale', -3500, 'expense', '2025-07-22');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_travel, 'Ola Rides', -1200, 'expense', '2025-07-25');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_subscriptions, 'Netflix', -649, 'expense', '2025-07-10');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_subscriptions, 'Spotify', -199, 'expense', '2025-07-10');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_emergency, 'Emergency Fund', -3500, 'expense', '2025-07-26');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_investments, 'Mutual Fund SIP', -2500, 'expense', '2025-07-28');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_goals, 'Laptop Fund', -2000, 'expense', '2025-07-30');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_projects, 'Client Website', 12000, 'income', '2025-07-15');

  -- AUGUST TRANSACTIONS
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_base, 'August Salary', 58000, 'income', v_aug1);
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_housing, 'House Rent', -12000, 'expense', '2025-08-01');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_utilities, 'Electricity Bill', -2500, 'expense', '2025-08-05');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_internet, 'Airtel Fiber', -999, 'expense', '2025-08-03');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_maintenance, 'AC Service', -800, 'expense', '2025-08-07');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_groceries, 'Big Bazaar', -2800, 'expense', '2025-08-08');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_groceries, 'Zepto Order', -650, 'expense', '2025-08-12');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_dining, 'Social', -1500, 'expense', '2025-08-14');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_dining, 'McDonalds', -380, 'expense', '2025-08-18');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_delivery, 'Swiggy', -920, 'expense', '2025-08-20');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_coffee, 'Blue Tokai', -350, 'expense', '2025-08-16');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_entertainment, 'BookMyShow', -500, 'expense', '2025-08-22');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_shopping, 'Amazon', -1800, 'expense', '2025-08-24');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_shopping, 'Decathlon', -2200, 'expense', '2025-08-26');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_travel, 'Uber Rides', -1100, 'expense', '2025-08-19');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_subscriptions, 'Netflix', -649, 'expense', '2025-08-10');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_subscriptions, 'Spotify', -199, 'expense', '2025-08-10');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_emergency, 'Emergency Fund', -4000, 'expense', '2025-08-28');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_investments, 'Mutual Fund SIP', -2500, 'expense', '2025-08-28');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_goals, 'Laptop Fund', -1500, 'expense', '2025-08-29');
  INSERT INTO public.transactions (user_id, category_id, name, amount, type, date) VALUES (v_user_id, v_sub_consulting, 'Startup Consulting', 15000, 'income', '2025-08-20');

  -- SAVINGS GOALS
  INSERT INTO public.savings_goals (user_id, name, target, current, icon, deadline) VALUES (v_user_id, 'New Laptop', 80000, 32000, E'\U0001F4BB', '2025-12-31');
  INSERT INTO public.savings_goals (user_id, name, target, current, icon, deadline) VALUES (v_user_id, 'Emergency Fund', 200000, 85000, E'\U0001F3E6', '2026-06-30');
  INSERT INTO public.savings_goals (user_id, name, target, current, icon, deadline) VALUES (v_user_id, 'Goa Trip', 35000, 12000, E'\U0001F3D6\uFE0F', '2025-12-15');

  -- PROFILE
  INSERT INTO public.profiles (id, full_name) VALUES (v_user_id, 'Demo User') ON CONFLICT (id) DO UPDATE SET full_name = 'Demo User';
END;
$fn$ LANGUAGE plpgsql SECURITY DEFINER;
