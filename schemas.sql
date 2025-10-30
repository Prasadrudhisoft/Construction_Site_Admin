
--######################################################## Main ERP Tables ##########################################################
-- ############################## register table ##############################

CREATE TABLE IF NOT EXISTS register (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('super_admin', 'admin', 'project_manager', 'architect', 'accountant', 'site_engineer') NOT NULL,
    contact_no VARCHAR(20),
    org_id INT NOT NULL,
    status ENUM('active', 'disabled') DEFAULT 'active'
);

--############################################## architects table ##########################################

CREATE TABLE IF NOT EXISTS architects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    license_number VARCHAR(50),
    contact_no VARCHAR(15),
    email VARCHAR(100),
    project_name VARCHAR(255),
    site_engineer_id INT,
    register_id INT,
    org_id INT NOT NULL,
    FOREIGN KEY (register_id) REFERENCES register(id) ON DELETE SET NULL
);

-- ######################################## architect_projects table ##########################################

CREATE TABLE IF NOT EXISTS  architect_projects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    architect_id INT,
    project_name VARCHAR(255),
    building_usage VARCHAR(100),
    num_floors INT,
    area_sqft FLOAT,
    plot_area FLOAT,
    fsi VARCHAR(50),
    architect_name VARCHAR(100),
    org_id INT NOT NULL,
    FOREIGN KEY (architect_id) REFERENCES architects(id) ON DELETE SET NULL
);

-- ########################## projects table ###################################

CREATE TABLE IF NOT EXISTS   projects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_name VARCHAR(255) NOT NULL,
    architect_id INT,
    site_engineer_id INT,
    site_id INT,
    org_id INT NOT NULL
);


-- ############################## daily_worker_report table ######################################

CREATE TABLE  IF NOT EXISTS daily_worker_report (
    id INT AUTO_INCREMENT PRIMARY KEY,
    site_engineer_id INT NOT NULL,
    project_id INT NOT NULL,
    worker_count INT NOT NULL,
    report_date DATE NOT NULL,
    org_id INT NOT NULL,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);


--#################################### design_details table ####################################

CREATE TABLE  IF NOT EXISTS design_details (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT,
    architect_id INT,
    building_usage VARCHAR(100),
    num_floors INT,
    area_sqft FLOAT,
    plot_area FLOAT,
    fsi VARCHAR(50),
    org_id INT NOT NULL
);


--############################################### drawing_documents table ###################################

CREATE TABLE IF NOT EXISTS drawing_documents (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    architect_id INT,
    layout_type ENUM(
        'Architectural Layout',
        'Elevation Drawing',
        'Section/Structural',
        'Electrical',
        'Plumbing/Sanitation'
    ) NOT NULL,
    document_title VARCHAR(255) NOT NULL,
    file_path VARCHAR(255) NOT NULL,
    uploaded_on DATETIME DEFAULT CURRENT_TIMESTAMP,
    uploaded_by INT,
    org_id INT NOT NULL
);




-- ################################## enquiries table ########################################

CREATE TABLE IF NOT EXISTS enquiries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    site_engineer_id INT,
    name VARCHAR(100) NOT NULL,
    address TEXT NOT NULL,
    contact_no VARCHAR(15) NOT NULL,
    requirement TEXT NOT NULL,
    enquiry_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    org_id INT NOT NULL
);

--########################################### inventory table #############################################
CREATE TABLE  IF NOT EXISTS inventory (
    material_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    material_description VARCHAR(255) NOT NULL,
    quantity INT NOT NULL,
    date DATE NOT NULL,
    org_id INT NOT NULL,
    status ENUM('available', 'low', 'out_of_stock', 'ordered') NOT NULL,
    site_engineer_id INT NOT NULL,
);



-- ############################# invoice_items table ##################################

CREATE TABLE IF NOT EXISTS invoice_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id INT NOT NULL,
    description VARCHAR(255) NOT NULL,
    quantity INT NOT NULL,
    rate DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    org_id INT NOT NULL,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
);


-- i###################################### invoices table ###########################

