begin;
alter type public.attempt_state add value if not exists 'pending_human_scoring';
alter type public.attempt_state add value if not exists 'grading_in_progress';
commit;
