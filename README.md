1. Clone repository

2. docker compose up

De docker compose file start de postgresql service op. Deze voert tijdens het opstarten de scripts in database/scripts uit.

- 01_create_tables.sql => Maakt de tabellen aan nodig in de configuratie die we gaan testen.
- 02_seed_tables.sql => Vult de tabellen met random testdata.

3. Verbinden met de PostgreSQL-database:

   Klik in pgAdmin op Add New Server.
   Vul de verbindingsgegevens in:
   Name: Hemiron DB (of een naam naar keuze).
   Host: postgres (de naam van de container).
   Port: 5432 (standaard PostgreSQL poort).
   Username: user (zoals gedefinieerd in je docker-compose.yml).
   Password: password (zoals gedefinieerd in je docker-compose.yml).
   Klik op Save.
