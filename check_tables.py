#!/usr/bin/env python3
import mysql.connector

def check_tables():
    """Check both call_categories and call_reasons tables."""

    try:
        connection = mysql.connector.connect(
            host='localhost',
            user='root',
            password='Admin@1234',
            database='janssencrm',
            port=3306
        )

        cursor = connection.cursor()

        # Check both possible table names
        tables_to_check = ['call_categories', 'call_reasons']

        print("=== Checking Table Names and Structures ===\n")

        for table in tables_to_check:
            cursor.execute(f'SHOW TABLES LIKE "{table}"')
            if cursor.fetchone():
                print(f'✓ Table "{table}" exists')

                # Check table structure
                cursor.execute(f'DESCRIBE {table}')
                columns = cursor.fetchall()
                print(f'  Columns in {table}:')
                for col in columns:
                    print(f'    {col[0]} - {col[1]}')

                # Check data count
                cursor.execute(f'SELECT COUNT(*) FROM {table}')
                count = cursor.fetchone()[0]
                print(f'  Records in {table}: {count}')

                if count > 0:
                    print(f'  Sample data from {table}:')
                    cursor.execute(f'SELECT * FROM {table} LIMIT 3')
                    rows = cursor.fetchall()
                    for row in rows:
                        print(f'    {row}')
                print()
            else:
                print(f'✗ Table "{table}" does not exist\n')

        # Also check what tables exist with 'call' in the name
        print("=== All Tables with 'call' in the name ===")
        cursor.execute("SHOW TABLES LIKE '%call%'")
        call_tables = cursor.fetchall()
        for table in call_tables:
            print(f"  - {table[0]}")

        cursor.close()
        connection.close()

    except Exception as e:
        print(f'Error: {e}')

if __name__ == "__main__":
    check_tables()
