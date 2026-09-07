SELECT 
    conname AS ชื่อข้อกำหนด,
    conrelid::regclass AS ตารางย่อย,
    confrelid::regclass AS ตารางหลัก,
    CASE confdeltype 
        WHEN 'c' THEN 'CASCADE'
        WHEN 'r' THEN 'RESTRICT'
        WHEN 'a' THEN 'NO ACTION'
        WHEN 'n' THEN 'SET NULL'
    END AS กฎ_on_delete
FROM pg_constraint
WHERE contype = 'f'
ORDER BY ตารางย่อย, ตารางหลัก;
