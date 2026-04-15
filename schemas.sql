-- ============================================================
-- 1. register
-- ============================================================
CREATE TABLE IF NOT EXISTS register (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(100)  NOT NULL,
    email         VARCHAR(150)  NOT NULL UNIQUE,
    password_hash VARCHAR(255)  NOT NULL,
    role          ENUM('super_admin','admin','project_manager','architect','accountant','site_engineer') NOT NULL,
    contact_no    VARCHAR(20),
    org_id        INT           NOT NULL,
    status        ENUM('active','disabled') DEFAULT 'active',

    INDEX idx_reg_org      (org_id),
    INDEX idx_reg_role     (role),
    INDEX idx_reg_org_role (org_id, role),
    INDEX idx_register_email (email),
    INDEX idx_register_org_role_name (org_id, role, name)
);


-- ============================================================
-- 2. organization_master
-- ============================================================
CREATE TABLE IF NOT EXISTS organization_master (
    org_id            INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    admin_id          INT          DEFAULT NULL,
    role              ENUM('super_admin','admin','project_manager','architect','accountant','site_engineer') NOT NULL,
    company_name      VARCHAR(255) NOT NULL,
    company_address   VARCHAR(255) NOT NULL,
    company_phone     VARCHAR(20)  NOT NULL,
    company_email     VARCHAR(100) NOT NULL,
    bank_name         VARCHAR(100),
    bank_account      VARCHAR(50),
    ifsc_code         VARCHAR(20),
    gst_number        VARCHAR(20),
    terms_conditions  VARCHAR(200)
);


-- ============================================================
-- 3. architects
-- ============================================================
CREATE TABLE IF NOT EXISTS architects (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    name             VARCHAR(100),
    license_number   VARCHAR(50),
    contact_no       VARCHAR(15),
    email            VARCHAR(100),
    project_name     VARCHAR(255),
    site_engineer_id INT,
    register_id      INT,
    org_id           INT NOT NULL,

    FOREIGN KEY (register_id) REFERENCES register(id) ON DELETE SET NULL,

    INDEX idx_arch_org         (org_id),
    INDEX idx_arch_register_id (register_id),
    INDEX idx_arch_site_engineer (site_engineer_id, org_id)
);


-- ============================================================
-- 4. architect_projects
-- ============================================================
CREATE TABLE IF NOT EXISTS architect_projects (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    architect_id    INT,
    project_name    VARCHAR(255),
    building_usage  VARCHAR(100),
    num_floors      INT,
    area_sqft       FLOAT,
    plot_area       FLOAT,
    fsi             VARCHAR(50),
    architect_name  VARCHAR(100),
    org_id          INT NOT NULL,

    FOREIGN KEY (architect_id) REFERENCES architects(id) ON DELETE SET NULL,

    INDEX idx_ap_org      (org_id),
    INDEX idx_ap_arch_id  (architect_id)
);


-- ============================================================
-- 5. sites
-- ============================================================
CREATE TABLE IF NOT EXISTS sites (
    site_id          INT AUTO_INCREMENT PRIMARY KEY,
    site_name        VARCHAR(100) NOT NULL,
    location         VARCHAR(255) NOT NULL,
    site_engineer_id INT          NOT NULL,
    architect_id     INT,
    org_id           INT          NOT NULL,

    FOREIGN KEY (architect_id) REFERENCES architects(id) ON DELETE SET NULL,

    INDEX idx_sites_org     (org_id),
    INDEX idx_sites_eng_org (site_engineer_id, org_id),
    INDEX idx_sites_engineer_org_name (site_engineer_id, org_id, site_name),
    INDEX idx_sites_org_name (org_id, site_name)
);


-- ============================================================
-- 6. projects
-- ============================================================
CREATE TABLE IF NOT EXISTS projects (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    project_name     VARCHAR(255) NOT NULL,
    architect_id     INT,
    site_engineer_id INT,
    site_id          INT,
    org_id           INT NOT NULL,

    INDEX idx_proj_org  (org_id),
    INDEX idx_proj_arch (architect_id),
    INDEX idx_proj_site (site_id),
    INDEX idx_projects_org_name (org_id, project_name),
    INDEX idx_projects_architect_org (architect_id, org_id, id, project_name),
    INDEX idx_projects_site_engineer (site_engineer_id, org_id, id, project_name),
    INDEX idx_projects_site_org (site_id, org_id),
    INDEX idx_projects_org_name_asc (org_id, project_name)
);


