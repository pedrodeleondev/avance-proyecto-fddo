import os
import subprocess
import shutil
import platform
import sys

def run(cmd):
    print(f"Ejecutando: {cmd}")
    subprocess.run(cmd, shell=True, check=True)

def es_windows():
    return platform.system() == "Windows"

def clonar_repo():
    if shutil.which("git") is None:
        print("Git no está instalado.")
        exit(1)
    if not os.path.exists("avance-proyecto-fddo"):
        run("git clone https://github.com/pedrodeleondev/avance-proyecto-fddo.git")

def instalar_dependencias():
    if es_windows():
        try:
            import pip
        except ImportError:
            run("python -m ensurepip --upgrade")
        run("python -m pip install --upgrade pip flask pymysql")
    else:
        run("sudo apt update && sudo apt install -y apache2")
        run("sudo systemctl enable apache2")
        run("sudo systemctl start apache2")

def configurar_backend():
    destino = r"C:\\flask_app" if es_windows() else os.path.expanduser("~/flask_app")
    if not os.path.exists(destino):
        os.makedirs(destino)

    origen = os.path.join(os.getcwd(), "avance-proyecto-fddo", "aplicacionWeb")
    for item in ["app.py", "templates", "static"]:
        src = os.path.join(origen, item)
        dst = os.path.join(destino, item)
        if os.path.isdir(src):
            if os.path.exists(dst):
                shutil.rmtree(dst)
            shutil.copytree(src, dst)
        else:
            shutil.copy2(src, dst)

    ruta_launcher = os.path.join(destino, "iniciar_flask.py")
    with open(ruta_launcher, "w", encoding="utf-8") as f:
        f.write('''from app import app
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
''')
    print(f"Backend configurado en {destino}")
    agregar_a_inicio(destino)
    # Ejecutar el servidor inmediatamente
    run(f"start /min cmd /c \"cd /d {destino} && python iniciar_flask.py\"")

def agregar_a_inicio(destino):
    ruta_inicio = os.path.join(os.environ["APPDATA"], "Microsoft\\Windows\\Start Menu\\Programs\\Startup")
    ruta_script = os.path.join(destino, "iniciar_flask.py")
    ruta_bat = os.path.join(ruta_inicio, "lanzar_backend.bat")
    with open(ruta_bat, "w") as f:
        f.write(f"@echo off\ncd /d {destino}\npython iniciar_flask.py")
    print("Backend configurado para arrancar al iniciar Windows.")

def configurar_frontend(ip_backend="10.0.1.39"):
    if not es_windows():
        print("Este script solo instala frontend en Windows con IIS.")
        return

    destino = r"C:\\inetpub\\wwwroot"
    origen_html = os.path.join("avance-proyecto-fddo", "aplicacionWeb", "templates", "index.html")
    origen_css = os.path.join("avance-proyecto-fddo", "aplicacionWeb", "static", "style.css")
    if not os.path.exists(destino):
        os.makedirs(destino)

    with open(origen_html, "r", encoding="utf-8") as f:
        contenido = f.read().replace("http://[IP_BACKEND]:5000", f"http://{ip_backend}:5000")
    with open(os.path.join(destino, "index.html"), "w", encoding="utf-8") as f:
        f.write(contenido)
    shutil.copy(origen_css, os.path.join(destino, "style.css"))
    print(f"HTML y CSS copiados a {destino}")
    print("Verifica que IIS esté activo en esta instancia.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("USO: python instalador.py frontend | backend")
        exit(1)

    modo = sys.argv[1].lower()
    clonar_repo()
    instalar_dependencias()

    if modo == "frontend":
        configurar_frontend()
    elif modo == "backend":
        configurar_backend()
    else:
        print("Modo inválido. Usa 'frontend' o 'backend'.")
