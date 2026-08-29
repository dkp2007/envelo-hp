create or replace function public.seed_dashboard_data()
returns void as $$
declare
  v_user_id uuid;
  v_rent_id uuid;
  v_food_id uuid;
  v_fun_id uuid;
  v_savings_id uuid;
begin
  v_user_id := auth.uid();

  insert into public.categories (user_id, name, icon, color)
  values
    (v_user_id, 'Rent', '🏠', '#202124')
  returning id into v_rent_id;

  insert into public.categories (user_id, name, icon, color, parent_id)
  values
    (v_user_id, 'Housing', '🏢', '#202124', v_rent_id),
    (v_user_id, 'Utilities', '💡', '#555555', v_rent_id),
    (v_user_id, 'Internet', '📶', '#777777', v_rent_id),
    (v_user_id, 'Maintenance', '🔧', '#999999', v_rent_id);

  insert into public.categories (user_id, name, icon, color)
  values
    (v_user_id, 'Food', '🍔', '#D7F34A')
  returning id into v_food_id;

  insert into public.categories (user_id, name, icon, color, parent_id)
  values
    (v_user_id, 'Groceries', '🛒', '#D7F34A', v_food_id),
    (v_user_id, 'Dining Out', '🍽️', '#c4de3e', v_food_id),
    (v_user_id, 'Delivery', '🛵', '#b0c935', v_food_id),
    (v_user_id, 'Coffee', '☕', '#9ab82d', v_food_id);

  insert into public.categories (user_id, name, icon, color)
  values
    (v_user_id, 'Fun', '🎮', '#4285F4')
  returning id into v_fun_id;

  insert into public.categories (user_id, name, icon, color, parent_id)
  values
    (v_user_id, 'Entertainment', '🎬', '#4285F4', v_fun_id),
    (v_user_id, 'Shopping', '🛍️', '#9c27b0', v_fun_id),
    (v_user_id, 'Travel', '✈️', '#e91e63', v_fun_id),
    (v_user_id, 'Subscriptions', '📱', '#ff9800', v_fun_id);

  insert into public.categories (user_id, name, icon, color)
  values
    (v_user_id, 'Savings', '💰', '#2e7d32')
  returning id into v_savings_id;

  insert into public.categories (user_id, name, icon, color, parent_id)
  values
    (v_user_id, 'Emergency Fund', '🛡️', '#2e7d32', v_savings_id),
    (v_user_id, 'Investments', '📈', '#388e3c', v_savings_id),
    (v_user_id, 'Goals', '🎯', '#43a047', v_savings_id);

  insert into public.budgets (user_id, category_id, amount, spent, month)
  values
    (v_user_id, v_rent_id, 20000, 12000, '2025-08-01'),
    (v_user_id, v_food_id, 5000, 2750, '2025-08-01'),
    (v_user_id, v_fun_id, 8000, 4250, '2025-08-01'),
    (v_user_id, v_savings_id, 12000, 8000, '2025-08-01');

  insert into public.transactions (user_id, category_id, name, amount, type, date)
  values
    (v_user_id, null, 'Salary', 50000, 'income', '2025-08-01'),
    (v_user_id, v_rent_id, 'Electricity Bill', -1200, 'expense', '2025-08-20'),
    (v_user_id, v_food_id, 'Swiggy', -450, 'expense', '2025-08-28'),
    (v_user_id, v_food_id, 'Groceries', -850, 'expense', '2025-08-24'),
    (v_user_id, v_fun_id, 'Movie Tickets', -350, 'expense', '2025-08-25'),
    (v_user_id, v_fun_id, 'Amazon', -1200, 'expense', '2025-08-28'),
    (v_user_id, v_fun_id, 'Uber', -180, 'expense', '2025-08-27'),
    (v_user_id, null, 'Freelance', 8000, 'income', '2025-08-15');

  insert into public.savings_goals (user_id, name, target, current, icon, deadline)
  values
    (v_user_id, 'New Laptop', 80000, 32000, '💻', '2025-12-31'),
    (v_user_id, 'Emergency Fund', 100000, 45000, '🛡️', '2026-06-30'),
    (v_user_id, 'Vacation', 50000, 12000, '✈️', '2026-03-15');
end;
$$ language plpgsql security definer;