-- ============================================================
-- 7. accountant_projects
-- ============================================================
CREATE TABLE IF NOT EXISTS accountant_projects (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    accountant_id INT NOT NULL,
    project_id    INT NOT NULL,
    org_id        INT NOT NULL,

    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,

    INDEX idx_accp_acc_org  (accountant_id, org_id),
    INDEX idx_accp_proj     (project_id),
    INDEX idx_accp_project_org (project_id, org_id),
    INDEX idx_accp_lookup (accountant_id, project_id, org_id)
);


-- ============================================================
-- 8. design_details
-- ============================================================
CREATE TABLE IF NOT EXISTS design_details (
    id             INT AUTO_INCREMENT PRIMARY KEY,
    project_id     INT,
    architect_id   INT,
    building_usage VARCHAR(100),
    num_floors     INT,
    area_sqft      FLOAT,
    plot_area      FLOAT,
    fsi            VARCHAR(50),
    org_id         INT NOT NULL,

    INDEX idx_dd_project_org (project_id, org_id)
);


-- ============================================================
-- 9. structural_details
-- ============================================================
CREATE TABLE IF NOT EXISTS structural_details (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    project_id       INT,
    architect_id     INT,
    foundation_type  VARCHAR(100),
    framing_system   VARCHAR(100),
    slab_type        VARCHAR(100),
    beam_details     TEXT,
    load_calculation TEXT,
    org_id           INT NOT NULL,

    INDEX idx_sd_project_org (project_id, org_id)
);


-- ============================================================
-- 10. material_specifications
-- ============================================================
CREATE TABLE IF NOT EXISTS material_specifications (
    id                   INT AUTO_INCREMENT PRIMARY KEY,
    project_id           INT,
    architect_id         INT,
    primary_material     VARCHAR(100),
    wall_material        VARCHAR(100),
    roofing_material     VARCHAR(100),
    flooring_material    VARCHAR(100),
    fire_safety_materials TEXT,
    org_id               INT NOT NULL,

    INDEX idx_ms_project_org (project_id, org_id)
);


-- ============================================================
-- 11. site_conditions
-- ============================================================
CREATE TABLE IF NOT EXISTS site_conditions (
    id                   INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    project_id           INT NOT NULL UNIQUE,
    architect_id         INT,
    soil_report_path     VARCHAR(255),
    water_table_level    VARCHAR(100),
    topo_counter_map_path VARCHAR(255),
    uploaded_on          DATETIME DEFAULT CURRENT_TIMESTAMP,
    org_id               INT NOT NULL,

    INDEX idx_sc_org (org_id)
);


-- ============================================================
-- 12. utilities_services
-- ============================================================
CREATE TABLE IF NOT EXISTS utilities_services (
    id                   INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    project_id           INT NOT NULL UNIQUE,
    architect_id         INT,
    water_supply_source  VARCHAR(255),
    drainage_system_type VARCHAR(255),
    power_supply_source  VARCHAR(255),
    uploaded_on          DATETIME DEFAULT CURRENT_TIMESTAMP,
    org_id               INT NOT NULL,

    INDEX idx_us_org (org_id)
);


-- ============================================================
-- 13. drawing_documents
-- ============================================================
CREATE TABLE IF NOT EXISTS drawing_documents (
    id             INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    project_id     INT NOT NULL,
    architect_id   INT,
    layout_type    ENUM(
                       'Architectural Layout',
                       'Elevation Drawing',
                       'Section/Structural',
                       'Electrical',
                       'Plumbing/Sanitation'
                   ) NOT NULL,
    document_title VARCHAR(255) NOT NULL,
    file_path      VARCHAR(255) NOT NULL,
    uploaded_on    DATETIME DEFAULT CURRENT_TIMESTAMP,
    uploaded_by    INT,
    org_id         INT NOT NULL,

    INDEX idx_drw_project_org (project_id, org_id),
    INDEX idx_drawing_project_type (project_id, org_id, layout_type)
);


