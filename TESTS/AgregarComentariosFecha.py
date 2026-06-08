# Fecha Ultima Modificacion Realizada: 2025-06-30
# Fecha Último uso confirmado: 2025-06-30
# Caso en que fue aplicado: 
# Agregar comentarios con fecha de modificación a archivos de este repositorio

# Estado del archivo: OK
# Se modifico para aplicar una validacion y codificar los .reg en UTF-16 ya que al principio lo hacia en UTF-8 y no se estaba haciendo correctamente

from pathlib import Path
import os
from datetime import datetime

# Detectar carpeta raíz automáticamente
repo_root = Path(__file__).parent.resolve()

# Comentarios por extensión
comment_styles = {
    ".txt": "#",
    ".bat": "REM",
    ".cmd": "REM",
    ".ps1": "#",
    ".reg": ";",
}

# Obtener fecha de modificación
def get_modification_date(path: Path) -> str:
    ts = os.path.getmtime(path)
    return datetime.fromtimestamp(ts).strftime("%Y-%m-%d")

# Procesar archivos compatibles
for filepath in repo_root.rglob("*.*"):
    ext = filepath.suffix.lower()
    if ext not in comment_styles or not filepath.is_file():
        continue

    comment = comment_styles[ext]
    fecha = get_modification_date(filepath)

    comentario = [
        f"{comment} Fecha Ultima Modificacion Realizada: {fecha}",
        f"{comment} Fecha Último uso confirmado: ",
        f"{comment} Caso en que fue aplicado: ",
        f"{comment} Estado del archivo: "
    ]

    try:
        if ext == ".reg":
            # UTF-16 para archivos .reg
            with open(filepath, "r", encoding="utf-16", errors="ignore") as f:
                original = f.read()
            nuevo = "\n".join(comentario) + "\n\n" + original
            with open(filepath, "w", encoding="utf-16") as f:
                f.write(nuevo)
        else:
            # UTF-8 para todos los demás
            original = filepath.read_text(encoding="utf-8", errors="ignore")
            nuevo = "\n".join(comentario) + "\n\n" + original
            filepath.write_text(nuevo, encoding="utf-8")

        print(f"[✔] Comentario agregado: {filepath.name}")

    except Exception as e:
        print(f"[!] Error con {filepath.name}: {e}")
