# Git — Renombrar Ramas

## El modelo mental primero

Una rama en Git es simplemente un **puntero con nombre** que apunta a un commit.
Cuando renombrás una rama, no movés commits ni cambiás historia — solo cambiás la etiqueta.

El problema es que esa etiqueta existe en **dos lugares distintos**:

```
Tu máquina (local)          GitHub/Gitea (remoto)
─────────────────           ─────────────────────
master ──→ commit X         origin/master ──→ commit X
```

Son independientes. Renombrar uno no renombra el otro automáticamente.
Por eso el proceso siempre tiene dos partes.

---

## Caso típico — renombrar master a main

### Opción A: desde GitHub (recomendada para repos existentes)

GitHub se encarga de la parte remota y avisa a colaboradores.

```
Settings → Branches → Rename
```

Después actualizás el lado local para que quede sincronizado:

```bash
# 1. Renombrás la rama local
git branch -m master main

# 2. Bajás el estado actualizado del remoto
git fetch origin

# 3. Le decís a tu rama local que siga a origin/main
git branch -u origin/main main
```

Verificar:

```bash
git branch -vv
```

Debe mostrar algo como:

```
* main  abc1234 [origin/main] último mensaje de commit
```

El `[origin/main]` confirma que el tracking está correcto.

---

### Opción B: todo desde la terminal

Si preferís hacerlo sin tocar la UI de GitHub:

```bash
# 1. Renombrás la rama local
git branch -m master main

# 2. Subís la rama con el nuevo nombre al remoto
git push origin main

# 3. Cambiás la rama default en GitHub (obligatorio, no se puede desde terminal)
#    Settings → Branches → cambiar default branch a main

# 4. Borrás la rama vieja del remoto
git push origin --delete master

# 5. Actualizás el tracking
git branch -u origin/main main
```

El paso 3 no se puede evitar — GitHub no permite borrar la rama default,
así que hay que cambiarla antes de poder borrar `master`.

---

## Renombrar cualquier otra rama

El proceso es el mismo, solo cambian los nombres:

```bash
# Renombrás local
git branch -m nombre-viejo nombre-nuevo

# Subís con nombre nuevo
git push origin nombre-nuevo

# Borrás el nombre viejo del remoto
git push origin --delete nombre-viejo

# Actualizás tracking
git branch -u origin/nombre-nuevo nombre-nuevo
```

---

## Qué significa cada comando

| Comando | Qué hace |
|---|---|
| `git branch -m viejo nuevo` | Renombra rama local (`-m` = move) |
| `git fetch origin` | Baja el estado del remoto sin mergear nada |
| `git branch -u origin/main main` | Dice "esta rama local sigue a esta rama remota" (`-u` = set upstream) |
| `git push origin --delete master` | Borra la rama `master` del remoto |

---

## Por qué el tracking importa

Sin tracking configurado, Git no sabe contra qué comparar tu rama cuando hacés `git status`.
Verías mensajes como "Your branch is ahead of..." o directamente no vería el remoto.

Con tracking correcto, `git status` puede decirte exactamente cuántos commits tenés
adelante o atrás respecto al remoto.

El tracking también es lo que hace que `git push` y `git pull` sin argumentos
funcionen correctamente — Git sabe a dónde mandar y de dónde bajar.

## Git Prune

Luego de renombrar una rama es normal que quede algo de cache, por ejemplo, en el Source Control de VS-Code
Para limpiarlo y actualizarlo se hace 

```bash
git fetch --prune
```

`--prune` le dice a Git que limpie las referencias remotas que ya no existen en el servidor. 
Después de eso solo debería quedar origin/main.