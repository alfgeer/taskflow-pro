-- ═══════════════════════════════════════════════════════
-- TaskFlow Pro — Supabase Database Schema
-- قاعدة البيانات الكاملة لتطبيق TaskFlow Pro
-- ═══════════════════════════════════════════════════════

-- ── 1. تفعيل UUID extension ─────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ══════════════════════════════════════════
-- 📋 جدول المهام
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.tasks (
  id           UUID         PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID         NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  text         TEXT         NOT NULL CHECK (char_length(text) BETWEEN 1 AND 500),
  priority     TEXT         NOT NULL DEFAULT 'medium' CHECK (priority IN ('high','medium','low')),
  category     TEXT         NOT NULL DEFAULT 'أخرى',
  done         BOOLEAN      NOT NULL DEFAULT FALSE,
  due_date     DATE,
  due_time     TIME,
  is_important BOOLEAN      NOT NULL DEFAULT FALSE,
  is_mit       BOOLEAN      NOT NULL DEFAULT FALSE,
  xp_value     SMALLINT     NOT NULL DEFAULT 20 CHECK (xp_value >= 0),
  est_minutes  SMALLINT     CHECK (est_minutes > 0),
  act_seconds  INT          NOT NULL DEFAULT 0,
  completed_at TIMESTAMPTZ,
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  sort_order   INT          NOT NULL DEFAULT 0
);

