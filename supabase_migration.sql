-- Ejecutar esto en el SQL Editor de Supabase

-- Agregar la columna modo a la tabla fugas (si no existe)
ALTER TABLE public.fugas ADD COLUMN IF NOT EXISTS modo TEXT DEFAULT 'fugas';

-- Asegurar que los datos existentes tengan el modo correcto
UPDATE public.fugas SET modo = 'fugas' WHERE modo IS NULL;

-- (Opcional) Si la tabla fugas_audit_log no tiene modo pero quieres 
-- vincularlo, en este caso no es necesario porque fugas_audit_log
-- tiene `fuga_id` que referencia a `fugas` (que ya tiene el modo).
