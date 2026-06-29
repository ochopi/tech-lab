# Git — Deshacer Cosas

Este es el tema donde más confusión hay en Git, porque existen varios comandos
que "deshacen" pero actúan en capas distintas. Entender las capas es la clave.

---

## Las tres capas de Git

Antes de ver los comandos, el modelo mental:

```
┌─────────────────────────────┐
│  Working Directory          │  ← archivos que ves y editás
├─────────────────────────────┤
│  Staging Area (Index)       │  ← lo que agregaste con git add
├─────────────────────────────┤
│  Commit History             │  ← lo que ya commiteaste
└─────────────────────────────┘
```

Cada comando de "deshacer" opera en una o más de estas capas.
Saber en qué capa está el problema te dice qué comando usar.

---

## git restore — deshacer cambios que todavía no commiteaste

### Descartar cambios en un archivo (Working Directory)

Modificaste un archivo y querés volver a como estaba en el último commit:

```bash
git restore archivo.txt
```

⚠️ **Irreversible.** Los cambios en el Working Directory no tienen historial —
una vez descartados, desaparecieron.

### Sacar un archivo del staging (sin perder los cambios)

Hiciste `git add` pero te arrepentiste y no querés incluirlo en el próximo commit:

```bash
git restore --staged archivo.txt
```

El archivo vuelve al Working Directory con los cambios intactos.
Solo lo sacás del staging, no perdés nada.

### Volver un archivo a como estaba en un commit específico

```bash
git restore --source abc1234 archivo.txt
```

Útil si borraste o rompiste un archivo y querés recuperar una versión anterior
sin tocar el resto del repo.

---

## git reset — mover el puntero de la rama

`reset` mueve el puntero `HEAD` (donde está tu rama ahora) hacia atrás en el historial.
Tiene tres modos que determinan qué pasa con los cambios de los commits que "deshaciste":

### --soft — deshace el commit, conserva los cambios en staging

```bash
git reset --soft HEAD~1
```

El último commit desaparece del historial pero todos sus cambios quedan
en el staging listos para volver a commitear. Útil si commiteaste demasiado pronto
y querés ajustar algo antes.

`HEAD~1` significa "un commit antes del actual". `HEAD~2` serían dos, etc.

### --mixed — deshace el commit, conserva los cambios en Working Directory (default)

```bash
git reset HEAD~1
# equivalente a:
git reset --mixed HEAD~1
```

El commit desaparece y los cambios vuelven al Working Directory sin staging.
Tenés que volver a hacer `git add` si querés incluirlos.

### --hard — deshace el commit y descarta todos los cambios

```bash
git reset --hard HEAD~1
```

⚠️ **Destructivo.** El commit desaparece y los cambios se pierden completamente.
Úsalo solo cuando estás seguro de que no querés nada de ese commit.

---

## git revert — deshacer sin reescribir historia

`revert` no borra commits — crea un commit nuevo que aplica el efecto inverso
de un commit anterior. La historia queda intacta.

```bash
git revert abc1234
```

Se abre el editor para confirmar el mensaje del commit de revert.
Al terminar, el nuevo commit cancela exactamente lo que hizo `abc1234`.

Cuándo usar `revert` en lugar de `reset`:
- Cuando el commit ya está en el remoto y otros lo pudieron bajar
- Cuando querés que quede registro de que algo fue revertido
- Cuando no querés o no podés forzar el push

---

## Resumen visual

```
¿Dónde está el problema?
│
├── En el Working Directory (sin git add)
│   └── git restore archivo.txt
│
├── En el Staging (después de git add, antes de commit)
│   └── git restore --staged archivo.txt
│
└── Ya commiteado
    │
    ├── ¿Solo local (no pusheaste)?
    │   ├── Quiero ajustar el último commit → git commit --amend
    │   ├── Quiero deshacer pero conservar cambios → git reset --soft HEAD~1
    │   └── Quiero deshacer y descartar todo → git reset --hard HEAD~1
    │
    └── ¿Ya está en el remoto?
        ├── Repo personal, nadie más lo bajó → git reset + git push --force-with-lease
        └── Otros lo pudieron bajar → git revert abc1234
```

---

## El salvavidas — git reflog

Si ejecutaste un `reset --hard` y te arrepentiste, no todo está perdido.
Git guarda un registro de todos los movimientos de HEAD llamado `reflog`:

```bash
git reflog
```

Salida de ejemplo:

```
abc1234 HEAD@{0}: reset: moving to HEAD~1
dda3054 HEAD@{1}: commit: el commit que "perdiste"
3a0a26f HEAD@{2}: commit: commit anterior
```

El commit `dda3054` sigue existiendo aunque no aparezca en `git log`.
Podés recuperarlo:

```bash
git reset --hard dda3054
```

El reflog se conserva por 90 días por defecto. Después de eso,
Git puede limpiar los commits huérfanos con `git gc`.

---

## Casos concretos rápidos

**Descartar todos los cambios no commiteados (volver al último commit limpio):**

```bash
git restore .
```

**Deshacer el último commit conservando los archivos:**

```bash
git reset --soft HEAD~1
```

**Recuperar un archivo borrado que sí estaba commiteado:**

```bash
git restore --source HEAD archivo-borrado.txt
```

**Ver qué hay en staging antes de commitear:**

```bash
git diff --staged
```