-- ══════════════════════════════════════════
-- 📝 جدول المهام الفرعية
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.subtasks (
  id        UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id   UUID        NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  user_id   UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  text      TEXT        NOT NULL CHECK (char_length(text) BETWEEN 1 AND 300),
  done      BOOLEAN     NOT NULL DEFAULT FALSE,
  sort_order INT        NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ══════════════════════════════════════════
-- 👤 جدول ملفات المستخدمين
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.profiles (
  id          UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username    TEXT        UNIQUE CHECK (char_length(username) BETWEEN 2 AND 50),
  full_name   TEXT        CHECK (char_length(full_name) <= 100),
  role        TEXT        NOT NULL DEFAULT 'user' CHECK (role IN ('admin','user')),
  xp          INT         NOT NULL DEFAULT 0 CHECK (xp >= 0),
  streak      SMALLINT    NOT NULL DEFAULT 0 CHECK (streak >= 0),
  theme       TEXT        NOT NULL DEFAULT 'dark' CHECK (theme IN ('dark','desert','ocean','light')),
  energy      TEXT        NOT NULL DEFAULT 'med' CHECK (energy IN ('low','med','hi')),
  notif_enabled BOOLEAN   NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ══════════════════════════════════════════
-- 📊 جدول إحصائيات اليومية
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.daily_stats (
  id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  stat_date   DATE        NOT NULL DEFAULT CURRENT_DATE,
  tasks_done  SMALLINT    NOT NULL DEFAULT 0 CHECK (tasks_done >= 0),
  xp_earned   INT         NOT NULL DEFAULT 0 CHECK (xp_earned >= 0),
  focus_mins  INT         NOT NULL DEFAULT 0 CHECK (focus_mins >= 0),
  UNIQUE (user_id, stat_date)
);

-- ══════════════════════════════════════════
-- 📅 جدول المراجعات الأسبوعية
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.weekly_reviews (
  id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start   DATE        NOT NULL,
  tasks_done   SMALLINT    NOT NULL DEFAULT 0,
  tasks_missed SMALLINT    NOT NULL DEFAULT 0,
  goals        JSONB       DEFAULT '[]',
  notes        TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, week_start)
);

-- ══════════════════════════════════════════
-- 📢 جدول الإشعارات المجدولة
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.notifications (
  id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  task_id      UUID        REFERENCES public.tasks(id) ON DELETE CASCADE,
  title        TEXT        NOT NULL,
  body         TEXT,
  scheduled_at TIMESTAMPTZ NOT NULL,
  sent         BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ══════════════════════════════════════════
-- ⚙️ جدول الإعدادات العامة (للمدير)
-- ══════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.app_settings (
  key         TEXT  PRIMARY KEY,
  value       JSONB NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by  UUID  REFERENCES auth.users(id)
);

-- ══════════════════════════════════════════
-- 📑 INDEXES للأداء
-- ══════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_tasks_user_id     ON public.tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_done        ON public.tasks(user_id, done);
CREATE INDEX IF NOT EXISTS idx_tasks_due         ON public.tasks(due_date) WHERE due_date IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_priority    ON public.tasks(user_id, priority);
CREATE INDEX IF NOT EXISTS idx_tasks_created     ON public.tasks(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_subtasks_task     ON public.subtasks(task_id);
CREATE INDEX IF NOT EXISTS idx_daily_stats_date  ON public.daily_stats(user_id, stat_date DESC);
CREATE INDEX IF NOT EXISTS idx_notifs_scheduled  ON public.notifications(scheduled_at) WHERE sent = FALSE;

-- ══════════════════════════════════════════
-- 🔄 FUNCTIONS & TRIGGERS
-- ══════════════════════════════════════════

-- تحديث updated_at تلقائياً
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER tasks_updated_at
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- إنشاء ملف مستخدم تلقائياً عند التسجيل
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, username, full_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'user')
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- تحديث إحصائيات اليوم عند إنجاز مهمة
CREATE OR REPLACE FUNCTION public.handle_task_completed()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.done = TRUE AND OLD.done = FALSE THEN
    -- تحديث XP في الملف الشخصي
    UPDATE public.profiles
    SET xp = xp + NEW.xp_value
    WHERE id = NEW.user_id;
    -- تحديث إحصائيات اليوم
    INSERT INTO public.daily_stats (user_id, stat_date, tasks_done, xp_earned)
    VALUES (NEW.user_id, CURRENT_DATE, 1, NEW.xp_value)
    ON CONFLICT (user_id, stat_date)
    DO UPDATE SET
      tasks_done = daily_stats.tasks_done + 1,
      xp_earned  = daily_stats.xp_earned + NEW.xp_value;
  END IF;
  IF NEW.done = FALSE AND OLD.done = TRUE THEN
    UPDATE public.profiles SET xp = GREATEST(0, xp - OLD.xp_value) WHERE id = NEW.user_id;
    UPDATE public.daily_stats
    SET tasks_done = GREATEST(0, tasks_done - 1), xp_earned = GREATEST(0, xp_earned - OLD.xp_value)
    WHERE user_id = NEW.user_id AND stat_date = CURRENT_DATE;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_task_completed
  AFTER UPDATE OF done ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION public.handle_task_completed();

-- ══════════════════════════════════════════
-- 🔐 Row Level Security (RLS)
-- ══════════════════════════════════════════

ALTER TABLE public.tasks           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subtasks        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_stats     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weekly_reviews  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings    ENABLE ROW LEVEL SECURITY;

-- سياسات المهام
CREATE POLICY "tasks: user owns" ON public.tasks
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "tasks: admin sees all" ON public.tasks
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- سياسات المهام الفرعية
CREATE POLICY "subtasks: user owns" ON public.subtasks
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- سياسات الملفات الشخصية
CREATE POLICY "profiles: own profile" ON public.profiles
  FOR ALL USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles: admin reads all" ON public.profiles
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- سياسات الإحصائيات
CREATE POLICY "stats: user owns" ON public.daily_stats
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- سياسات المراجعات
CREATE POLICY "reviews: user owns" ON public.weekly_reviews
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- سياسات الإشعارات
CREATE POLICY "notifs: user owns" ON public.notifications
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- سياسات إعدادات التطبيق (المدير فقط)
CREATE POLICY "app_settings: admin only" ON public.app_settings
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ══════════════════════════════════════════
-- 🛠️ VIEWS مفيدة
-- ══════════════════════════════════════════

-- عرض المهام مع المهام الفرعية
CREATE OR REPLACE VIEW public.tasks_with_subtasks AS
SELECT
  t.*,
  COALESCE(
    json_agg(
      json_build_object('id',s.id,'text',s.text,'done',s.done,'sort_order',s.sort_order)
      ORDER BY s.sort_order
    ) FILTER (WHERE s.id IS NOT NULL),
    '[]'
  ) AS subtasks_json,
  COUNT(s.id) FILTER (WHERE s.id IS NOT NULL) AS subtasks_total,
  COUNT(s.id) FILTER (WHERE s.done = TRUE) AS subtasks_done
FROM public.tasks t
LEFT JOIN public.subtasks s ON s.task_id = t.id
GROUP BY t.id;

-- عرض لوحة المدير
CREATE OR REPLACE VIEW public.admin_dashboard AS
SELECT
  p.id,
  p.username,
  p.full_name,
  p.role,
  p.xp,
  p.streak,
  p.created_at,
  COUNT(t.id) AS total_tasks,
  COUNT(t.id) FILTER (WHERE t.done = TRUE) AS done_tasks,
  COUNT(t.id) FILTER (WHERE t.done = FALSE) AS pending_tasks
FROM public.profiles p
LEFT JOIN public.tasks t ON t.user_id = p.id
GROUP BY p.id, p.username, p.full_name, p.role, p.xp, p.streak, p.created_at;

-- ══════════════════════════════════════════
-- ⚡ إعدادات أولية للتطبيق
-- ══════════════════════════════════════════
INSERT INTO public.app_settings (key, value) VALUES
  ('app_version',   '"2.0.0"'),
  ('max_tasks',     '500'),
  ('maintenance',   'false'),
  ('features',      '{"pwa":true,"offline":true,"analytics":true,"voice":true}')
ON CONFLICT (key) DO NOTHING;

-- ══════════════════════════════════════════
-- ✅ نهاية Schema
-- ══════════════════════════════════════════
