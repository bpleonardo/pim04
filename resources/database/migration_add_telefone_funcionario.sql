-- Add telefone column to tb_funcionario if it doesn't exist
-- This is a one-time migration needed for the app to function properly

BEGIN;

-- Check if column exists and add it if needed
ALTER TABLE tb_funcionario 
ADD COLUMN IF NOT EXISTS telefone character varying(13);

COMMIT;
