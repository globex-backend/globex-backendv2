# Globex Decision OS — Deployment Guide for Mr. Meftah

## Files in This Package

| File | What it is | What you do with it |
|------|-----------|---------------------|
| `Schema.sql` | Creates all 16 database tables | Run in Supabase SQL Editor |
| `02_agents_seed.sql` | Seeds the agent army | Run in Supabase SQL Editor |
| `05_causal_seed.sql` | Seeds the safety-belt causal chains | Run in Supabase SQL Editor |
| `tick_index.ts` | Main decision engine (Edge Function) | Upload to Supabase as function `tick` |
| `causal_engine_index.ts` | Causal chain engine (Edge Function) | Upload to Supabase as function `causal_engine` |
| `rule_engine.ts` | Generic rule interpreter (shared) | Place in `supabase/_shared/` folder |
| `metric_engine.ts` | Generic metric calculator (shared) | Place in `supabase/_shared/` folder |
| `db.ts` | Database connection helper (shared) | Place in `supabase/_shared/` folder |

---

## Step-by-Step Deployment (Staging First — Always)

### STEP 1 — Run the Schema (creates all tables)
1. Go to your **Supabase staging project**
2. Click **SQL Editor** → **New query**
3. Open `Schema.sql` from this package → copy all contents → paste → click **Run**
4. Expected result at the bottom: `Success. No rows returned`
5. Click **Table Editor** on the left → you should see exactly **16 tables**:
   `entity, relation, org_user, event, insight, request, agent, agent_action,`
   `commission, rule, metric_def, metric_value, dashboard_block, causal_link,`
   `causal_rule, audit_log`
6. ⛔ If you see a red error — STOP. Copy the error text and send it to the chat.

---

### STEP 2 — Seed the Agents
1. SQL Editor → **New query**
2. Open `02_agents_seed.sql` → copy all → paste → Run
3. Expected: `Success`
4. Check: Table Editor → `agent` table → should have **19 rows**

---

### STEP 3 — Seed the Causal Chains
1. SQL Editor → **New query**
2. Open `05_causal_seed.sql` → copy **only the top section** (stop before the `/*` comment block) → paste → Run
3. Expected: `Success`
4. Check: Table Editor → `causal_rule` table → should have **10 rows**

---

### STEP 4 — Set Up the GitHub Folder Structure
In your GitHub repo (`globex-backend/lobex-backendv2`), create this folder structure and upload the files:

```
supabase/
├── _shared/
│   ├── db.ts                ← upload db.ts from this package
│   ├── rule_engine.ts       ← upload rule_engine.ts from this package
│   └── metric_engine.ts     ← upload metric_engine.ts from this package
└── functions/
    ├── tick/
    │   └── index.ts         ← upload tick_index.ts, rename it to index.ts
    └── causal_engine/
        └── index.ts         ← upload causal_engine_index.ts, rename it to index.ts
```

---

### STEP 5 — Deploy the Edge Functions (Terminal)
Open a terminal in the repo folder and run:

```bash
supabase link --project-ref YOUR_STAGING_REF
supabase functions deploy tick
supabase functions deploy causal_engine
```

> Your staging `project-ref` is found in: Supabase panel → Settings → General → **Reference ID**

Each command should respond with: `Deployed Function ...`
If you get an error, copy it and send to the chat.

---

### STEP 6 — Set the Secret Keys (Never in code — only here)
In Supabase panel → **Project Settings** → **Edge Functions** → **Secrets** → Add new secret:

| Secret Name | Where to find the value |
|-------------|------------------------|
| `SUPABASE_URL` | Settings → API → Project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Settings → API → service_role key (keep secret!) |

⚠️ Never paste these keys into chat, code files, or GitHub.

---

### STEP 7 — Test the Brain (Verify It Works)
1. SQL Editor → **New query** → open `05_causal_seed.sql` again
2. Find the block between `/*` and `*/` at the bottom — copy just that block (without the `/*` and `*/`) → paste → Run
3. This inserts one test deal entity + one rule + one event
4. Go to **Edge Functions** → click `tick` → click **Invoke**
5. ✅ **Pass:** Go to Table Editor → `insight` table → you should see **1 row** with headline: `Deal silent — follow up now`
6. ⛔ **Fail:** If insight table is empty or you see an error — copy it and send to chat

---

### STEP 8 — Set Up Automatic Scheduling (Cron Jobs)
In Supabase panel → **Database** → **Cron Jobs** → **Create job** (twice):

**Job 1 — Decision engine (every 10 minutes):**
- Name: `tick-every-10min`
- Schedule: `*/10 * * * *`
- Type: Edge Function → `tick`

**Job 2 — Causal engine (every hour):**
- Name: `causal-hourly`
- Schedule: `0 * * * *`
- Type: Edge Function → `causal_engine`

---

## ✅ Done — How to Know It's Working

After Step 8, wait 10 minutes, then:
- Table Editor → `event` table → insert any row manually
- Wait up to 10 min → check `insight` table → new decision rows should appear automatically

The brain is now running. Every 10 minutes it reads all recent events, evaluates all active rules, and writes structured decisions into the `insight` table. Every hour it traces causal chains across units and writes them into `causal_link`.

---

## If Something Breaks
- Edge Function error: Panel → Edge Functions → function name → **Logs** tab
- SQL error: Panel → Logs → **Postgres Logs**
- Cron error: Panel → Database → Cron Jobs → run history
- To reset everything: run `migrations_99_rollback.sql` in SQL Editor (drops all tables), then start from Step 1

## DO NOT RUN these files (they conflict with Schema.sql):
- ❌ `03_self_growing.sql`
- ❌ `04_graph_rules.sql`
- ❌ `tick_decision_engine.ts` (old broken version — ignore it)