-- ============================================================
-- 14. cost_estimation
-- ============================================================
CREATE TABLE IF NOT EXISTS cost_estimation (
    id                       INT AUTO_INCREMENT PRIMARY KEY,
    architectural_design_cost FLOAT,
    structural_design_cost   FLOAT,
    estimation_summary       TEXT,
    boq_reference            TEXT,
    cost_per_sqft            FLOAT,
    report_pdf_path          VARCHAR(255),
    uploaded_on              DATETIME DEFAULT CURRENT_TIMESTAMP,
    project_id               INT,
    architect_id             INT,
    generated_on             DATETIME DEFAULT CURRENT_TIMESTAMP,
    org_id                   INT NOT NULL,

    INDEX idx_ce_proj_org (project_id, org_id),
    INDEX idx_cost_project_org (project_id, org_id, generated_on DESC)
);


-- ============================================================
-- 15. legal_and_compliances
-- ============================================================
CREATE TABLE IF NOT EXISTS legal_and_compliances (
    id                       INT AUTO_INCREMENT PRIMARY KEY,
    project_id               INT NOT NULL,
    municipal_approval_status ENUM('Approved','Not Approved') NOT NULL,
    municipal_approval_pdf   VARCHAR(255),
    building_permit_pdf      VARCHAR(255),
    sanction_plan_pdf        VARCHAR(255),
    fire_department_noc_pdf  VARCHAR(255),
    environmental_clearance  TEXT,
    uploaded_on              DATETIME DEFAULT CURRENT_TIMESTAMP,
    mngl_pdf                 VARCHAR(255),
    org_id                   INT NOT NULL,

    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,

    INDEX idx_lc_project_org (project_id, org_id),
    INDEX idx_lc_org         (org_id),
    INDEX idx_legal_project_status (project_id, org_id, municipal_approval_status)
);


-- ============================================================
-- 16. invoices
-- ============================================================
CREATE TABLE IF NOT EXISTS invoices (
    id                     INT AUTO_INCREMENT PRIMARY KEY,
    site_engineer_id       INT NOT NULL,
    vendor_name            VARCHAR(255),
    total_amount           DECIMAL(10,2) NOT NULL,
    generated_on           DATETIME DEFAULT CURRENT_TIMESTAMP,
    pdf_filename           VARCHAR(255),
    gst_amount             DECIMAL(10,2) DEFAULT 0.00,
    invoice_number         VARCHAR(50),
    bill_to_name           VARCHAR(255),
    bill_to_address        TEXT,
    bill_to_phone          VARCHAR(20),
    subtotal               DECIMAL(10,2),
    status                 VARCHAR(20) DEFAULT 'Pending',
    rejection_reason       TEXT,
    approved_by            INT,
    approved_on            DATETIME,
    project_id             INT,
    invoice_image_filename VARCHAR(255),
    org_id                 INT NOT NULL,

    FOREIGN KEY (approved_by) REFERENCES register(id) ON DELETE SET NULL,
    FOREIGN KEY (project_id)  REFERENCES projects(id) ON DELETE SET NULL,

    INDEX idx_inv_org_status (org_id, status),
    INDEX idx_inv_engineer   (site_engineer_id),
    INDEX idx_inv_project    (project_id),
    INDEX idx_inv_org_date   (org_id, generated_on),
    INDEX idx_invoices_engineer_status (site_engineer_id, org_id, status, generated_on),
    INDEX idx_invoices_org_status_created (org_id, status, generated_on),
    INDEX idx_invoices_number_org (invoice_number, org_id)
);


-- ============================================================
-- 17. invoice_items
-- ============================================================
CREATE TABLE IF NOT EXISTS invoice_items (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id  INT           NOT NULL,
    description VARCHAR(255)  NOT NULL,
    quantity    INT           NOT NULL,
    rate        DECIMAL(10,2) NOT NULL,
    subtotal    DECIMAL(10,2) NOT NULL,
    org_id      INT           NOT NULL,

    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,

    INDEX idx_ii_invoice_org (invoice_id, org_id)
);


