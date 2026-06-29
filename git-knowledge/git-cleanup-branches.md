# Git — Limpieza de Ramas y Referencias

## Por qué aparecen ramas fantasma

Cuando hacés `git fetch` o `git pull`, Git baja el estado del remoto
y actualiza tus referencias locales (`origin/main`, `origin/master`, etc.).

El problema es que Git **no borra automáticamente** las referencias a ramas
que ya no existen en el remoto. Si alguien borró `origin/master` en GitHub,
tu repo local sigue teniendo esa referencia cacheada hasta que la limpies.

```
GitHub (remoto)          Tu máquina (local)
───────────────          ──────────────────
main ✅                  origin/main ✅
                         origin/master 👻 ← ya no existe en el remoto
```

Esto es lo que muestra Code Server en el Source Control Graph cuando ves
`origin/master` con color distinto al `main` activo — es una referencia
que apunta a un commit real pero a una rama que ya no existe en el servidor.

---

## git fetch --prune — limpiar referencias remotas obsoletas

```bash
git fetch --prune
```

Hace dos cosas en un solo paso:
1. Baja los cambios nuevos del remoto (igual que `git fetch`)
2. Borra las referencias locales a ramas remotas que ya no existen

Después de ejecutarlo, `origin/master` desaparece si ya no existe en GitHub.

### Verificar antes de limpiar

Si querés ver qué referencias están obsoletas sin borrar nada todavía:

```bash
git remote prune origin --dry-run
```

Muestra qué borraría sin ejecutar la limpieza.

---

## git remote prune — solo limpiar, sin bajar cambios

Si no querés hacer fetch pero sí limpiar referencias viejas:

```bash
git remote prune origin
```

No baja nada nuevo. Solo elimina las referencias locales que apuntan
a ramas que ya no existen en `origin`.

---

## Configurar prune automático

Para que Git haga prune automáticamente en cada fetch o pull:

```bash
git config --global fetch.prune true
```

Con esto configurado, cada `git fetch` y `git pull` incluye prune sin que
tengas que acordarte de agregar el flag.

Verificar que quedó configurado:

```bash
git config --global --get fetch.prune
# debe mostrar: true
```

---

## Limpiar ramas locales huérfanas

`fetch --prune` limpia las referencias remotas (`origin/rama`),
pero no toca las ramas locales. Si tenías una rama local que seguía
a `origin/master`, esa rama local sigue existiendo aunque el remoto ya no exista.

### Ver ramas locales con su tracking

```bash
git branch -vv
```

Salida de ejemplo:

```
* main          abc1234 [origin/main] último commit
  feature-test  def5678 [origin/feature-test: gone] otro commit
  rama-vieja    ghi9012 sin tracking configurado
```

El `gone` indica que la rama remota ya no existe — esa rama local es candidata a borrar.

### Borrar una rama local

```bash
git branch -d nombre-rama
```

`-d` es seguro — falla si la rama tiene commits que no fueron mergeados.
Si estás seguro de que no necesitás esos commits:

```bash
git branch -D nombre-rama
```

`-D` fuerza el borrado sin verificar.

### Borrar todas las ramas locales cuyo remoto ya no existe

```bash
git branch -vv | grep ': gone]' | awk '{print $1}' | xargs git branch -d
```

Desglosado:
- `git branch -vv` — lista ramas con info de tracking
- `grep ': gone]'` — filtra solo las que tienen el remoto eliminado
- `awk '{print $1}'` — extrae solo el nombre de la rama
- `xargs git branch -d` — borra cada una con `-d` seguro

Si alguna tiene commits sin mergear, `-d` fallará para esa rama específicamente
y tendrás que decidir manualmente si usar `-D` o no.

---

## Ver el estado general de ramas

### Todas las ramas (locales y remotas)

```bash
git branch -a
```

### Solo remotas

```bash
git branch -r
```

### Con información de tracking y commits adelante/atrás

```bash
git branch -vv
```

### Ver qué ramas ya fueron mergeadas a main (candidatas a borrar)

```bash
git branch --merged main
```

Las ramas que aparecen acá ya están integradas — sus commits existen en `main`.
Se pueden borrar sin perder trabajo.

```bash
# Borrar todas las mergeadas excepto main
git branch --merged main | grep -v '^\* main' | xargs git branch -d
```

---

## Resumen de comandos

| Comando | Qué limpia |
|---|---|
| `git fetch --prune` | Referencias remotas obsoletas + baja cambios nuevos |
| `git remote prune origin` | Referencias remotas obsoletas (sin fetch) |
| `git branch -d rama` | Rama local (seguro, verifica merge) |
| `git branch -D rama` | Rama local (forzado, sin verificar) |
| `git fetch --prune` + `git branch -vv` | Ver qué quedó huérfano después de limpiar |

---

## Flujo de limpieza completo

Cuando el repo empieza a acumular ramas viejas:

```bash
# 1. Configurar prune automático si no está hecho
git config --global fetch.prune true

# 2. Limpiar referencias remotas obsoletas
git fetch --prune

# 3. Ver qué ramas locales quedaron huérfanas
git branch -vv

# 4. Borrar las que tienen ': gone]'
git branch -vv | grep ': gone]' | awk '{print $1}' | xargs git branch -d

# 5. Ver qué ramas locales ya fueron mergeadas (opcional)
git branch --merged main

# 6. Borrar las mergeadas que ya no necesitás
git branch --merged main | grep -v '^\* main' | xargs git branch -d
```

Después del paso 2 el Source Control de Code Server ya no debería mostrar
ramas fantasma como `origin/master`.
