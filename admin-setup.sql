-- ═══════════════════════════════════════════════════════
-- TaskFlow Pro — إنشاء حساب المدير الجذر
-- نفّذ هذا بعد تسجيل حساب المدير عبر التطبيق
-- ═══════════════════════════════════════════════════════

-- ── الخطوة 1: ترقية مستخدم لمدير ───────────────────────
-- استبدل YOUR_EMAIL بالإيميل الذي سجّلت به

UPDATE public.profiles
SET role = 'admin'
WHERE id = (
  SELECT id FROM auth.users WHERE email = 'YOUR_ADMIN_EMAIL@example.com' LIMIT 1
);

-- ── الخطوة 2: منح XP ابتدائي للمدير ────────────────────
UPDATE public.profiles
SET xp = 1000, streak = 7
WHERE role = 'admin';

-- ── الخطوة 3: التحقق من نجاح العملية ───────────────────
SELECT
  u.email,
  p.username,
  p.role,
  p.xp,
  p.created_at
FROM auth.users u
JOIN public.profiles p ON p.id = u.id
WHERE p.role = 'admin';

-- ── الخطوة 4: عرض لوحة المدير ───────────────────────────
SELECT * FROM public.admin_dashboard ORDER BY total_tasks DESC;

-- ══════════════════════════════════════════
-- دالة مساعدة: ترقية مستخدم لمدير من داخل التطبيق
-- ══════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.promote_to_admin(target_email TEXT)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_caller_role TEXT;
  v_target_id   UUID;
BEGIN
  -- التحقق أن الداعي هو مدير
  SELECT role INTO v_caller_role FROM profiles WHERE id = auth.uid();
  IF v_caller_role <> 'admin' THEN
    RETURN 'خطأ: صلاحيات غير كافية';
  END IF;
  -- إيجاد المستخدم المستهدف
  SELECT id INTO v_target_id FROM auth.users WHERE email = target_email;
  IF v_target_id IS NULL THEN
    RETURN 'خطأ: المستخدم غير موجود';
  END IF;
  -- الترقية
  UPDATE profiles SET role = 'admin' WHERE id = v_target_id;
  RETURN 'تم ترقية ' || target_email || ' لمدير بنجاح ✓';
END;
$$;
