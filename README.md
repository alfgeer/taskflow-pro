# 🚀 TaskFlow Pro — دليل النشر الكامل

> تطبيق PWA احترافي مدعوم بقاعدة بيانات Supabase حقيقية، منشور على GitHub ومرتبط بـ Netlify

---

## 📁 هيكل المشروع

```
taskflow-full/
├── public/              ← ملفات التطبيق (تُنشر على Netlify)
│   ├── index.html       ← التطبيق الكامل
│   ├── sw.js            ← Service Worker (Offline)
│   ├── manifest.json    ← إعدادات PWA
│   └── *.png            ← الأيقونات
├── supabase/
│   ├── schema.sql       ← قاعدة البيانات الكاملة
│   └── admin-setup.sql  ← إنشاء حساب المدير
├── netlify.toml         ← إعدادات Netlify
├── .gitignore
└── README.md
```

---

## ═══════════════════════════════════════
## الخطوة 1 — إنشاء قاعدة بيانات Supabase
## ═══════════════════════════════════════

### 1.1 إنشاء مشروع Supabase

1. افتح **https://supabase.com** وسجّل حساباً مجانياً
2. اضغط **"New Project"**
3. اختر اسماً للمشروع مثل: `taskflow-pro`
4. اختر كلمة مرور قوية لقاعدة البيانات — **احفظها جيداً**
5. اختر المنطقة الأقرب لك (مثل: `Central EU` أو `US East`)
6. انتظر دقيقة حتى ينشئ Supabase المشروع

### 1.2 تشغيل Schema قاعدة البيانات

1. في لوحة Supabase، اضغط **"SQL Editor"** من القائمة الجانبية
2. اضغط **"New query"**
3. افتح ملف `supabase/schema.sql` من هذا المشروع
4. انسخ كامل المحتوى والصقه في محرر SQL
5. اضغط **"RUN"** (أو Ctrl+Enter)
6. انتظر رسالة: `Success. No rows returned` ✅

### 1.3 تفعيل Google Auth (اختياري)

1. في Supabase → **Authentication** → **Providers**
2. فعّل **Google**
3. أنشئ مشروع في https://console.cloud.google.com
4. أضف OAuth credentials وأدخل Client ID و Client Secret

### 1.4 الحصول على مفاتيح API

1. في Supabase → **Project Settings** → **API**
2. انسخ:
   - **Project URL**: `https://xxxxxxxxxx.supabase.co`
   - **anon public key**: `eyJhbGciOiJIUzI1NiIs...`

> ⚠️ لا تشارك `service_role` key أبداً — هذا للخادم فقط

---

## ═══════════════════════════════════════
## الخطوة 2 — إعداد مشروع GitHub
## ═══════════════════════════════════════

### 2.1 إنشاء حساب GitHub (إذا لم يكن لديك)

1. افتح **https://github.com** وأنشئ حساباً
2. تحقق من بريدك الإلكتروني

### 2.2 إنشاء مستودع جديد

1. اضغط **"+"** ثم **"New repository"**
2. اسم المستودع: `taskflow-pro`
3. اجعله **Public** (مجاني مع Netlify)
4. **لا تضف** README أو .gitignore (الملفات موجودة)
5. اضغط **"Create repository"**

### 2.3 رفع الملفات بـ GitHub Desktop (الأسهل)

#### تثبيت GitHub Desktop:
1. افتح **https://desktop.github.com** وحمّل التطبيق
2. سجّل دخولك بحساب GitHub

#### رفع الملفات:
1. افتح GitHub Desktop
2. اضغط **"Add an Existing Repository from your Hard Drive"**
3. أو: File → Add local repository
4. اختر مجلد `taskflow-full`
5. إذا لم يتعرف عليه، اضغط **"create a repository here"**
6. في حقل **"Summary"** اكتب: `First commit — TaskFlow Pro v2`
7. اضغط **"Commit to main"**
8. اضغط **"Publish repository"**
9. اختر اسم: `taskflow-pro`
10. اضغط **"Publish Repository"** ✅

### أو بالـ Terminal (للمتقدمين):

```bash
cd /مسار/taskflow-full
git init
git add .
git commit -m "🚀 TaskFlow Pro v2 — Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/taskflow-pro.git
git push -u origin main
```

---

## ═══════════════════════════════════════
## الخطوة 3 — ربط GitHub بـ Netlify
## ═══════════════════════════════════════

### 3.1 إنشاء حساب Netlify

1. افتح **https://netlify.com**
2. اضغط **"Sign up"** → اختر **"Sign up with GitHub"**
3. سجّل الدخول بحسابك على GitHub ومنح الصلاحيات

### 3.2 إنشاء موقع جديد

1. في لوحة Netlify اضغط **"Add new site"**
2. اختر **"Import an existing project"**
3. اختر **"Deploy with GitHub"**
4. ابحث عن `taskflow-pro` واختره

### 3.3 إعداد Build Settings

| الحقل | القيمة |
|-------|---------|
| Branch to deploy | `main` |
| Base directory | *(فارغ)* |
| Build command | *(فارغ)* |
| Publish directory | `public` |

اضغط **"Deploy site"** ✅

### 3.4 إضافة متغيرات البيئة (Environment Variables)

