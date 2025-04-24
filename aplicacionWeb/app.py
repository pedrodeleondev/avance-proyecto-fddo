from flask import Flask, request, jsonify
import pymysql

app = Flask(__name__)

def get_connection():
    return pymysql.connect(
        host="bd-proyect-mysql.cis9zqmovwyf.us-east-1.rds.amazonaws.com",
        user="admin",
        password="proyecto98765", 
        database="proyecto_db",
        port=3306,
        cursorclass=pymysql.cursors.DictCursor
    )

@app.route('/productos', methods=['GET'])
def obtener_productos():
    conn = get_connection()
    with conn.cursor() as cursor:
        cursor.execute("SELECT * FROM productos")
        productos = cursor.fetchall()
    conn.close()
    return jsonify(productos)

@app.route('/agregar', methods=['POST'])
def agregar():
    data = request.json
    nombre = data['nombre']
    cantidad = data['cantidad']
    precio = data['precio']
    conn = get_connection()
    with conn.cursor() as cursor:
        cursor.execute(
            "INSERT INTO productos (nombre, cantidad, precio) VALUES (%s, %s, %s)",
            (nombre, cantidad, precio)
        )
    conn.commit()
    conn.close()
    return jsonify({"mensaje": "Producto agregado"}), 201

@app.route('/editar/<int:id>', methods=['PUT'])
def editar(id):
    data = request.json
    nombre = data['nombre']
    cantidad = data['cantidad']
    precio = data['precio']
    conn = get_connection()
    with conn.cursor() as cursor:
        cursor.execute(
            "UPDATE productos SET nombre=%s, cantidad=%s, precio=%s WHERE id=%s",
            (nombre, cantidad, precio, id)
        )
    conn.commit()
    conn.close()
    return jsonify({"mensaje": "Producto actualizado"})

@app.route('/eliminar/<int:id>', methods=['DELETE'])
def eliminar(id):
    conn = get_connection()
    with conn.cursor() as cursor:
        cursor.execute("DELETE FROM productos WHERE id=%s", (id,))
    conn.commit()
    conn.close()
    return jsonify({"mensaje": "Producto eliminado"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
