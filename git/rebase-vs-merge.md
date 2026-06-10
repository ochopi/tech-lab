# Git Rebase y Git Merge

## Git Rebase

### Qué hace exactamente

Rebase **mueve o re-aplica commits** encima de otra base. No fusiona, sino que literalmente recorta tus commits y los vuelve a escribir encima de otro punto.

En tu caso concreto:

```
ANTES:
* e5de150 (HEAD -> main) actualizacion de arbol     ← tu commit
| * 3a0a26f (origin/main) actualizacion summaries   ← el que te faltaba
|/
* 5c9c5da ancestro común

DESPUÉS del rebase:
* 3f06d25 (HEAD -> main) actualizacion de arbol     ← mismo cambio, commit NUEVO (hash distinto)
* 3a0a26f (origin/main) actualizacion summaries
* 5c9c5da ancestro común
```

Nota importante: `e5de150` desapareció y apareció `3f06d25`. **Es un commit nuevo**. Git tomó los cambios de `e5de150`, los descartó temporalmente, avanzó hasta `3a0a26f`, y volvió a aplicar esos mismos cambios encima. El contenido es idéntico pero el hash cambia porque cambió su commit padre.

### Desde dónde se ejecuta

Siempre desde la rama que querés mover, apuntando a la rama destino:

```bash
# Estás en la rama que tiene tus commits locales
git checkout mi-rama

# La rebaseas encima de origin/main
git rebase origin/main
```

En tu caso estabas en `main` con el commit de code-server, y rebasaste sobre `origin/main` que tenía el commit de VS Code. Correcto.

### Qué pasa si hay conflictos

Si dos commits tocan el mismo archivo, Git pausa y te dice dónde está el conflicto:

```bash
# Resolvés el archivo manualmente, luego:
git add archivo-conflictivo
git rebase --continue

# Si querés abortar y volver al estado anterior:
git rebase --abort
```

---

## Git Merge

### Qué hace exactamente

Merge **une dos ramas creando un commit nuevo** que tiene dos padres. No reescribe historia, la preserva tal cual y agrega un nodo de unión.

Con el mismo escenario tuyo, si hubieras hecho merge en lugar de rebase:

```
ANTES:
* e5de150 (HEAD -> main) actualizacion de arbol
| * 3a0a26f (origin/main) actualizacion summaries
|/
* 5c9c5da ancestro común

DESPUÉS del merge:
*   a1b2c3d (HEAD -> main) Merge branch 'origin/main' into main
|\
| * 3a0a26f actualizacion summaries
* | e5de150 actualizacion de arbol
|/
* 5c9c5da ancestro común
```

Los commits originales `e5de150` y `3a0a26f` siguen existiendo con sus hashes intactos. El commit de merge `a1b2c3d` es el que une ambas líneas.

### Cómo se ejecuta

```bash
# Estás en la rama que recibe los cambios
git checkout main

# Traés los cambios de origin
git fetch origin

# Mergeás
git merge origin/main
```

O en un solo paso si no necesitás revisar antes:
```bash
git pull origin main  # fetch + merge automático
```

---

## Diferencias clave

| | Rebase | Merge |
|---|---|---|
| Historial | Lineal, limpio | Preserva ramas, más fiel a la realidad |
| Commits originales | Los reescribe (hash nuevo) | Los preserva intactos |
| Commit extra | No | Sí (el merge commit) |
| Conflictos | Se resuelven uno por uno, commit a commit | Se resuelven todos juntos |
| Seguridad en repos compartidos | Peligroso si ya hiciste push | Siempre seguro |

---

## La regla de oro del rebase

**Nunca rebasear commits que ya están en origin y que otros podrían haber bajado.**

Cuando rebaseás, reescribís la historia. Si alguien ya tiene `e5de150` en su máquina y vos lo reemplazás por `3f06d25`, esa persona tendrá un conflicto severo la próxima vez que haga pull porque Git verá dos versiones distintas del mismo trabajo.

En tu homelab sos el único usuario, así que no hay riesgo. En un equipo, la regla es: **rebase solo en commits que todavía no salieron de tu máquina.**

---

## Cuándo usar cada uno

**Rebase** cuando:
- Tus commits son locales y aún no los pusheaste
- Querés mantener el historial limpio y lineal
- Estás actualizando tu rama de feature con los últimos cambios de main antes de hacer PR
- Es un proyecto personal o solo vos trabajás en esa rama

**Merge** cuando:
- Los commits ya están en origin y otros los pudieron bajar
- Querés preservar exactamente cuándo y desde dónde se hizo cada cambio
- Estás integrando una feature branch completa a main (el merge commit documenta ese evento)
- Trabajás en equipo y la transparencia del historial importa

En la práctica profesional el flujo más común es: **rebase para mantener tu rama actualizada mientras desarrollás, merge para integrar al final cuando la feature está lista.**