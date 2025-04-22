from flask import Flask, render_template, request, redirect, url_for
import pymysql
from urllib.parse import urlparse

app = Flask(__name__)

# ---------- CONEXIÓN DESDE URI ----------
db_url = 'mysql://root:wyGyirKMoKGNyOjHnwPzxVmnFTVzYsKN@crossover.proxy.rlwy.net:37763/railway'
parsed_url = urlparse(db_url)

def get_connection():
    return pymysql.connect(
        host=parsed_url.hostname,
        user=parsed_url.username,
        password=parsed_url.password,
        database=parsed_url.path.lstrip('/'),
        port=parsed_url.port,
        cursorclass=pymysql.cursors.DictCursor
    )

# ---------- RUTAS ----------

@app.route('/')
def index():
    conn = get_connection()
    with conn.cursor() as cursor:
        cursor.execute("SELECT * FROM productos")
        productos = cursor.fetchall()
    conn.close()
    return render_template('index.html', productos=productos)

@app.route('/agregar', methods=['POST'])
def agregar():
    nombre = request.form['nombre']
    cantidad = request.form['cantidad']
    precio = request.form['precio']
    conn = get_connection()
    with conn.cursor() as cursor:
        cursor.execute(
            "INSERT INTO productos (nombre, cantidad, precio) VALUES (%s, %s, %s)",
            (nombre, cantidad, precio)
        )
    conn.commit()
    conn.close()
    return redirect(url_for('index'))

@app.route('/editar/<int:id>', methods=['POST'])
def editar(id):
    nombre = request.form['nombre']
    cantidad = request.form['cantidad']
    precio = request.form['precio']
    conn = get_connection()
    with conn.cursor() as cursor:
        cursor.execute(
            "UPDATE productos SET nombre=%s, cantidad=%s, precio=%s WHERE id=%s",
            (nombre, cantidad, precio, id)
        )
    conn.commit()
    conn.close()
    return redirect(url_for('index'))

@app.route('/eliminar/<int:id>')
def eliminar(id):
    conn = get_connection()
    with conn.cursor() as cursor:
        cursor.execute("DELETE FROM productos WHERE id=%s", (id,))
    conn.commit()
    conn.close()
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(debug=True)
