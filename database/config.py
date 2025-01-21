# config.py
import os 

# Aantal testrecords
NUMBER_OF_USERS = 1000
NUMBER_OF_DNA_SAMPLES = 2000
NUMBER_OF_TRANSACTIONS = 3000
NUMBER_OF_LOGS = 5000

# PostgreSQL instellingen
DB_SETTINGS = {
    "dbname": "testdb",
    "host": "postgres", 
    "port": 5432,
    "user":"postgres",
    "password":"postgres"
}