-- ============================================================
-- 18. inventory
-- ============================================================
CREATE TABLE IF NOT EXISTS inventory (
    material_id          INT AUTO_INCREMENT PRIMARY KEY,
    material_description VARCHAR(255) NOT NULL,
    quantity             INT          NOT NULL,
    date                 DATE         NOT NULL,
    org_id               INT          NOT NULL,
    status               ENUM('available','low','out_of_stock','ordered') NOT NULL,
    site_engineer_id     INT          NOT NULL,

    INDEX idx_invent_org_eng (org_id, site_engineer_id),
    INDEX idx_inventory_org_date (org_id, date DESC),
    INDEX idx_inventory_engineer_status (site_engineer_id, org_id, status)
);


-- ============================================================
-- 19. vendor_inventory
-- ============================================================
CREATE TABLE IF NOT EXISTS vendor_inventory (
    id                   INT AUTO_INCREMENT PRIMARY KEY,
    material_description VARCHAR(255) NOT NULL,
    quantity             INT          NOT NULL,
    date                 DATE         NOT NULL,
    status               ENUM('available','low','out_of_stock','ordered') NOT NULL,
    vendor_name          VARCHAR(100) NOT NULL,
    vendor_quotation_pdf VARCHAR(255),
    admin_remark         VARCHAR(255),
    site_engineer_id     INT          NULL,
    admin_approval       ENUM('pending','approved','rejected') DEFAULT 'pending',
    vendor_type          ENUM('electrical','plumber','carpenter','painter','other') NOT NULL DEFAULT 'other',
    org_id               INT          NOT NULL,

    INDEX idx_vi_org_approval (org_id, admin_approval),
    INDEX idx_vi_engineer     (site_engineer_id),
    INDEX idx_vendor_pending (org_id, admin_approval, date DESC),
    INDEX idx_vendor_engineer_status (site_engineer_id, org_id, admin_approval, date DESC),
    INDEX idx_vendor_type_org (org_id, vendor_type, admin_approval),
    INDEX idx_vendor_date_org (org_id, date DESC)
);


-- ============================================================
-- 20. enquiries
-- ============================================================
CREATE TABLE IF NOT EXISTS enquiries (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    site_engineer_id INT,
    name             VARCHAR(100) NOT NULL,
    address          TEXT         NOT NULL,
    contact_no       VARCHAR(15)  NOT NULL,
    requirement      TEXT         NOT NULL,
    enquiry_date     DATETIME DEFAULT CURRENT_TIMESTAMP,
    org_id           INT          NOT NULL,

    INDEX idx_enq_org_date (org_id, enquiry_date),
    INDEX idx_enquiries_org_date_engineer (org_id, enquiry_date DESC, site_engineer_id)
);


-- ============================================================
-- 21. progress_reports
-- ============================================================
CREATE TABLE IF NOT EXISTS progress_reports (
    report_id        INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    site_id          INT NOT NULL,
    progress_percent INT NOT NULL,
    image_path       VARCHAR(255) DEFAULT NULL,
    pdf_path         VARCHAR(255) DEFAULT NULL,
    report_date      DATE         NOT NULL,
    remark           VARCHAR(255) DEFAULT NULL,
    org_id           INT          NOT NULL,

    INDEX idx_pr_site_id (site_id),
    INDEX idx_pr_org_id  (org_id),
    INDEX idx_progress_org_date (org_id, report_date DESC),
    INDEX idx_progress_site_org (site_id, org_id, report_date DESC),
    INDEX idx_progress_date_range (org_id, report_date, progress_percent)
);


-- ============================================================
-- 22. daily_worker_report
-- ============================================================
CREATE TABLE IF NOT EXISTS daily_worker_report (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    site_engineer_id INT  NOT NULL,
    project_id       INT  NOT NULL,
    worker_count     INT  NOT NULL,
    report_date      DATE NOT NULL,
    org_id           INT  NOT NULL,

    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE,

    INDEX idx_dwr_org_date (org_id, report_date),
    INDEX idx_dwr_eng_org  (site_engineer_id, org_id),
    INDEX idx_worker_report_org_date_desc (org_id, report_date DESC, worker_count),
    INDEX idx_worker_report_project (project_id, org_id, report_date DESC),
    INDEX idx_worker_report_engineer_month (site_engineer_id, org_id, report_date DESC)
);