هذه الخطوة تحمي مفاتيح API:

1. في Netlify → **Site settings** → **Environment variables**
2. اضغط **"Add a variable"** وأضف:

| Key | Value |
|-----|-------|
| `SUPABASE_URL` | `https://xxxxxxxxxx.supabase.co` |
| `SUPABASE_ANON` | `eyJhbGciOiJIUzI1NiIs...` |

3. اضغط **"Save"**

### 3.5 تفعيل المتغيرات في التطبيق

افتح `public/index.html`، ابحث عن هذا السطر:

```javascript
const SUPABASE_URL  = window.__ENV__?.SUPABASE_URL  || 'https://YOUR_PROJECT.supabase.co';
const SUPABASE_ANON = window.__ENV__?.SUPABASE_ANON || 'YOUR_ANON_KEY';
```

**الخيار الأسهل** — استبدل مباشرة:
```javascript
const SUPABASE_URL  = 'https://xxxxxxxxxx.supabase.co';  // ← ضع URL مشروعك
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIs...';         // ← ضع مفتاحك
```

احفظ وارفع التحديث:
```bash
git add .
git commit -m "🔑 Add Supabase credentials"
git push
```
Netlify يُعيد النشر تلقائياً خلال 30 ثانية ✅

---

## ═══════════════════════════════════════
## الخطوة 4 — إنشاء حساب المدير الجذر
## ═══════════════════════════════════════

### 4.1 إنشاء الحساب

1. افتح رابط تطبيقك على Netlify (مثل: `https://taskflow-pro.netlify.app`)
2. اضغط **"إنشاء حساب"**
3. أدخل:
   - البريد الإلكتروني: بريدك الخاص
   - كلمة المرور: قوية (8+ أحرف، أرقام، رموز)
   - الاسم الكامل: اسمك
4. اضغط **"إنشاء حساب"**

### 4.2 ترقية الحساب لمدير

1. ارجع لـ **Supabase → SQL Editor**
2. أنشئ Query جديدة والصق:

```sql
UPDATE public.profiles
SET role = 'admin', xp = 500, streak = 7
WHERE id = (
  SELECT id FROM auth.users
  WHERE email = 'YOUR_EMAIL@example.com'   -- ← غيّر هذا
  LIMIT 1
);

-- تحقق من النجاح
SELECT u.email, p.role, p.xp
FROM auth.users u
JOIN public.profiles p ON p.id = u.id
WHERE p.role = 'admin';
```

3. اضغط **RUN** — يجب أن يظهر بريدك مع `role = admin` ✅

### 4.3 صلاحيات المدير في التطبيق

بعد تسجيل الدخول كمدير ستجد في تبويب **تحليل**:
- 👑 لوحة المدير مع قائمة كل المستخدمين
- عدد مهام كل مستخدم، XP، التاريخ
- إحصائيات شاملة للتطبيق

---

## ═══════════════════════════════════════
## الخطوة 5 — تثبيت التطبيق على آيفونك
## ═══════════════════════════════════════

1. افتح رابط Netlify في **Safari**
2. اضغط زر المشاركة **↑**
3. اختر **"إضافة إلى الشاشة الرئيسية"**
4. اضغط **"إضافة"**
5. ستجد أيقونة TaskFlow Pro على شاشتك 📱

---

## ═══════════════════════════════════════
## إعداد Custom Domain (اختياري)
## ═══════════════════════════════════════

1. في Netlify → **Domain settings** → **Add custom domain**
2. أدخل نطاقك مثل: `taskflow.yourdomain.com`
3. أضف CNAME record في مزود النطاق يشير لـ Netlify
4. Netlify يُفعّل SSL تلقائياً (HTTPS مجاني) ✅

---

## 🔒 الأمان والخصوصية

| الميزة | التفاصيل |
|--------|----------|
| Row Level Security | كل مستخدم يرى بياناته فقط |
| HTTPS | مفعّل تلقائياً عبر Netlify |
| JWT Auth | Supabase يصدر tokens آمنة |
| Password Hashing | bcrypt مدمج في Supabase |
| Admin RLS | المدير فقط يرى بيانات المستخدمين |

---

## 🆘 حل المشاكل الشائعة

**❌ "Invalid API Key"**
← تحقق من SUPABASE_URL و SUPABASE_ANON في الكود

**❌ "Row Level Security violation"**
← تأكد من تشغيل schema.sql كاملاً

**❌ التطبيق لا يُحدَّث على Netlify**
← Deploys → Trigger deploy → Clear cache and deploy site

**❌ "User not found" عند ترقية المدير**
← تأكد من تسجيل الحساب أولاً في التطبيق قبل تشغيل SQL

---

## 📞 تقنيات المشروع

| التقنية | الدور |
|---------|-------|
| **Supabase** | قاعدة بيانات PostgreSQL + Auth + Realtime |
| **Netlify** | استضافة + CI/CD + CDN عالمي |
| **GitHub** | إدارة الكود + Version Control |
| **PWA** | تطبيق قابل للتثبيت على iOS/Android |
| **Service Worker** | عمل Offline كامل |

---

*TaskFlow Pro v2.0 — بُني بـ ❤️*
