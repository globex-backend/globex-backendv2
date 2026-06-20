-- 05_causal_seed.sql
-- Seeds the causal_rule table with the safety-belt chains from the Soul Document.
-- These are DATA, not code. The causal_engine reads them at runtime.
-- Add more rows here as new chains are discovered — no code change needed.

insert into causal_rule (cause_kind, effect_kind, relation, window_hours, confidence) values
-- marketing → sales → finance chain
('budget_cut',        'lead_drop',          'leads_to',  72,  0.8),
('lead_drop',         'forecast_down',      'leads_to',  72,  0.75),
('forecast_down',     'ceo_growth_alert',   'leads_to',  72,  0.9),
-- SLA breach chain
('sla_breached',      'lead_cold',          'leads_to',  48,  0.85),
('lead_cold',         'reactivation',       'leads_to',  48,  0.7),
('reactivation',      'cac_rise',           'amplifies', 168, 0.65),
-- deal close → legal → payment → commission chain
('contract_closed',   'legal_review',       'leads_to',  24,  0.95),
('legal_review',      'payment_gate',       'leads_to',  24,  0.9),
('payment_confirmed', 'commission_unlocked','unlocks',    24,  1.0),
-- WhatsApp silence chain
('whatsapp_silent',   'lead_drop',          'leads_to',  48,  0.75);

-- ---------------------------------------------------------------
-- STAGING TEST FIXTURE (run this block to verify the brain works)
-- After running, invoke tick manually → check insight table for 1 row.
-- ---------------------------------------------------------------
/*
insert into entity (id, type, unit, attributes) values
  ('aaaaaaaa-0000-0000-0000-000000000001',
   'deal', 'sales',
   '{"stage":"warm","last_event_at":"2026-06-15T09:00:00Z"}');

insert into rule (unit, nl_text, trigger, dsl, rule_key, enabled) values
  ('sales',
   'deal warm and silent for more than 2 days',
   'field_changed',
   '{
     "condition": {"and": [
       {"entity.attributes.stage": {"=": "warm"}},
       {"days_since": {">": 2}}
     ]},
     "action": {
       "type":     "route_insight",
       "to_unit":  "sales",
       "severity": "warning",
       "headline": "Deal silent — follow up now"
     }
   }',
   'sales_silent',
   true);

insert into event (kind, unit, entity_id) values
  ('field_changed', 'sales', 'aaaaaaaa-0000-0000-0000-000000000001');
*/
