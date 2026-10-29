CREATE DATABASE IF NOT EXISTS tailor_db;
USE tailor_db;

CREATE TABLE IF NOT EXISTS tailor_order (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer VARCHAR(40) NOT NULL,
    garment VARCHAR(20) NOT NULL,
    delivery_date DATE NOT NULL,
    notes TEXT
);

