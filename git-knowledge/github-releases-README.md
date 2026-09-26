# Guía — Proceso de Releases en GitHub

> Esta guía documenta el *proceso*, no un proyecto específico.  
> 
> Basada en la experiencia real haciendo los releases de un fork de `e1000e-dkms-debian`.
> Sirve como referencia para cualquier repo futuro.

---

## 1. Los 3 conceptos que hay que distinguir

Es fácil mezclarlos porque suenan parecido, pero son cosas distintas:

| Concepto    | Qué es                                                                                                    | Dónde vive                                                                          |
| ----------- | --------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| **Commit**  | Una foto del código en un punto del tiempo, con mensaje                                                   | Dentro del historial de git, en una rama                                            |
| **Tag**     | Una etiqueta fija sobre un commit específico (ej. `v1.0.0`) — marca "este commit es una versión"          | Git, pero se sube a GitHub con `git push --tags` o lo crea `gh`/la web directamente |
| **Release** | Una *página* en GitHub construida sobre un tag: título, notas en Markdown, y archivos adjuntos opcionales | Solo existe en GitHub (no es un concepto de git puro)                               |

Un release **siempre requiere un tag** (lo crea si no existe), pero un tag por sí solo no es un release — es solo un puntero.

---

## 2. Flujo típico completo

```
cambios en código
      │
      ▼
git add + git commit  (guarda el cambio en el historial)
      │
      ▼
git push origin main  (sube el historial a GitHub)
      │
      ▼
crear tag + release   (marca un commit específico como "versión publicada")
      │
      ▼
(opcional) adjuntar binarios/paquetes al release
```

Los commits normales (día a día, arreglando cosas, documentando) **no necesitan un release cada vez**. El release es para marcar un punto concreto que querés que la gente pueda encontrar, descargar y citar como "versión X".

---

## 3. Mensajes de commit — qué los hace útiles

Un commit sin buen mensaje es casi inútil para el futuro (tuyo o de otro).  

Estructura que funciona bien:

```
Título corto en imperativo (qué hace este commit, no qué hiciste)

- Detalle 1
- Detalle 2
- Contexto extra si hace falta (por qué, no solo qué)

Tested on: <contexto relevante, ej. versión de kernel>
```

Ejemplo real usado en este proceso:

```
Patch driver for kernel 6.17 (Proxmox) API compatibility + NVM checksum bypass

- Bypass NVM checksum validation (netdev.c)
- Update timer API calls (del_timer_sync, from_timer)
- strlcpy -> strscpy
- Update ethtool_ops signatures (ringparam, coalesce, ts_info, EEE)

Tested on kernel 6.17.2-1-pve, Intel I219-LM.
```

Con esto, alguien mirando el historial (`git log`) entiende el cambio sin tener que leer el diff completo.

---

## 4. SSH vs gh (CLI) — por qué son cosas separadas

Este fue el punto que generó la duda: *"si ya estaba autenticado por SSH, ¿por qué me pidió `gh auth login`?"*

|               | SSH (clave)                                       | `gh` CLI                                                           |
| ------------- | ------------------------------------------------- | ------------------------------------------------------------------ |
| Qué autentica | **git** — el protocolo para `clone`/`push`/`pull` | La **API de GitHub** — crear releases, issues, PRs, comentar, etc. |
| Qué usa       | Tu clave pública/privada SSH                      | Un token OAuth propio de `gh`                                      |
| Se configura  | Una vez por máquina/clave                         | Una vez por instalación de `gh`                                    |

Son dos sistemas de autenticación completamente independientes. Tener SSH andando no le da a `gh` acceso a la API — hay que autenticarlo aparte, una sola vez, con `gh auth login`.

---

## 5. `gh repo set-default` — por qué aparece en forks

Cuando el repo local es un **fork**, GitHub sabe que existe una relación con el repo original (upstream). `gh` detecta eso y, como tenés acceso a ambos (dueño del fork, lector del original público), te pregunta a cuál debe apuntar por defecto cuando corrés comandos como `gh release create`, `gh issue create`, etc.

**Casi siempre querés elegir tu fork**, no el original — si elegís el original por error, `gh` va a intentar crear el release ahí y te va a fallar por falta de permisos (a menos que también seas colaborador de ese repo).

Se puede reconfigurar en cualquier momento:

```bash
gh repo set-default
```

---

## 6. Crear un release — CLI vs GUI

**Se puede hacer por las dos vías** — es la misma funcionalidad, solo cambia la interfaz.

### Por la web (GUI)

1. Repo → pestaña **Releases** (en la barra lateral derecha, o `/releases` en la URL)
2. **Draft a new release**
3. **Choose a tag** → escribir uno nuevo (ej. `v1.0.0`) → *Create new tag on publish*
4. Target: la rama o commit exacto
5. Título + cuerpo (Markdown, se puede pegar directo)
6. **Attach binaries** → arrastrar archivos si aplica
7. **Publish release**

Ventaja: no hay que recordar sintaxis, se ve el preview del Markdown en vivo.

### Por CLI (`gh`)

```bash
gh release create v1.0.0 \
  --title "Título del release" \
  --notes-file notas.md \
  --target main
```

Para adjuntar un archivo después (o en el mismo comando, pasándolo como argumento extra):

```bash
gh release upload v1.0.0 ./archivo.tar.gz
```

Ventaja: repetible, scripteable, no hay que salir de la terminal — útil si vas a automatizar releases más adelante (ej. desde un pipeline).

**No hay diferencia funcional entre ambas** — el resultado en GitHub es idéntico. Es puramente preferencia de flujo de trabajo.

---

## 7. Notas prácticas aprendidas en el proceso real

- **Un release no necesita traer un archivo adjunto** — GitHub genera automáticamente el `.zip`/`.tar.gz` del código fuente en ese tag. Adjuntar un binario aparte (como un `.tar.gz` con `install.sh` incluido) es opcional, para conveniencia de quien lo descargue.
- **No todo commit necesita ser un release.** El "Update README" de este proceso, por ejemplo, se quedó como commit normal — no ameritaba una versión nueva porque no cambió nada funcional del paquete.
- **Revisar qué se sube antes del release**, sobre todo si el material de trabajo incluyó logs, backups o conversaciones con datos reales de tu entorno (IPs, MACs, nombres de host) — esos no deberían terminar en un repo público. Vale la pena un `git diff`/`git status` antes de cada commit, y una revisión visual del `.tar.gz` antes de subirlo como binario.
- **Los mensajes de commit detallados valen más que muchos commits pequeños mal descritos**, sobre todo cuando no tenés el historial real paso a paso (como en este caso, reconstruido desde una conversación) — es más honesto documentar bien en un solo commit que fingir una progresión que no ocurrió.

---

## 8. Checklist rápido para el próximo release

```
[ ] Cambios ya commiteados y pusheados a main
[ ] git status limpio (nada suelto sin commitear)
[ ] Revisar que no haya datos sensibles en lo que se va a publicar
[ ] Elegir nombre de tag (semver o descriptivo, ej. v1.2.0 o v3.8.7-algo)
[ ] Redactar notas del release (qué cambió, en qué se probó, limitaciones conocidas)
[ ] gh release create <tag> --title "..." --notes-file notas.md --target main
    (o el mismo proceso por la web si se prefiere)
[ ] (Opcional) gh release upload <tag> archivo.ext
[ ] Verificar que el release se ve bien en la web antes de anunciarlo
```
