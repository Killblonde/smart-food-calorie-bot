-- Smart Food Calorie Bot — Supabase Migration
-- Таблицы для хранения профиля пользователя и дневника питания

-- ============================================
-- 1. Профиль пользователя
-- ============================================
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  telegram_chat_id BIGINT UNIQUE NOT NULL,
  name TEXT DEFAULT 'User',
  height_cm INTEGER,
  weight_kg NUMERIC(5,1),
  age INTEGER,
  activity_level TEXT DEFAULT 'moderate',
  bmr NUMERIC(7,1),
  tdee NUMERIC(7,1),
  target_calories NUMERIC(7,1) DEFAULT 2400,
  target_protein NUMERIC(5,1) DEFAULT 140,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- 2. Дневник питания
-- ============================================
CREATE TABLE IF NOT EXISTS food_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  telegram_chat_id BIGINT NOT NULL,
  meal_description TEXT NOT NULL,
  calories NUMERIC(7,1),
  protein NUMERIC(5,1),
  fat NUMERIC(5,1),
  carbs NUMERIC(5,1),
  meal_type TEXT DEFAULT 'auto',
  source TEXT DEFAULT 'text',
  logged_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Индекс для быстрого поиска по chat_id + дате
CREATE INDEX IF NOT EXISTS idx_food_log_chat_date
  ON food_log (telegram_chat_id, logged_at DESC);

-- ============================================
-- 3. Row Level Security (опционально)
-- ============================================
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE food_log ENABLE ROW LEVEL SECURITY;

-- Политика: service_role имеет полный доступ
CREATE POLICY "Service role full access" ON user_profiles
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Service role full access" ON food_log
  FOR ALL USING (true) WITH CHECK (true);

-- ============================================
-- 4. Шаблон начальных данных (замените на свои)
-- ============================================
-- INSERT INTO user_profiles (telegram_chat_id, name, height_cm, weight_kg, age, target_calories, target_protein, notes)
-- VALUES (
--   000000000,           -- ваш Telegram ID
--   'YOUR_NAME',         -- ваше имя
--   180,                 -- рост в см
--   80.0,                -- вес в кг
--   30,                  -- возраст
--   2400,                -- норма ккал/день
--   140,                 -- норма белка г/день
--   'Заметки о здоровье' -- примечания
-- );
