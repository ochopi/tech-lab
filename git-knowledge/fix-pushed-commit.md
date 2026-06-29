# Git — Corregir un Commit ya Subido

## El problema

Un commit ya está en el remoto (GitHub/Gitea) y necesitás corregir algo:
el autor, el mensaje, o el contenido de los archivos.

Como el commit ya existe en el remoto, cualquier corrección implica
**reescribir la historia** y forzar el push. Esto solo es seguro si sos el único
que trabaja en esa rama.

---

## Caso 1 — Corregir el autor del último commit

Ocurre cuando hiciste commit con la identidad equivocada.
Ejemplo real: commit en el repo de `ewbiblia` que salió firmado como `ochopi`
porque faltaba configurar `git config user.name` y `user.email` en ese repo.

```bash
# 1. Verificar que la identidad local es correcta ahora
git config user.name
git config user.email

# 2. Reescribir el commit con el autor correcto
git commit --amend --reset-author --no-edit
```

`--reset-author` toma el `user.name` y `user.email` actuales y los aplica al commit.
`--no-edit` conserva el mensaje original sin abrir el editor.

```bash
# 3. Forzar el push
git push --force-with-lease origin main
```

Verificar en GitHub que el commit aparece con el autor correcto.

---

## Caso 2 — Corregir el mensaje del último commit

```bash
git commit --amend
```

Se abre el editor con el mensaje actual. Editás, guardás y cerrás.

```bash
git push --force-with-lease origin main
```

---

## Caso 3 — Corregir el contenido del último commit

Si te olvidaste de incluir un archivo, o subiste algo que no debías:

```bash
# Hacés los cambios necesarios en los archivos
# Luego los agregás al staging
git add archivo-corregido

# Amend sin cambiar el mensaje
git commit --amend --no-edit

git push --force-with-lease origin main
```

---

## Caso 4 — Corregir un commit anterior (no el último)

Si el commit a corregir no es el último, `--amend` no alcanza.
Necesitás rebase interactivo.

```bash
# Ver el historial con hashes
git log --oneline

# Ejemplo de salida:
# dda3054 (HEAD -> main) commit que querés corregir  ← no es el último
# 3a0a26f el último commit
# 5c9c5da commit anterior
```

```bash
# Abrís rebase interactivo desde el commit anterior al que querés editar
# Si querés editar dda3054, pasás su padre como referencia
git rebase -i 5c9c5da
```

Se abre un editor con la lista de commits. Cambiás `pick` por `edit`
en el commit que querés corregir, guardás y cerrás.

Git pausa en ese commit. Hacés las correcciones (amend, agregar archivos, etc.):

```bash
git commit --amend --reset-author --no-edit
# o lo que necesites corregir
```

Continuás el rebase:

```bash
git rebase --continue
```

Si hay más commits marcados como `edit`, Git pausa en cada uno.
Al terminar, forzás el push:

```bash
git push --force-with-lease origin main
```

---

## force vs force-with-lease

| Comando                       | Comportamiento                                              |
| ----------------------------- | ----------------------------------------------------------- |
| `git push --force`            | Sobreescribe sin verificar nada                             |
| `git push --force-with-lease` | Verifica que nadie más subió cambios antes de sobreescribir |

Siempre usar `--force-with-lease`. Si alguien subió algo después de tu último fetch,
`--force` lo borraría sin avisar. `--force-with-lease` falla y te avisa.

En un repo personal donde sos el único usuario la diferencia es mínima,
pero es un buen hábito.

---

## Cuándo NO hacer esto

Si otros ya bajaron (`git pull`) los commits que querés reescribir,
al forzar el push tendrán conflictos severos la próxima vez que sincronicen.

En ese caso la alternativa segura es hacer un commit nuevo que corrija el error
en lugar de reescribir la historia. Para el caso del autor equivocado
no hay forma limpia de corregirlo sin reescribir — en un equipo
habría que coordinarlo.

En repos personales donde sos el único usuario, reescribir es siempre seguro.