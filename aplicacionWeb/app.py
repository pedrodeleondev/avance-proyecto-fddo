from flask import Flask, render_template, request, redirect, url_for
import pymysql
from urllib.parse import urlparse

app = Flask(__name__)

# ------- CONEXIÓN ----------
def get_connection():
    return pymysql.connect(
        host="bd-proyect-mysql.cis9zqmovwyf.us-east-1.rds.amazonaws.com",
        user="admin",
        password="proyecto98765", 
        database="proyecto_db",
        port=3306,
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
