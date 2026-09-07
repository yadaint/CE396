-- ล้างบางตารางเก่าทิ้งให้หมดก่อนเริ่มใหม่
DROP TABLE IF EXISTS receipt CASCADE;
DROP TABLE IF EXISTS visit_medicine CASCADE;
DROP TABLE IF EXISTS medicine CASCADE;
DROP TABLE IF EXISTS visit CASCADE;
DROP TABLE IF EXISTS vet_specialty CASCADE;
DROP TABLE IF EXISTS vet CASCADE;
DROP TABLE IF EXISTS animal CASCADE;
DROP TABLE IF EXISTS owner_phone CASCADE;
DROP TABLE IF EXISTS owner CASCADE;

-- 1. ข้อมูลเจ้าของสัตว์เลี้ยง
CREATE TABLE owner (
    owner_id INTEGER,
    first_name VARCHAR(120) NOT NULL,
    last_name VARCHAR(120) NOT NULL,
    address TEXT,
    CONSTRAINT pk_owner_id PRIMARY KEY (owner_id)
);

-- 2. เบอร์ติดต่อเจ้าของ (เก็บได้หลายเบอร์)
CREATE TABLE owner_phone (
    owner_id INTEGER,
    phone_no VARCHAR(20),
    is_primary BOOLEAN DEFAULT FALSE,
    CONSTRAINT pk_owner_tel PRIMARY KEY (owner_id, phone_no),
    CONSTRAINT fk_owner_tel FOREIGN KEY (owner_id) REFERENCES owner(owner_id) ON DELETE CASCADE
    -- ใช้ CASCADE เพราะถ้าลบเจ้าของออกจากระบบ เบอร์โทรก็ไม่มีประโยชน์ ต้องลบตามไปเลย
);

-- 3. ข้อมูลน้องหมาน้องแมว (หรือสัตว์อื่นๆ)
CREATE TABLE animal (
    animal_id INTEGER,
    owner_id INTEGER NOT NULL,
    name VARCHAR(120) NOT NULL,
    species VARCHAR(60),
    sex VARCHAR(15),
    color VARCHAR(60),
    birth_date DATE,
    CONSTRAINT pk_animal_id PRIMARY KEY (animal_id),
    CONSTRAINT chk_gender CHECK (sex IN ('Male', 'Female', 'Unknown')),
    CONSTRAINT fk_animal_owner FOREIGN KEY (owner_id) REFERENCES owner(owner_id) ON DELETE CASCADE
    -- CASCADE เหมือนกัน ลบเจ้าของปุ๊บ ข้อมูลสัตว์เลี้ยงก็หายตามไปด้วย
);

-- 4. ประวัติคุณหมอ
CREATE TABLE vet (
    vet_id INTEGER,
    license_no VARCHAR(60) NOT NULL,
    name VARCHAR(200) NOT NULL,
    start_date DATE,
    CONSTRAINT pk_vet_id PRIMARY KEY (vet_id),
    CONSTRAINT uq_vet_license UNIQUE (license_no)
);

-- 5. ความเชี่ยวชาญเฉพาะทางของหมอ (M:N)
CREATE TABLE vet_specialty (
    vet_id INTEGER,
    specialty VARCHAR(120),
    CONSTRAINT pk_vet_sp PRIMARY KEY (vet_id, specialty),
    CONSTRAINT fk_sp_vet FOREIGN KEY (vet_id) REFERENCES vet(vet_id) ON DELETE CASCADE
    -- ถ้าลบรายชื่อคุณหมอทิ้ง ประวัติความเชี่ยวชาญก็ต้องล้างทิ้งไปด้วย (CASCADE)
);

-- 6. บันทึกการเข้ามารักษา (เอนทิตีอ่อน)
CREATE TABLE visit (
    animal_id INTEGER,
    visit_no INTEGER,
    visit_date DATE NOT NULL,
    weight DECIMAL(6,2),
    temperature DECIMAL(5,2),
    symptom TEXT,
    diagnosis TEXT,
    vet_id INTEGER NOT NULL,
    CONSTRAINT pk_visit_history PRIMARY KEY (animal_id, visit_no),
    CONSTRAINT fk_visit_ani FOREIGN KEY (animal_id) REFERENCES animal(animal_id) ON DELETE CASCADE,
    -- ลบสัตว์เลี้ยงออก ประวัติการรักษาก็ปลิวตาม (CASCADE)
    CONSTRAINT fk_visit_doctor FOREIGN KEY (vet_id) REFERENCES vet(vet_id) ON DELETE RESTRICT
    -- ล็อกไว้เลย ห้ามลบข้อมูลหมอถ้าหมอคนนั้นเคยตรวจสัตว์ไปแล้ว เดี๋ยวประวัติพัง (RESTRICT)
);

-- 7. คลังยา
CREATE TABLE medicine (
    medicine_id INTEGER,
    name VARCHAR(200) NOT NULL,
    unit VARCHAR(50),
    unit_price DECIMAL(10,2),
    CONSTRAINT pk_med_id PRIMARY KEY (medicine_id),
    CONSTRAINT chk_price_positive CHECK (unit_price >= 0)
);

-- 8. ประวัติการจ่ายยาในแต่ละครั้ง (M:N)
CREATE TABLE visit_medicine (
    animal_id INTEGER,
    visit_no INTEGER,
    medicine_id INTEGER,
    dosage VARCHAR(150),
    days INTEGER,
    CONSTRAINT pk_visit_med PRIMARY KEY (animal_id, visit_no, medicine_id),
    CONSTRAINT chk_med_days CHECK (days > 0),
    CONSTRAINT fk_vmed_visit FOREIGN KEY (animal_id, visit_no) REFERENCES visit(animal_id, visit_no) ON DELETE CASCADE,
    -- ลบประวัติการรักษาปุ๊บ รายการยาที่จ่ายในรอบนั้นก็ต้องโดนลบทิ้งด้วย (CASCADE)
    CONSTRAINT fk_vmed_medicine FOREIGN KEY (medicine_id) REFERENCES medicine(medicine_id) ON DELETE RESTRICT
    -- ห้ามลบยาออกจากคลังถ้ายานั้นเคยถูกจ่ายไปแล้ว ต้องเก็บไว้เป็นหลักฐาน (RESTRICT)
);

-- 9. ใบเสร็จเก็บเงิน (1:1 กับการรักษา)
CREATE TABLE receipt (
    receipt_id INTEGER,
    animal_id INTEGER NOT NULL,
    visit_no INTEGER NOT NULL,
    paid_at TIMESTAMP,
    total_amount DECIMAL(12,2),
    CONSTRAINT pk_rcpt_id PRIMARY KEY (receipt_id),
    CONSTRAINT uq_rcpt_visit UNIQUE (animal_id, visit_no),
    CONSTRAINT chk_total_amt CHECK (total_amount >= 0),
    CONSTRAINT fk_rcpt_visit FOREIGN KEY (animal_id, visit_no) REFERENCES visit(animal_id, visit_no) ON DELETE RESTRICT
    -- ใบเสร็จเป็นเอกสารสำคัญ ห้ามลบประวัติการรักษาถ้ามีการออกใบเสร็จและจ่ายเงินไปแล้ว (RESTRICT)
);