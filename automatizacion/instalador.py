import os
import subprocess
import shutil
import platform

def run(cmd):
    print(f"Ejecutando: {cmd}")
    subprocess.run(cmd, shell=True, check=True)

def es_windows():
    return platform.system() == "Windows"

def clonar_repo():
    if shutil.which("git") is None:
        print("Git no está instalado. Por favor instálalo e intenta de nuevo.")
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
    print(f"Ejecuta iniciar_flask.py desde {destino} para lanzar el servidor")

    agregar_a_inicio(destino)

def agregar_a_inicio(destino):
    ruta_inicio = os.path.join(os.environ["APPDATA"], "Microsoft\\Windows\\Start Menu\\Programs\\Startup")
    ruta_script = os.path.join(destino, "iniciar_flask.py")
    ruta_bat = os.path.join(ruta_inicio, "lanzar_backend.bat")
    with open(ruta_bat, "w") as f:
        f.write(f"@echo off\ncd /d {destino}\npython iniciar_flask.py")
    print("El backend se lanzará automáticamente al iniciar Windows.")

def configurar_frontend(ip_backend="10.0.1.39"):
    if es_windows():
        print("En Windows no se instala Apache ni se configura el frontend. Solo aplica en Linux.")
        return

    origen_html = os.path.join("avance-proyecto-fddo", "aplicacionWeb", "templates", "index.html")
    origen_css = os.path.join("avance-proyecto-fddo", "aplicacionWeb", "static", "style.css")
    html_destino = "/var/www/html/index.html"
    css_destino = "/var/www/html/style.css"

    with open(origen_html, "r", encoding="utf-8") as f:
        contenido = f.read().replace("http://[IP_BACKEND]:5000", f"http://{ip_backend}:5000")
    with open("/tmp/index.html", "w", encoding="utf-8") as f:
        f.write(contenido)

    shutil.copy("/tmp/index.html", html_destino)
    shutil.copy(origen_css, css_destino)
    print("Frontend instalado en /var/www/html")

if __name__ == "__main__":
    clonar_repo()
    instalar_dependencias()
    if es_windows():
        configurar_backend()
    else:
        configurar_frontend()
