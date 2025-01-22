# Benchmark Onderzoek - PostgreSQL Configuraties

Dit document beschrijft de stappen voor het opzetten van de testomgeving, het uitvoeren van benchmarks, en het verkrijgen van resultaten met betrekking tot verschillende configuraties van de PostgreSQL-database.

## Stap 1: Opzet van de Testomgeving

1. **Download de repository**:
   - Unzip de repository uit de bijlagen, of
   - Clone de repository met het volgende commando:
     ```bash
     git clone https://github.com/JochemHarteveld/ipsenho-onderzoek.git
     ```

## Stap 2: Stel de Configuratie in

2. **Wijzig de configuratie van PostgreSQL**:

   - Open het bestand `postgresql.conf` in de PostgreSQL-configuratiemap.
   - Stel de volgende variabelen in:
     - `shared_buffers`
     - `work_mem`
   - Sla het bestand op.
   - De eenheid van deze variabelen is in bytes (bijvoorbeeld: `128MB`, `1GB`, `64kB`).

   **Configuraties die getest worden**:

   | **shared_buffers**           | **work_mem** |
   | ---------------------------- | ------------ | --- |
   | **Configuratie 1 (default)** | 128MB        | 1MB |
   | **Configuratie 2**           | 4GB          | 1MB |
   | **Configuratie 3**           | 128MB        | 1GB |
   | **Configuratie 4**           | 4GB          | 1GB |

   Deze waarden zijn gekozen om te onderzoeken of hogere waarden invloed hebben op de prestaties.

## Stap 3: Start de Container

3. **Start de PostgreSQL-container**:
   - In de root van de repository, voer het volgende commando uit om de PostgreSQL-database te starten:
     ```bash
     docker compose up
     ```
   - De eerste keer dat je dit commando uitvoert, is er nog geen testdata in de database. PostgreSQL zal dit detecteren en de initialisatiebestanden uitvoeren.
   - De initialisatiebestanden bevinden zich in de map `database/scripts` en worden in volgorde uitgevoerd.

## Stap 4: Voer de Test Uit

4. **Controleer de naam van de container**:

   - Gebruik het commando `docker ps` om de naam van de container te vinden.

5. **Voer het testscript uit**:

   - Voer het benchmarktestscript uit vanaf je lokale machine met het volgende commando:
     ```bash
     docker exec -it <container_naam> tests/run_benchmark.sh <aantal_tests>
     ```

   Vervang `<container_naam>` door de naam van de container en `<aantal_tests>` door het aantal gewenste tests.

## Stap 5: De Resultaten

6. **Resultaten ophalen**:
   - Na het uitvoeren van de tests, zijn de resultaten beschikbaar in de map `logs`.
   - Als je opnieuw een test wilt uitvoeren, stop dan de PostgreSQL-container met het volgende commando:
     ```bash
     docker compose down
     ```
   - Voer het proces opnieuw uit vanaf stap 2.

## Opmerkingen

- Zorg ervoor dat Docker is geïnstalleerd en correct werkt op je machine voordat je begint.
- Het aantal tests en de configuraties kunnen worden aangepast afhankelijk van je onderzoeksbehoeften.
