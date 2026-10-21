// Supabase Edge Function — career-advisor (PrepUp AI, Phase 15)
//
// AI Career Advisor proxy. The Flutter app never talks to DeepSeek directly
// (locked decision D2): it invokes this function, which holds the API key.
//
// Contract (consumed by lib/data/remote/career_remote_repository.dart):
//   POST   /functions/v1/career-advisor
//   body   { "preferences": { ...student inputs... } }   (a bare map of the
//          preference fields is also accepted, since that is what the app
//          sends today)
//   200 -> { "career_title": "...", "summary": "...", "required_subjects": [...] }
//   401  missing/invalid Supabase JWT
//   405  non-POST
//   429  daily rate limit reached (AM-4: 10 calls per user per day)
//   502  DeepSeek failed or returned unparseable output
//
// Security notes:
//   - DEEPSEEK_API_KEY is read from Deno.env (a Supabase secret) and is never
//     echoed in a response, a prompt, or a log.
//   - Rate limiting is enforced atomically in Postgres (career_requests,
//     migration 0001) so concurrent requests cannot slip past the counter.
//   - User input only ever lands inside the `messages` array, never in the
//     system message or a header.
//
// Deploy:
//   supabase secrets set DEEPSEEK_API_KEY=sk-...   # already done for this project
//   supabase functions deploy career-advisor
//
// Local test:
//   supabase functions serve career-advisor
//   curl -X POST http://127.0.0.1:54321/functions/v1/career-advisor \
//     -H "Authorization: Bearer <user-access-token>" \
//     -H "Content-Type: application/json" \
//     -d '{"preferences":{"workEnvironment":"indoor","activityPreference":"solvingMath","favoriteSubjects":["Mathematics"]}}'
//   -> 401 without the header, 200 with a valid token and a healthy key.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const DAILY_CALL_LIMIT = 10;
const DEEPSEEK_URL = "https://api.deepseek.com/v1/chat/completions";
const DEEPSEEK_MODEL = "deepseek-chat";
const MAX_TOKENS = 500;

const SYSTEM_PROMPT = `You are the PrepUp AI career advisor for Nigerian secondary-school students preparing for WAEC and JAMB.
Given the student's preferences, recommend ONE STEM career that fits them best.
Reply with STRICT JSON only, no prose, no markdown fences, exactly this shape:
{"career": "<career title>", "summary": "<2-3 sentences explaining the fit, addressed to the student>", "required_subjects": ["<WAEC/JAMB subject>", ...]}
required_subjects must contain 2 to 4 real WAEC/JAMB subjects relevant to the career.`;

