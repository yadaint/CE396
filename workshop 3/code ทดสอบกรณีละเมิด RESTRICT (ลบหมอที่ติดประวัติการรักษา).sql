INSERT INTO owner (owner_id, first_name, last_name) VALUES (88, 'กานต์', 'รักสัตว์');
INSERT INTO animal (animal_id, owner_id, name, sex) VALUES (88, 88, 'ส้มจี๊ด', 'Female');
INSERT INTO visit (animal_id, visit_no, visit_date, vet_id) VALUES (88, 1, '2023-10-15', 88);

DELETE FROM vet WHERE vet_id = 88;
