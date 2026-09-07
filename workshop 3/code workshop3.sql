-- คำสั่ง DROP TABLE ใช้ลบตารางเก่าทิ้ง IF EXISTS คือถ้ามีตารางอยู่ถึงลบ
-- CASCADE สั่งให้ลบสิ่งที่ผูกกันอยู่ให้ขาดรวดเดียว จะได้รันโค้ดใหม่ไม่ติด error
DROP TABLE IF EXISTS receipt CASCADE;
DROP TABLE IF EXISTS visit_medicine CASCADE;
DROP TABLE IF EXISTS medicine CASCADE;
DROP TABLE IF EXISTS visit CASCADE;
DROP TABLE IF EXISTS vet_specialty CASCADE;
DROP TABLE IF EXISTS vet CASCADE;
DROP TABLE IF EXISTS animal CASCADE;
DROP TABLE IF EXISTS owner_phone CASCADE;
DROP TABLE IF EXISTS owner CASCADE;

-- 1. ตารางข้อมูลเจ้าของ
-- CREATE TABLE คือคำสั่งสร้างตาราง
CREATE TABLE owner (
    owner_id INTEGER, -- INTEGER คือชนิดข้อมูลตัวเลขจำนวนเต็ม
    first_name VARCHAR(120) NOT NULL, -- VARCHAR(120) เก็บตัวอักษรยาวไม่เกิน 120 / NOT NULL บังคับห้ามเว้นว่าง
    last_name VARCHAR(120) NOT NULL,
    address TEXT, -- TEXT ไว้เก็บข้อความยาวๆ เช่นที่อยู่
    -- CONSTRAINT ไว้ตั้งชื่อกฎ / PRIMARY KEY กำหนดให้คอลัมน์นี้เป็นคีย์หลักประจำตาราง ข้อมูลห้ามซ้ำและห้ามว่าง
    CONSTRAINT pk_owner_id PRIMARY KEY (owner_id) 
);

-- 2. ตารางเบอร์โทรเจ้าของ (แยกออกมาเพราะคนนึงอาจมีหลายเบอร์)
CREATE TABLE owner_phone (
    owner_id INTEGER,
    phone_no VARCHAR(20),
    is_primary BOOLEAN DEFAULT FALSE, -- BOOLEAN เก็บค่าจริง/เท็จ / DEFAULT FALSE กำหนดค่าเริ่มต้นให้เป็นเท็จถ้าไม่ได้กรอก
    CONSTRAINT pk_owner_tel PRIMARY KEY (owner_id, phone_no), -- เอา 2 คอลัมน์มารวมกันเป็นคีย์หลัก (PK ผสม)
    -- FOREIGN KEY ใช้เชื่อมโยงข้อมูลข้ามตาราง / REFERENCES ชี้ไปที่ตาราง owner
    CONSTRAINT fk_owner_tel FOREIGN KEY (owner_id) REFERENCES owner(owner_id) ON DELETE CASCADE
    -- ON DELETE CASCADE: กฎลบต่อเนื่อง ถ้าชื่อเจ้าของโดนลบ เบอร์โทรก็ต้องโดนลบทิ้งตามไปด้วย
);

-- 3. ตารางข้อมูลน้องหมาน้องแมว
CREATE TABLE animal (
    animal_id INTEGER,
    owner_id INTEGER NOT NULL,
    name VARCHAR(120) NOT NULL,
    species VARCHAR(60),
    sex VARCHAR(15),
    color VARCHAR(60),
    birth_date DATE, -- DATE ใช้เก็บข้อมูลวันที่
    CONSTRAINT pk_animal_id PRIMARY KEY (animal_id),
    -- CHECK ใช้สร้างเงื่อนไขบังคับข้อมูลก่อนบันทึก ในที่นี้บังคับให้กรอกเพศได้แค่ 3 แบบที่กำหนด
    CONSTRAINT chk_gender CHECK (sex IN ('Male', 'Female', 'Unknown')),
    CONSTRAINT fk_animal_owner FOREIGN KEY (owner_id) REFERENCES owner(owner_id) ON DELETE CASCADE
    -- ON DELETE CASCADE: ถ้าลบเจ้าของทิ้ง ข้อมูลสัตว์เลี้ยงก็ต้องปลิวตามไปด้วย
);

-- 4. ตารางประวัติคุณหมอ
CREATE TABLE vet (
    vet_id INTEGER,
    license_no VARCHAR(60) NOT NULL,
    name VARCHAR(200) NOT NULL,
    start_date DATE,
    CONSTRAINT pk_vet_id PRIMARY KEY (vet_id),
    -- UNIQUE บังคับว่าข้อมูลในคอลัมน์นี้ห้ามซ้ำกันเลย (เลขใบอนุญาตหมอต้องไม่ซ้ำกัน)
    CONSTRAINT uq_vet_license UNIQUE (license_no) 
);

