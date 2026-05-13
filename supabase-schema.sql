-- =====================================================
-- LeadHub — Supabase schema (idempotent)
-- Chạy lại bao nhiêu lần cũng OK, không reset data.
-- =====================================================

-- 5.1 USERS
CREATE TABLE IF NOT EXISTS users (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pin         text UNIQUE NOT NULL,                 -- '1001', '1002'...
  full_name   text NOT NULL,
  role        text NOT NULL,                        -- 'lead_pm' | 'lead_tech' | ...
  area        text NOT NULL,                        -- 'pm' | 'tech' | 'content' | 'ops'
  color       text DEFAULT '#3B82F6',
  is_active   boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- 5.2 PROJECTS
CREATE TABLE IF NOT EXISTS projects (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL,
  description text,
  start_at    date,
  end_at      date,
  is_archived boolean NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- 5.3 GOALS (mục tiêu / milestone)
CREATE TABLE IF NOT EXISTS goals (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id  uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  title       text NOT NULL,
  description text,
  area        text NOT NULL,
  due_at      date,
  status      text NOT NULL DEFAULT 'open',         -- open | done | dropped
  sort_order  int  NOT NULL DEFAULT 0,
  created_by  uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- 5.4 TASKS
CREATE TABLE IF NOT EXISTS tasks (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id   uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  goal_id      uuid REFERENCES goals(id) ON DELETE SET NULL,
  title        text NOT NULL,
  description  text,
  status       text NOT NULL DEFAULT 'todo',        -- backlog | todo | doing | review | done
  priority     text NOT NULL DEFAULT 'normal',      -- low | normal | high | urgent
  area         text NOT NULL,                       -- pm | tech | content | ops
  assignee_id  uuid REFERENCES users(id) ON DELETE SET NULL,
  created_by   uuid REFERENCES users(id) ON DELETE SET NULL,
  start_at     date,
  due_at       date,
  done_at      timestamptz,
  checklist    jsonb NOT NULL DEFAULT '[]'::jsonb,
  tags         jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order   int  NOT NULL DEFAULT 0,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tasks_status   ON tasks(status);
CREATE INDEX IF NOT EXISTS idx_tasks_assignee ON tasks(assignee_id);
CREATE INDEX IF NOT EXISTS idx_tasks_due      ON tasks(due_at);
CREATE INDEX IF NOT EXISTS idx_tasks_goal     ON tasks(goal_id);

-- 5.5 ACTIVITIES (audit log nhẹ + comments)
CREATE TABLE IF NOT EXISTS activities (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id     uuid REFERENCES tasks(id) ON DELETE CASCADE,
  user_id     uuid REFERENCES users(id) ON DELETE SET NULL,
  kind        text NOT NULL,                       -- 'comment' | 'status_change' | 'assigned' | 'created' | 'edited'
  payload     jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_activities_task ON activities(task_id, created_at DESC);

-- =====================================================
-- RLS open_all (internal app)
-- =====================================================
ALTER TABLE users      ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects   ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals      ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks      ENABLE ROW LEVEL SECURITY;
ALTER TABLE activities ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  DROP POLICY IF EXISTS "open_all" ON users;      CREATE POLICY "open_all" ON users      FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
  DROP POLICY IF EXISTS "open_all" ON projects;   CREATE POLICY "open_all" ON projects   FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
  DROP POLICY IF EXISTS "open_all" ON goals;      CREATE POLICY "open_all" ON goals      FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
  DROP POLICY IF EXISTS "open_all" ON tasks;      CREATE POLICY "open_all" ON tasks      FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
  DROP POLICY IF EXISTS "open_all" ON activities; CREATE POLICY "open_all" ON activities FOR ALL TO anon, authenticated USING (true) WITH CHECK (true);
END $$;

-- =====================================================
-- Realtime publication
-- =====================================================
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE tasks;      EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE goals;      EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE activities; EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE users;      EXCEPTION WHEN duplicate_object THEN NULL; END $$;
-- projects ít đổi → không enable realtime

-- =====================================================
-- Seed (chỉ khi rỗng)
-- =====================================================
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM users) THEN
    INSERT INTO users (pin, full_name, role, area, color) VALUES
      ('1001', 'Leader A',     'lead_pm',     'pm',      '#7C3AED'),
      ('1002', 'Leader B',     'lead_tech',   'tech',    '#1D4ED8'),
      ('1003', 'Sub-leader C', 'sub_content', 'content', '#16A34A'),
      ('1004', 'Sub-leader D', 'sub_ops',     'ops',     '#EA580C');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM projects) THEN
    INSERT INTO projects (name, description, start_at, end_at)
    VALUES ('Dự án Demo', 'Project khởi tạo mặc định — đổi tên trong Settings.', CURRENT_DATE, CURRENT_DATE + INTERVAL '90 days');
  END IF;
END $$;

DO $$
DECLARE
  pid uuid; gid1 uuid; gid2 uuid;
  u_pm uuid; u_tech uuid; u_content uuid; u_ops uuid;
BEGIN
  SELECT id INTO pid FROM projects LIMIT 1;
  SELECT id INTO u_pm      FROM users WHERE pin='1001';
  SELECT id INTO u_tech    FROM users WHERE pin='1002';
  SELECT id INTO u_content FROM users WHERE pin='1003';
  SELECT id INTO u_ops     FROM users WHERE pin='1004';

  IF NOT EXISTS (SELECT 1 FROM goals) THEN
    INSERT INTO goals (project_id, title, area, due_at, created_by, sort_order)
    VALUES (pid, 'Mốc 1 — Hoàn thiện sản phẩm v1', 'tech', CURRENT_DATE + 30, u_pm, 1)
    RETURNING id INTO gid1;

    INSERT INTO goals (project_id, title, area, due_at, created_by, sort_order)
    VALUES (pid, 'Mốc 2 — Ra mắt và truyền thông', 'content', CURRENT_DATE + 60, u_pm, 2)
    RETURNING id INTO gid2;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM tasks) THEN
    INSERT INTO tasks (project_id, goal_id, title, status, priority, area, assignee_id, created_by, start_at, due_at) VALUES
      (pid, gid1, 'Thiết kế kiến trúc hệ thống',     'doing',   'high',   'tech',    u_tech,    u_pm, CURRENT_DATE,        CURRENT_DATE + 7),
      (pid, gid1, 'Code module auth',                'todo',    'high',   'tech',    u_tech,    u_pm, CURRENT_DATE + 3,    CURRENT_DATE + 14),
      (pid, gid2, 'Lập kế hoạch nội dung tuần 1-4',  'todo',    'normal', 'content', u_content, u_pm, CURRENT_DATE + 7,    CURRENT_DATE + 21),
      (pid, gid2, 'Booking địa điểm ra mắt',         'backlog', 'normal', 'ops',     u_ops,     u_pm, CURRENT_DATE + 30,   CURRENT_DATE + 45),
      (pid, NULL, 'Họp kick-off team',               'done',    'high',   'pm',      u_pm,      u_pm, CURRENT_DATE - 2,    CURRENT_DATE - 1),
      (pid, NULL, 'Lên timeline tổng',               'review',  'normal', 'pm',      u_pm,      u_pm, CURRENT_DATE - 1,    CURRENT_DATE + 2);
  END IF;
END $$;