CREATE TABLE IF NOT EXISTS invoices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    site_engineer_id INT NOT NULL,
    vendor_name VARCHAR(255),
    total_amount DECIMAL(10,2) NOT NULL,
    generated_on DATETIME DEFAULT CURRENT_TIMESTAMP,
    pdf_filename VARCHAR(255),
    gst_amount DECIMAL(10,2) DEFAULT 0.00,
    invoice_number VARCHAR(50),
    bill_to_name VARCHAR(255),
    bill_to_address TEXT,
    bill_to_phone VARCHAR(20),
    subtotal DECIMAL(10,2),
    status VARCHAR(20) DEFAULT 'Pending',
    rejection_reason TEXT,
    approved_by INT,
    approved_on DATETIME,
    project_id INT,
    invoice_image_filename VARCHAR(255),
    org_id INT NOT NULL,
    FOREIGN KEY (approved_by) REFERENCES register(id) ON DELETE SET NULL,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE SET NULL
);

-- ############################### legal_and_compliances table #########################################

CREATE TABLE IF NOT EXISTS legal_and_compliances (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL,
    municipal_approval_status ENUM('Approved', 'Not Approved') NOT NULL,
    municipal_approval_pdf VARCHAR(255),
    building_permit_pdf VARCHAR(255),
    sanction_plan_pdf VARCHAR(255),
    fire_department_noc_pdf VARCHAR(255),
    environmental_clearance TEXT,
    uploaded_on DATETIME DEFAULT CURRENT_TIMESTAMP,
    mngl_pdf VARCHAR(255),
    org_id INT NOT NULL,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);


-- ############################ material_specifications table ######################################### 

CREATE TABLE  IF NOT EXISTS material_specifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT,
    architect_id INT,
    primary_material VARCHAR(100),
    wall_material VARCHAR(100),
    roofing_material VARCHAR(100),
    flooring_material VARCHAR(100),
    fire_safety_materials TEXT,
    org_id INT NOT NULL
);

--################################ progress_reports table ############################

CREATE TABLE IF NOT EXISTS progress_reports (
    report_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    site_id INT NOT NULL,
    progress_percent INT NOT NULL,
    image_path VARCHAR(255) DEFAULT NULL,
    pdf_path VARCHAR(255) DEFAULT NULL,
    report_date DATE NOT NULL,
    remark VARCHAR(255) DEFAULT NULL,
    org_id INT NOT NULL,
    INDEX (site_id),
    INDEX (org_id)
);

-- ########################################## messages table ##########################################
CREATE TABLE IF NOT EXISTS messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT NOT NULL,
    receiver_id INT NOT NULL,
    message TEXT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_read TINYINT(1) DEFAULT 0,
    org_id INT NOT NULL,
    FOREIGN KEY (sender_id) REFERENCES register(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES register(id) ON DELETE CASCADE
);

-- ############### salaries table ##############################

CREATE TABLE IF NOT EXISTS salaries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT,
    user_id INT,
    role VARCHAR(50),
    month_year VARCHAR(7),  -- Format: YYYY-MM
    base_salary DECIMAL(10,2),
    allowance DECIMAL(10,2),
    pf DECIMAL(10,2),
    advance DECIMAL(10,2) DEFAULT 0.00,
    description VARCHAR(255),
    created_by INT,
    created_on DATETIME DEFAULT CURRENT_TIMESTAMP,
    payment_mode ENUM('cash', 'cheque') NOT NULL DEFAULT 'cash',
    cheque_number VARCHAR(50),
    org_id INT NOT NULL,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE SET NULL,
    FOREIGN KEY (user_id) REFERENCES register(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES register(id) ON DELETE SET NULL
);


-- #################################### site_conditions table #######################################

CREATE TABLE IF NOT EXISTS site_conditions (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL UNIQUE,
    architect_id INT,
    soil_report_path VARCHAR(255),
    water_table_level VARCHAR(100),
    topo_counter_map_path VARCHAR(255),
    uploaded_on DATETIME DEFAULT CURRENT_TIMESTAMP,
    org_id INT NOT NULL
);

