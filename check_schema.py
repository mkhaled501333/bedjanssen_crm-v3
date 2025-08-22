#!/usr/bin/env python3
import mysql.connector
from mysql.connector import Error

try:
    connection = mysql.connector.connect(
        host='localhost',
        user='root',
        password='Admin@1234',
        database='janssencrm'
    )

    if connection.is_connected():
        cursor = connection.cursor()
        cursor.execute("DESCRIBE ticket_items")
        columns = cursor.fetchall()

        print("ticket_items table columns:")
        for col in columns:
            print(f"  {col[0]}: {col[1]}")

        cursor.close()
        connection.close()

except Error as e:
    print(f"Error connecting to MySQL: {e}")
