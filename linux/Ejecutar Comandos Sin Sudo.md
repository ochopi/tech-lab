# Mini-manual: permitir comandos especificos (`efibootmgr` y `reboot`) sin contraseña

## Objetivo

Permitir que un usuario ejecute **solo** estos comandos como root, sin `sudo` interactivo:

* `efibootmgr`
* `systemctl reboot`

Sin abrir permisos generales ni tocar otros privilegios.

---

## 1️⃣ Abrir/Crear un archivo sudoers dedicado

**Nunca** edites `/etc/sudoers` directamente.

```bash
sudo visudo -f /etc/sudoers.d/bootnext
```
Esto abre un archivo nuevo y seguro.
* si el archivo **no existe**, se crea
* si existe, se edita
* No tiene contenido previo. Tu defines todo.

---

## 2️⃣ Añadir las reglas

Dentro del editor, pega (ajusta el nombre de usuario si no es `yggr`):

```text
yggr ALL=(root) NOPASSWD: /usr/sbin/efibootmgr
yggr ALL=(root) NOPASSWD: /usr/bin/systemctl reboot
```

Guarda y cierra.

Si estas editando en vim:
* Presiona ESC
* Teclea  `:wq` + `ENTER`
* :w → write (guardar)
* :q → quit (salir)
* O para salir sin guardar: `ESC` + `:qa!` + `ENTER`

`visudo` valida la sintaxis antes de aplicar nada.
Asi que no hay que preocuparse de romper SUDO

---

## 3️⃣ Probar que funciona

Cierra todas las terminales abiertas (importante).

Luego ejecuta:

```bash
sudo -k
sudo efibootmgr
sudo systemctl reboot
```

Resultado esperado:

* **no pide contraseña**
* los comandos se ejecutan normalmente

Si alguno pide clave, la ruta del binario es distinta.

---

## 4️⃣ (Opcional) Versión más restrictiva

Si quieres limitar `efibootmgr` **solo** a `--bootnext`:

```text
yggr ALL=(root) NOPASSWD: /usr/sbin/efibootmgr --bootnext *
yggr ALL=(root) NOPASSWD: /usr/bin/systemctl reboot
```

Más seguro, menos flexible.

---

## 5️⃣ Deshacer los cambios (si algún día hace falta)

```bash
sudo rm /etc/sudoers.d/bootnext
```

Los permisos vuelven a la normalidad inmediatamente.

---

## Notas finales

* Esto **no** concede root general
* No permite ejecutar otros comandos
* No persiste cambios peligrosos
* Es compatible con Bazzite / ostree
* Ideal para scripts de arranque selectivo

---

**Regla de oro**
Permite sin contraseña solo aquello que:

1. entiendes perfectamente
2. ejecutarías manualmente sin dudar
3. no deja puertas abiertas

Este caso cumple las tres.
