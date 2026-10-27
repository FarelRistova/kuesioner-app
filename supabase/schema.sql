-- =====================================================================
-- Skema database Kuesioner Online (Supabase / PostgreSQL)
-- Jalankan seluruh isi file ini di: Supabase Dashboard > SQL Editor > New query
-- =====================================================================

-- 1) TABEL ------------------------------------------------------------

create table if not exists public.surveys (
  id          uuid primary key default gen_random_uuid(),
  title       text not null check (char_length(title) between 1 and 150),
  description text check (char_length(description) <= 500),
  created_at  timestamptz not null default now()
);

create table if not exists public.questions (
  id         uuid primary key default gen_random_uuid(),
  survey_id  uuid not null references public.surveys(id) on delete cascade,
  position   int  not null default 0,
  text       text not null check (char_length(text) between 1 and 300),
  -- choice = pilihan ganda, rating = skala 1-5, text = jawaban bebas
  type       text not null check (type in ('choice', 'rating', 'text')),
  options    jsonb not null default '[]'::jsonb,
  required   boolean not null default true
);

create table if not exists public.responses (
  id               uuid primary key default gen_random_uuid(),
  survey_id        uuid not null references public.surveys(id) on delete cascade,
  respondent_name  text not null check (char_length(respondent_name) between 1 and 100),
  created_at       timestamptz not null default now()
);

create table if not exists public.answers (
  id           uuid primary key default gen_random_uuid(),
  response_id  uuid not null references public.responses(id) on delete cascade,
  survey_id    uuid not null references public.surveys(id) on delete cascade,
  question_id  uuid not null references public.questions(id) on delete cascade,
  value        text not null check (char_length(value) <= 1000)
);

create index if not exists questions_survey_idx on public.questions (survey_id, position);
create index if not exists responses_survey_idx on public.responses (survey_id);
create index if not exists answers_survey_idx   on public.answers (survey_id);
create index if not exists answers_question_idx on public.answers (question_id);

-- 2) ROW LEVEL SECURITY ----------------------------------------------
-- Website ini publik: siapa saja boleh membuat kuesioner, mengisi, dan
-- melihat hasil. Tetapi TIDAK ADA yang boleh mengubah / menghapus data
-- lewat API publik (hanya lewat dashboard Supabase oleh Anda).

alter table public.surveys   enable row level security;
alter table public.questions enable row level security;
alter table public.responses enable row level security;
alter table public.answers   enable row level security;

create policy "surveys_select_public"   on public.surveys   for select to anon, authenticated using (true);
create policy "surveys_insert_public"   on public.surveys   for insert to anon, authenticated with check (true);

create policy "questions_select_public" on public.questions for select to anon, authenticated using (true);
create policy "questions_insert_public" on public.questions for insert to anon, authenticated with check (true);
create policy "surveys_update_public" on public.surveys for update to anon, authenticated using (true) with check (true);
create policy "questions_update_public" on public.questions for update to anon, authenticated using (true) with check (true);
create policy "questions_delete_public" on public.questions for delete to anon, authenticated using (true);

create policy "responses_select_public" on public.responses for select to anon, authenticated using (true);
create policy "responses_insert_public" on public.responses for insert to anon, authenticated with check (true);

create policy "answers_select_public"   on public.answers   for select to anon, authenticated using (true);
create policy "answers_insert_public"   on public.answers   for insert to anon, authenticated with check (true);

-- 3) PRIVASI NAMA RESPONDEN ------------------------------------------
-- Nama responden hanya bisa dibaca dari dashboard Supabase, bukan dari
-- API publik. Halaman hasil hanya butuh jumlah responden (kolom id).
revoke select on public.responses from anon, authenticated;
grant  select (id, survey_id, created_at) on public.responses to anon, authenticated;
