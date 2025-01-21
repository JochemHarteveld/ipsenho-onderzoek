import psycopg2
from psycopg2.extras import execute_batch
from faker import Faker
import random
import time
from config import DB_SETTINGS, NUMBER_OF_USERS, NUMBER_OF_DNA_SAMPLES, NUMBER_OF_TRANSACTIONS, NUMBER_OF_LOGS

# Maak een Faker-instantie
fake = Faker()

# Function to establish a connection with retries
def get_connection():
    retries = 5
    for _ in range(retries):
        try:
            return psycopg2.connect(**DB_SETTINGS)
        except psycopg2.OperationalError:
            print("Connection failed, retrying...")
            time.sleep(5)  # Wait 5 seconds before retrying
    raise Exception("Unable to connect to database after several retries")


# Functie om tabellen te truncaten
def truncate_table(cursor, table_name):
    cursor.execute(f"TRUNCATE TABLE {table_name} RESTART IDENTITY CASCADE;")

# Functie om tabellen te creëren
def create_tables():
    with get_connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute("""
                -- Gebruikerstabel
                CREATE TABLE IF NOT EXISTS users (
                    user_id SERIAL PRIMARY KEY,
                    username VARCHAR(50) UNIQUE NOT NULL,
                    email VARCHAR(100) UNIQUE NOT NULL,
                    role VARCHAR(20) CHECK (role IN ('admin', 'student', 'docent')),
                    created_at TIMESTAMP DEFAULT NOW()
                );

                -- DNA-monsters tabel
                CREATE TABLE IF NOT EXISTS dna_samples (
                    sample_id SERIAL PRIMARY KEY,
                    user_id INTEGER REFERENCES users(user_id),
                    sequence TEXT NOT NULL,
                    analysis_date DATE DEFAULT CURRENT_DATE
                );

                -- Transacties tabel
                CREATE TABLE IF NOT EXISTS transactions (
                    transaction_id SERIAL PRIMARY KEY,
                    user_id INTEGER REFERENCES users(user_id),
                    amount NUMERIC(10,2) NOT NULL,
                    timestamp TIMESTAMP DEFAULT NOW()
                );

                -- Query-log tabel
                CREATE TABLE IF NOT EXISTS query_logs (
                    log_id SERIAL PRIMARY KEY,
                    user_id INTEGER REFERENCES users(user_id),
                    query_text TEXT NOT NULL,
                    execution_time NUMERIC(10,3),
                    logged_at TIMESTAMP DEFAULT NOW()
                );
            """)
            conn.commit()
    print("Tabellen succesvol aangemaakt!")

def seed_data():
    with get_connection() as conn:
        with conn.cursor() as cursor:
            # Truncate de tabellen
            truncate_table(cursor, "users")
            truncate_table(cursor, "dna_samples")
            truncate_table(cursor, "transactions")
            truncate_table(cursor, "query_logs")
            
            # Voeg users toe met gecontroleerde unieke usernames en e-mails
            users = []
            existing_usernames = set()
            existing_emails = set()  # Voeg set toe voor unieke e-mails
            
            while len(users) < NUMBER_OF_USERS:
                username = fake.user_name()
                email = fake.email()
                
                # Zorg ervoor dat de username en email uniek zijn
                if username not in existing_usernames and email not in existing_emails:
                    existing_usernames.add(username)
                    existing_emails.add(email)
                    users.append((username, email, random.choice(['admin', 'student', 'docent'])))
            
            execute_batch(cursor, "INSERT INTO users (username, email, role) VALUES (%s, %s, %s)", users)

            # Haal user_ids op
            cursor.execute("SELECT user_id FROM users")
            user_ids = [row[0] for row in cursor.fetchall()]

            # Voeg DNA-monsters toe
            dna_samples = [
                (random.choice(user_ids), fake.text(max_nb_chars=100))
                for _ in range(NUMBER_OF_DNA_SAMPLES)
            ]
            execute_batch(cursor, "INSERT INTO dna_samples (user_id, sequence) VALUES (%s, %s)", dna_samples)

            # Voeg transacties toe
            transactions = [
                (random.choice(user_ids), round(random.uniform(10, 500), 2))
                for _ in range(NUMBER_OF_TRANSACTIONS)
            ]
            execute_batch(cursor, "INSERT INTO transactions (user_id, amount) VALUES (%s, %s)", transactions)

            # Voeg logs toe
            query_logs = [
                (random.choice(user_ids), fake.sentence(), round(random.uniform(5, 100), 3))
                for _ in range(NUMBER_OF_LOGS)
            ]
            execute_batch(cursor, "INSERT INTO query_logs (user_id, query_text, execution_time) VALUES (%s, %s, %s)", query_logs)

            conn.commit()
    print(f"Testdata succesvol toegevoegd: {NUMBER_OF_USERS} users, {NUMBER_OF_DNA_SAMPLES} DNA-monsters, {NUMBER_OF_TRANSACTIONS} transacties, {NUMBER_OF_LOGS} logs.")


# Main functie
if __name__ == "__main__":
    create_tables()
    seed_data()