-- ============================================================
-- 23. messages
-- ============================================================
CREATE TABLE IF NOT EXISTS messages (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    sender_id   INT  NOT NULL,
    receiver_id INT  NOT NULL,
    message     TEXT NOT NULL,
    timestamp   DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_read     TINYINT(1) DEFAULT 0,
    org_id      INT  NOT NULL,

    FOREIGN KEY (sender_id)   REFERENCES register(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES register(id) ON DELETE CASCADE,

    INDEX idx_msg_conv   (sender_id, receiver_id, org_id),
    INDEX idx_msg_unread (receiver_id, is_read),
    INDEX idx_messages_conversation (sender_id, receiver_id, org_id, timestamp),
    INDEX idx_messages_unread_org (receiver_id, org_id, is_read, timestamp),
    INDEX idx_messages_recent_user (receiver_id, org_id, timestamp DESC)
);


-- ============================================================
-- 24. salaries
-- ============================================================
CREATE TABLE IF NOT EXISTS salaries (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    project_id       INT,
    user_id          INT,
    role             VARCHAR(50),
    month_year       VARCHAR(7),
    base_salary      DECIMAL(10,2),
    allowance        DECIMAL(10,2),
    pf               DECIMAL(10,2),
    advance          DECIMAL(10,2) DEFAULT 0.00,
    other_deductions DECIMAL(10,2) DEFAULT 0.00,
    net_salary       DECIMAL(10,2) DEFAULT 0.00,
    pdf_filename     VARCHAR(255)  NULL,
    description      VARCHAR(255),
    created_by       INT,
    created_on       DATETIME DEFAULT CURRENT_TIMESTAMP,
    payment_mode     ENUM('cash','cheque') NOT NULL DEFAULT 'cash',
    cheque_number    VARCHAR(50),
    org_id           INT NOT NULL,

    FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE SET NULL,
    FOREIGN KEY (user_id)    REFERENCES register(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES register(id) ON DELETE SET NULL,

    INDEX idx_sal_org_month  (org_id, month_year),
    INDEX idx_sal_user_org   (user_id, org_id),
    INDEX idx_sal_created_by (created_by),
    INDEX idx_sal_project    (project_id),
    INDEX idx_salaries_user_month (user_id, org_id, month_year DESC, created_on),
    INDEX idx_salaries_org_month_user (org_id, month_year DESC, user_id),
    INDEX idx_salaries_pdf_status (org_id, pdf_filename, id),
    INDEX idx_salaries_project_month (project_id, org_id, month_year, net_salary)
);


-- ============================================================
-- 25. salary_report_tasks
-- ============================================================
CREATE TABLE IF NOT EXISTS salary_report_tasks (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    month_year    VARCHAR(7)   NOT NULL,
    status        ENUM('pending','processing','completed','failed') DEFAULT 'pending',
    pdf_filename  VARCHAR(255) NULL,
    error_message TEXT         NULL,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at  TIMESTAMP    NULL,
    org_id        INT          NOT NULL,
    created_by    INT          NOT NULL,

    INDEX idx_srt_status    (status),
    INDEX idx_srt_org_by    (org_id, created_by)
);


-- ============================================================
-- 26. advances
-- ============================================================
CREATE TABLE IF NOT EXISTS advances (
    id               INT AUTO_INCREMENT PRIMARY KEY,
    user_id          INT           NOT NULL,
    advance_amount   DECIMAL(10,2) NOT NULL,
    remaining_amount DECIMAL(10,2) NOT NULL,
    created_by       INT           NOT NULL,
    created_on       DATETIME,
    org_id           INT           NOT NULL,

    INDEX idx_adv_user_org (user_id, org_id),
    INDEX idx_adv_org      (org_id)
);


-- ============================================================
-- 27. base_salaries
-- ============================================================
CREATE TABLE IF NOT EXISTS base_salaries (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    user_id    INT           NOT NULL,
    salary     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    created_on DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_by INT           NOT NULL,
    updated_on DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    updated_by INT           DEFAULT NULL,
    org_id     INT           NOT NULL,

    FOREIGN KEY (user_id)    REFERENCES register(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by) REFERENCES register(id),
    FOREIGN KEY (updated_by) REFERENCES register(id),

    UNIQUE KEY unique_user_org (user_id, org_id),
    INDEX idx_bs_org_id  (org_id),
    INDEX idx_bs_user_id (user_id)
);


-- ============================================================
-- 28. daily_expenses
-- ============================================================
CREATE TABLE IF NOT EXISTS daily_expenses (
    id               INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    site_engineer_id INT,
    org_id           INT,
    project_id       INT,
    date             DATE,
    description      TEXT,
    amount           DECIMAL(10,2),
    status           ENUM('Pending','Approved','Rejected') DEFAULT 'Pending',
    admin_comment    TEXT,
    created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_exp_org_status (org_id, status),
    INDEX idx_exp_eng_org    (site_engineer_id, org_id),
    INDEX idx_exp_project    (project_id),
    INDEX idx_expenses_lookup (org_id, status, created_at DESC, site_engineer_id),
    INDEX idx_expenses_date_range (org_id, date, status, created_at),
    INDEX idx_expenses_engineer_history (site_engineer_id, org_id, created_at DESC, status),
    INDEX idx_expenses_project_status (project_id, org_id, status, amount)
);


-- ============================================================
-- 29. notifications
-- ============================================================
CREATE TABLE IF NOT EXISTS notifications (
    id                INT AUTO_INCREMENT PRIMARY KEY,
    user_id           INT         NOT NULL,
    org_id            INT         NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    reference_id      INT,
    message           TEXT        NOT NULL,
    is_read           BOOLEAN DEFAULT FALSE,
    created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES register(id),

    INDEX idx_notif_lookup (user_id, org_id, is_read, notification_type),
    INDEX idx_notif_created (user_id, created_at),
    INDEX idx_notifications_user_type (user_id, org_id, notification_type, is_read, created_at),
    INDEX idx_notifications_cleanup (is_read, created_at),
    INDEX idx_notifications_recent (user_id, org_id, created_at DESC),
    INDEX idx_notifications_mark_read (user_id, org_id, notification_type, is_read),
    INDEX idx_notifications_reference (reference_id, notification_type, org_id)
);


-- ============================================================
-- 30. bills_and_payments
-- ============================================================
CREATE TABLE IF NOT EXISTS bills_and_payments (
    id                     INT AUTO_INCREMENT PRIMARY KEY,
    bill_no                VARCHAR(100)  NOT NULL,
    bill_date              DATE          NOT NULL,
    bill_type              ENUM('Advance Bill','Running Account Bill','Final Bill') NOT NULL,
    bill_file_path         VARCHAR(500)  NULL,
    bill_file_type         ENUM('pdf','image') NULL,
    advance_amount         DECIMAL(15,2) DEFAULT 0.00,
    running_account_amount DECIMAL(15,2) DEFAULT 0.00,
    final_amount           DECIMAL(15,2) DEFAULT 0.00,
    work_name              VARCHAR(255)  NOT NULL,
    work_order_number      VARCHAR(100)  NOT NULL,
    work_order_date        DATE          NOT NULL,
    tender_name            VARCHAR(255)  NULL,
    tender_number          VARCHAR(100)  NULL,
    gross_amount           DECIMAL(15,2) NOT NULL,
    gst_percentage         DECIMAL(5,2)  NOT NULL,
    gst_amount             DECIMAL(15,2) NOT NULL,
    security_deposit       DECIMAL(15,2) DEFAULT 0.00,
    labour_charges         DECIMAL(15,2) NOT NULL,
    net_amount             DECIMAL(15,2) NOT NULL,
    pdf_filename           VARCHAR(255)  NULL,
    payment_status         ENUM('Paid','Unpaid') DEFAULT 'Unpaid',
    created_by             INT           NOT NULL,
    created_by_role        ENUM('admin','accountant') NOT NULL,
    org_id                 INT           NOT NULL,
    project_id             INT           NULL,
    accountant_id          INT           NULL,
    created_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_bp_bill_type      (bill_type),
    INDEX idx_bp_payment_status (payment_status),
    INDEX idx_bp_created_by     (created_by),
    INDEX idx_bp_org_id         (org_id),
    INDEX idx_bp_project_id     (project_id),
    INDEX idx_bp_accountant_id  (accountant_id),
    INDEX idx_bp_org_status     (org_id, payment_status),
    INDEX idx_bills_number_org (bill_no, org_id),
    INDEX idx_bills_date_range (org_id, bill_date DESC, payment_status),
    INDEX idx_bills_accountant (accountant_id, org_id, created_at DESC),
    INDEX idx_bills_work_order (work_order_number, org_id)
);