-- ######################################## sites table ###############################################

CREATE TABLE IF NOT EXISTS sites (
    site_id INT AUTO_INCREMENT PRIMARY KEY,
    site_name VARCHAR(100) NOT NULL,
    location VARCHAR(255) NOT NULL,
    site_engineer_id INT NOT NULL,
    architect_id INT,
    org_id INT NOT NULL,
    FOREIGN KEY (architect_id) REFERENCES architects(id) ON DELETE SET NULL
);



-- #############################structural_details table###############################################

CREATE TABLE IF NOT EXISTS structural_details (
    id INT AUTO_INCREMENT PRIMARY KEY,
    project_id INT,
    architect_id INT,
    foundation_type VARCHAR(100),
    framing_system VARCHAR(100),
    slab_type VARCHAR(100),
    beam_details TEXT,
    load_calculation TEXT,
    org_id INT NOT NULL
);



-- #######################utilities_services table#############################################

CREATE TABLE IF NOT EXISTS utilities_services (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    project_id INT NOT NULL UNIQUE,
    architect_id INT,
    water_supply_source VARCHAR(255),
    drainage_system_type VARCHAR(255),
    power_supply_source VARCHAR(255),
    uploaded_on DATETIME DEFAULT CURRENT_TIMESTAMP,
    org_id INT NOT NULL
);




-- ####################vendor_inventory table##################################

CREATE TABLE IF NOT EXISTS vendor_inventory (
    id INT AUTO_INCREMENT PRIMARY KEY,
    material_description VARCHAR(255) NOT NULL,
    quantity INT NOT NULL,
    date DATE NOT NULL,
    status ENUM('available', 'low', 'out_of_stock', 'ordered') NOT NULL,
    vendor_name VARCHAR(100) NOT NULL,
    vendor_quotation_pdf VARCHAR(255),
    admin_remark VARCHAR(255),
    admin_approval ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
    vendor_type ENUM('electrical', 'plumber', 'carpenter', 'painter', 'other') NOT NULL DEFAULT 'other',
    org_id INT NOT NULL
);


-- ##################################### accountant_projects table ######################################

CREATE TABLE IF NOT EXISTS accountant_projects (
    id INT AUTO_INCREMENT PRIMARY KEY,
    accountant_id INT NOT NULL,
    project_id INT NOT NULL,
    org_id INT NOT NULL,
    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE
);



-----------############ cost_estimation table #######################################################

CREATE TABLE IF NOT EXISTS cost_estimation (
    id INT AUTO_INCREMENT PRIMARY KEY,
    architectural_design_cost FLOAT,
    structural_design_cost FLOAT,
    estimation_summary TEXT,
    boq_reference TEXT,
    cost_per_sqft FLOAT,
    report_pdf_path VARCHAR(255),
    uploaded_on DATETIME DEFAULT CURRENT_TIMESTAMP,
    project_id INT,
    architect_id INT,
    generated_on DATETIME DEFAULT CURRENT_TIMESTAMP,
    org_id INT NOT NULL
);

-----------################################### ORGANIZATION TABLE ##########################################
CREATE TABLE IF NOT EXISTS organization_master (
    org_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    admin_id INT DEFAULT NULL,
    role ENUM('super_admin', 'admin', 'project_manager', 'architect', 'accountant', 'site_engineer') NOT NULL,
    company_name VARCHAR(255) NOT NULL,
    company_address VARCHAR(255) NOT NULL,
    company_phone VARCHAR(20) NOT NULL,
    company_email VARCHAR(100) NOT NULL,
    bank_name VARCHAR(100),
    bank_account VARCHAR(50),
    ifsc_code VARCHAR(20),
    gst_number VARCHAR(20),
    terms_conditions VARCHAR(200)
);
-----------######################################## daily_expenses table ##########################################
CREATE TABLE IF NOT EXISTS daily_expenses (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    site_engineer_id INT,
    org_id INT,
    project_id INT,
    date DATE,
    description TEXT,
    amount DECIMAL(10,2),
    status ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
    admin_comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