interface CareerPayload {
  career: string;
  summary: string;
  required_subjects: string[];
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/// Extract and validate the student's free-form preferences. Everything is
/// optional and length-capped so a hostile client cannot inflate the prompt.
function sanitizePreferences(raw: unknown): Record<string, string | string[]> {
  const source = (raw ?? {}) as Record<string, unknown>;
  const nested = (source.preferences ?? source) as Record<string, unknown>;
  const out: Record<string, string | string[]> = {};

  for (const [key, value] of Object.entries(nested)) {
    if (!/^[A-Za-z][A-Za-z0-9_]{0,40}$/.test(key)) continue;
    if (typeof value === "string") {
      const trimmed = value.trim().slice(0, 120);
      if (trimmed) out[key] = trimmed;
    } else if (Array.isArray(value)) {
      const items = value
        .filter((v): v is string => typeof v === "string")
        .map((v) => v.trim().slice(0, 60))
        .filter((v) => v.length > 0)
        .slice(0, 6);
      if (items.length > 0) out[key] = items;
    }
  }
  return out;
}

function buildUserMessage(preferences: Record<string, string | string[]>): string {
  const lines = Object.entries(preferences).map(([k, v]) => `${k}: ${Array.isArray(v) ? v.join(", ") : v}`);
  // Keep the free-form input inert: one blob, clearly delimited.
  return `Student preferences:\n${lines.join("\n")}\n\nRespond with the JSON object only.`;
}

function parseCareerJson(content: string): CareerPayload | null {
  let text = content.trim();
  // Strip accidental markdown fences or leading prose.
  const firstBrace = text.indexOf("{");
  const lastBrace = text.lastIndexOf("}");
  if (firstBrace === -1 || lastBrace <= firstBrace) return null;
  text = text.slice(firstBrace, lastBrace + 1);

  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch {
    return null;
  }
  if (typeof parsed !== "object" || parsed === null) return null;
  const obj = parsed as Record<string, unknown>;

  const career = obj.career ?? obj.career_title ?? obj.title;
  const summary = obj.summary ?? obj.description;
  const subjects = obj.required_subjects ?? obj.subjects;
  if (typeof career !== "string" || career.trim().length === 0) return null;
  if (typeof summary !== "string" || summary.trim().length === 0) return null;
  if (!Array.isArray(subjects)) return null;
  const requiredSubjects = subjects
    .filter((s): s is string => typeof s === "string")
    .map((s) => s.trim())
    .filter((s) => s.length > 0)
    .slice(0, 6);
  if (requiredSubjects.length === 0) return null;

  return {
    career: career.trim().slice(0, 120),
    summary: summary.trim().slice(0, 1000),
    required_subjects: requiredSubjects,
  };
}

async function callDeepSeek(
  apiKey: string,
  userMessage: string,
): Promise<CareerPayload | null> {
  for (let attempt = 0; attempt < 2; attempt++) {
    const response = await fetch(DEEPSEEK_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: DEEPSEEK_MODEL,
        max_tokens: MAX_TOKENS,
        temperature: 0.7,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: userMessage },
        ],
      }),
    });

    if (!response.ok) {
      // Retry only transient classes of failure once; never leak the body,
      // which could echo upstream details.
      if (response.status >= 500 && attempt === 0) continue;
      console.error(`DeepSeek returned ${response.status}`);
      return null;
    }

    const data = await response.json() as {
      choices?: Array<{ message?: { content?: string } }>;
    };
    const content = data.choices?.[0]?.message?.content;
    if (typeof content !== "string") return null;

    const parsed = parseCareerJson(content);
    if (parsed) return parsed;
    // Malformed output: fall through to the single retry.
  }
  return null;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  // --- 15.1: require a valid Supabase JWT -----------------------------------
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace(/^Bearer\s+/i, "").trim();
  if (!token) {
    return json({ error: "Sign in to use the AI Career Advisor." }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  const authClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const { data: userData, error: userError } = await authClient.auth.getUser(token);
  if (userError || !userData?.user) {
    return json({ error: "Sign in to use the AI Career Advisor." }, 401);
  }
  const userId = userData.user.id;

  // --- 15.2: daily rate limit (AM-4) ----------------------------------------
  // increment_career_request (migration 0004) is a single atomic
  // INSERT ... ON CONFLICT DO UPDATE ... RETURNING, so concurrent requests
  // cannot race past the limit. It is revoked from anon/authenticated, so
  // only this service-role call can reach it.
  const db = createClient(supabaseUrl, serviceRoleKey);
  const { data: callCount, error: counterError } = await db.rpc(
    "increment_career_request",
    { p_user_id: userId },
  );

  if (counterError) {
    // Fail closed: a broken counter must not become an open gate.
    console.error("Rate limit lookup failed:", counterError.message);
    return json({ error: "The career advisor is temporarily unavailable." }, 502);
  }

  if (typeof callCount === "number" && callCount > DAILY_CALL_LIMIT) {
    return json({ error: "Daily limit reached. Try again tomorrow." }, 429);
  }

  // --- 15.3/15.4: build prompt, call DeepSeek, validate --------------------
  const apiKey = Deno.env.get("DEEPSEEK_API_KEY");
  if (!apiKey) {
    // Misconfiguration, not the user's fault: 500 per the client's mapping.
    console.error("DEEPSEEK_API_KEY is not set");
    return json({ error: "The career advisor is not configured." }, 500);
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body." }, 400);
  }
  const preferences = sanitizePreferences(body);
  if (Object.keys(preferences).length === 0) {
    return json({ error: "No preferences provided." }, 400);
  }

  let payload: CareerPayload | null = null;
  try {
    payload = await callDeepSeek(apiKey, buildUserMessage(preferences));
  } catch (error) {
    // Never echo upstream error details (they could contain key-adjacent info).
    console.error("DeepSeek call failed:", error instanceof Error ? error.name : "unknown");
  }
  if (!payload) {
    return json(
      { error: "The career advisor is temporarily unavailable. Please try again." },
      502,
    );
  }

  return json({
    career_title: payload.career,
    summary: payload.summary,
    required_subjects: payload.required_subjects,
  });
});
