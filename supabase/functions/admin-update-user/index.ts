import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) throw new Error('No authorization header')

    const userClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: userError } = await userClient.auth.getUser()
    if (userError || !user) throw new Error('Usuario no autenticado')

    const role = user.user_metadata?.role
    if (role !== 'Admin') throw new Error('Acceso denegado: solo Admins')

    const body = await req.json()
    const { id, password, role: newRole, name } = body

    if (!id) throw new Error('Falta el id del usuario')

    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const metadata: Record<string, string> = {}
    if (newRole) metadata['role'] = newRole
    if (name) metadata['full_name'] = name

    const attrs: Record<string, unknown> = {}
    if (password && password.trim().length > 0) attrs['password'] = password
    if (Object.keys(metadata).length > 0) attrs['user_metadata'] = metadata

    const { data, error } = await adminClient.auth.admin.updateUserById(id, attrs)
    if (error) throw error

    return new Response(JSON.stringify({ success: true, user: data.user }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
