-- Insert into table1 with fewer rows
INSERT INTO table1 (date, name)
SELECT CURRENT_DATE - (random() * 365)::INT, md5(random()::TEXT)
FROM generate_series(1, 100000);  

-- Insert into table2 with valid ids from table1
INSERT INTO table2 (t1_id, name)
SELECT t1.id, md5(random()::TEXT)
FROM table1 t1
ORDER BY random()
LIMIT 100000;  

-- Insert into table3 with valid random t2_id from table2
INSERT INTO table3 (t2_id, amount)
SELECT t2.id, random() * 1000
FROM table2 t2
ORDER BY random()
LIMIT 100000;

-- Insert into large_table (with fewer rows)
INSERT INTO large_table (data_column)
SELECT md5(random()::TEXT)
FROM generate_series(1, 1000000);