-- 5. ตารางความเชี่ยวชาญของหมอ (หมอ 1 คนอาจจะเก่งหลายด้าน)
CREATE TABLE vet_specialty (
    vet_id INTEGER,
    specialty VARCHAR(120),
    CONSTRAINT pk_vet_sp PRIMARY KEY (vet_id, specialty),
    CONSTRAINT fk_sp_vet FOREIGN KEY (vet_id) REFERENCES vet(vet_id) ON DELETE CASCADE
    -- ON DELETE CASCADE: ถ้าลบรายชื่อคุณหมอออก ความเชี่ยวชาญของหมอคนนั้นก็ต้องโดนลบทิ้ง
);

-- 6. ตารางบันทึกประวัติการเข้ามารักษา (เอนทิตีอ่อน)
CREATE TABLE visit (
    animal_id INTEGER,
    visit_no INTEGER,
    visit_date DATE NOT NULL,
    weight DECIMAL(6,2), -- DECIMAL เก็บตัวเลขทศนิยม (รวม 6 หลัก เป็นทศนิยมไป 2 หลัก)
    temperature DECIMAL(5,2),
    symptom TEXT,
    diagnosis TEXT,
    vet_id INTEGER NOT NULL,
    CONSTRAINT pk_visit_history PRIMARY KEY (animal_id, visit_no),
    CONSTRAINT fk_visit_ani FOREIGN KEY (animal_id) REFERENCES animal(animal_id) ON DELETE CASCADE,
    -- ON DELETE CASCADE: ลบข้อมูลสัตว์เลี้ยงปุ๊บ ประวัติการรักษาเก่าๆ ก็ลบทิ้งไปเลย
    CONSTRAINT fk_visit_doctor FOREIGN KEY (vet_id) REFERENCES vet(vet_id) ON DELETE RESTRICT
    -- ON DELETE RESTRICT: กฎห้ามลบ ป้องกันไม่ให้ลบชื่อหมอถ้าหมอเคยตรวจเคสนี้ไปแล้ว เดี๋ยวข้อมูลประวัติการรักษาพัง
);

-- 7. ตารางคลังยา
CREATE TABLE medicine (
    medicine_id INTEGER,
    name VARCHAR(200) NOT NULL,
    unit VARCHAR(50),
    unit_price DECIMAL(10,2),
    CONSTRAINT pk_med_id PRIMARY KEY (medicine_id),
    -- บังคับว่าราคายาต้องมากกว่าหรือเท่ากับ 0 ห้ามติดลบ
    CONSTRAINT chk_price_positive CHECK (unit_price >= 0) 
);

-- 8. ตารางบันทึกการจ่ายยาในแต่ละรอบ
CREATE TABLE visit_medicine (
    animal_id INTEGER,
    visit_no INTEGER,
    medicine_id INTEGER,
    dosage VARCHAR(150),
    days INTEGER,
    CONSTRAINT pk_visit_med PRIMARY KEY (animal_id, visit_no, medicine_id),
    -- บังคับว่าจำนวนวันจ่ายยาต้องมากกว่า 0 วัน
    CONSTRAINT chk_med_days CHECK (days > 0), 
    CONSTRAINT fk_vmed_visit FOREIGN KEY (animal_id, visit_no) REFERENCES visit(animal_id, visit_no) ON DELETE CASCADE,
    -- ON DELETE CASCADE: ถ้ายกเลิก/ลบประวัติการรักษา รายการยาที่สั่งในรอบนั้นก็ต้องโดนลบตาม
    CONSTRAINT fk_vmed_medicine FOREIGN KEY (medicine_id) REFERENCES medicine(medicine_id) ON DELETE RESTRICT
    -- ON DELETE RESTRICT: ห้ามลบยาออกจากคลังถ้ายานั้นเคยถูกสั่งจ่ายไปแล้ว ต้องเก็บเป็นหลักฐานว่าเคยจ่ายยานี้ไป
);

-- 9. ตารางใบเสร็จ (ออกได้ 1 ใบต่อการรักษา 1 ครั้ง)
CREATE TABLE receipt (
    receipt_id INTEGER,
    animal_id INTEGER NOT NULL,
    visit_no INTEGER NOT NULL,
    paid_at TIMESTAMP, -- TIMESTAMP เก็บเวลาแบบละเอียดทั้งวันที่และเวลา
    total_amount DECIMAL(12,2),
    CONSTRAINT pk_rcpt_id PRIMARY KEY (receipt_id),
    -- UNIQUE แบบจับคู่ บังคับว่าการรักษา 1 รอบ (animal_id + visit_no) ออกใบเสร็จซ้ำไม่ได้
    CONSTRAINT uq_rcpt_visit UNIQUE (animal_id, visit_no), 
    CONSTRAINT chk_total_amt CHECK (total_amount >= 0),
    CONSTRAINT fk_rcpt_visit FOREIGN KEY (animal_id, visit_no) REFERENCES visit(animal_id, visit_no) ON DELETE RESTRICT
    -- ON DELETE RESTRICT: ถ้าออกใบเสร็จรับเงินไปแล้ว จะกลับไปลบประวัติการรักษาไม่ได้แล้ว ป้องกันบัญชีพัง
);
