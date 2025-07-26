-- ##############################register table##############################

CREATE TABLE register (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('super_admin', 'admin', 'project_manager', 'architect', 'accountant', 'site_engineer') NOT NULL,
    contact_no VARCHAR(20),
    status ENUM('active', 'disabled') DEFAULT 'active'
);



-- ##########################projects table###################################

CREATE TABLE projects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_name VARCHAR(255) NOT NULL,
    architect_id INT,
    site_engineer_id INT,
    site_id INT,
    FOREIGN KEY (architect_id) REFERENCES architects(id) ON DELETE SET NULL,
    FOREIGN KEY (site_engineer_id) REFERENCES site_engineers(id) ON DELETE SET NULL
);


-- ########################################sites table ###############################################

CREATE TABLE sites (
    site_id INT AUTO_INCREMENT PRIMARY KEY,
    site_name VARCHAR(100) NOT NULL,
    location VARCHAR(255) NOT NULL,
    site_engineer_id INT NOT NULL,
    architect_id INT,
    FOREIGN KEY (site_engineer_id) REFERENCES site_engineers(id) ON DELETE CASCADE,
    FOREIGN KEY (architect_id) REFERENCES architects(id) ON DELETE SET NULL
);