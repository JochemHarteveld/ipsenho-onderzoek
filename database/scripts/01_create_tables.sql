CREATE TABLE table1 (
    id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    name TEXT NOT NULL
);

CREATE TABLE table2 (
    id SERIAL PRIMARY KEY,
    t1_id INT NOT NULL REFERENCES table1(id),
    name TEXT NOT NULL
);

CREATE TABLE table3 (
    id SERIAL PRIMARY KEY,
    t2_id INT NOT NULL REFERENCES table2(id),
    amount NUMERIC NOT NULL
);

CREATE TABLE large_table (
    id SERIAL PRIMARY KEY,
    data_column TEXT NOT NULL
);