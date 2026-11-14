-- Esquema del MVP de Mimedica.
-- Cada fila pertenece a quien inició sesión; RLS es la única barrera, así que
-- toda tabla nueva debe salir de aquí con su política.

create table public.perfiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nombre text not null,
  tipo_documento text not null,
  documento text not null,
  nacimiento date not null,
  autorizo_servicio_el timestamptz,
  autoriza_estadistica boolean not null default false,
  version_autorizacion text,
  creado_el timestamptz not null default now()
);

create table public.personas (
  id uuid primary key,
  usuario_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  nombre text not null,
  es_titular boolean not null default false,
  eps text,
  creado_el timestamptz not null default now()
);

create table public.tratamientos (
  id uuid primary key,
  usuario_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  persona_id uuid not null references public.personas (id) on delete cascade,
  nombre text not null,
  concentracion text not null default '',
  presentacion text not null check (presentacion in ('tableta', 'capsula', 'unidad')),
  por_toma numeric not null check (por_toma > 0),
  frecuencia text not null check (frecuencia in ('cada24', 'cada12', 'cada8', 'cada6')),
  en_casa numeric not null check (en_casa >= 0),
  contado_el date not null,
  vigencia_hasta date,
  foto_formula text,
  pausado boolean not null default false,
  creado_el timestamptz not null default now()
);

create table public.ciclos (
  id uuid primary key,
  usuario_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  tratamiento_id uuid not null references public.tratamientos (id) on delete cascade,
  abierto_el date not null,
  estado text not null default 'abierto' check (estado in ('abierto', 'asegurado', 'cerrado')),
  -- Lo que el equipo averiguó con la EPS, en una frase para el cuidador.
  nota text,
  origen text check (origen in ('eps', 'particular')),
  cantidad numeric,
  punto text,
  cerrado_el date
);

-- Las opciones las registra el equipo desde el panel de Supabase.
create table public.opciones (
  id uuid primary key default gen_random_uuid(),
  ciclo_id uuid not null references public.ciclos (id) on delete cascade,
  tipo text not null check (tipo in ('eps', 'drogueria')),
  nombre text not null,
  direccion text,
  precio integer,
  distancia_km numeric,
  telefono text,
  verificado_el timestamptz not null default now()
);

create table public.pendientes (
  id uuid primary key,
  usuario_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  tratamiento_id uuid not null references public.tratamientos (id) on delete cascade,
  fecha date not null,
  punto text not null,
  faltante numeric,
  nota text
);

create table public.eventos (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  nombre text not null,
  datos jsonb not null default '{}',
  ocurrio_el timestamptz not null default now()
);

create index on public.personas (usuario_id);
create index on public.tratamientos (usuario_id);
create index on public.tratamientos (persona_id);
create index on public.ciclos (usuario_id);
create index on public.ciclos (tratamiento_id);
create index on public.opciones (ciclo_id);
create index on public.pendientes (usuario_id);
create index on public.eventos (usuario_id, nombre);

alter table public.perfiles enable row level security;
alter table public.personas enable row level security;
alter table public.tratamientos enable row level security;
alter table public.ciclos enable row level security;
alter table public.opciones enable row level security;
alter table public.pendientes enable row level security;
alter table public.eventos enable row level security;

create policy "perfil propio" on public.perfiles
  for all to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy "personas del hogar" on public.personas
  for all to authenticated
  using (usuario_id = (select auth.uid()))
  with check (usuario_id = (select auth.uid()));

create policy "tratamientos del hogar" on public.tratamientos
  for all to authenticated
  using (usuario_id = (select auth.uid()))
  with check (usuario_id = (select auth.uid()));

create policy "ciclos del hogar" on public.ciclos
  for all to authenticated
  using (usuario_id = (select auth.uid()))
  with check (usuario_id = (select auth.uid()));

create policy "opciones de mis ciclos" on public.opciones
  for select to authenticated
  using (
    exists (
      select 1 from public.ciclos c
      where c.id = opciones.ciclo_id and c.usuario_id = (select auth.uid())
    )
  );

create policy "pendientes del hogar" on public.pendientes
  for all to authenticated
  using (usuario_id = (select auth.uid()))
  with check (usuario_id = (select auth.uid()));

create policy "registrar eventos propios" on public.eventos
  for insert to authenticated
  with check (usuario_id = (select auth.uid()));

-- Lo que el equipo tiene que gestionar hoy. Se consulta desde el panel.
create view public.ciclos_por_gestionar
with (security_invoker = true) as
select
  c.id as ciclo_id,
  c.abierto_el,
  c.estado,
  c.nota,
  t.nombre || ' ' || t.concentracion as medicamento,
  p.nombre as paciente,
  p.eps,
  (t.contado_el + floor(t.en_casa / (t.por_toma *
    case t.frecuencia
      when 'cada24' then 1 when 'cada12' then 2 when 'cada8' then 3 else 4
    end))::int) as se_acaba_el,
  t.foto_formula
from public.ciclos c
join public.tratamientos t on t.id = c.tratamiento_id
join public.personas p on p.id = t.persona_id
where c.estado <> 'cerrado'
order by se_acaba_el;

-- Borra la cuenta de quien llama; las tablas caen en cascada.
create function public.eliminar_cuenta()
returns void
language sql
security definer
set search_path = ''
as $$
  delete from auth.users where id = (select auth.uid());
$$;

revoke execute on function public.eliminar_cuenta() from public, anon;
grant execute on function public.eliminar_cuenta() to authenticated;

-- Fotos de las fórmulas: bucket privado, una carpeta por usuario.
insert into storage.buckets (id, name, public)
values ('formulas', 'formulas', false)
on conflict (id) do nothing;

create policy "ver mis formulas" on storage.objects
  for select to authenticated
  using (bucket_id = 'formulas' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "subir mis formulas" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'formulas' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "borrar mis formulas" on storage.objects
  for delete to authenticated
  using (bucket_id = 'formulas' and (storage.foldername(name))[1] = (select auth.uid())::text);
