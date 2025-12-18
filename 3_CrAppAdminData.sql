
-- Add data
-- Add locations
exec add_location('New York');
exec add_location('Los Angeles');
exec add_location('Chicago');
exec add_location('Houston');
exec add_location('Miami');
exec add_location('San Francisco');
exec add_location('Seattle');
exec add_location('Denver');
exec add_location('Atlanta');
exec add_location('Dallas');
exec add_location('Phoenix');
exec add_location('Boston');
exec add_location('Las Vegas');
exec add_location('Orlando');
exec add_location('Portland');
exec add_location('Austin');
exec add_location('Nashville');
exec add_location('San Diego');
exec add_location('Minneapolis');

-- Add vehicle types
-- Sedan
exec add_vehicle_type('honda', 'accord', 'automatic', 'sedan', 'petrol');
exec add_vehicle_type('toyota', 'corolla', 'manual', 'sedan', 'gasoline');


-- SUV
exec add_vehicle_type('jeep', 'cherokee', 'automatic', 'suv', 'gasoline');
exec add_vehicle_type('honda', 'cr-v', 'cvt', 'suv', 'petrol');


-- Truck
exec add_vehicle_type('chevrolet', 'silverado', 'automatic', 'truck', 'diesel');
exec add_vehicle_type('ford', 'f-250', 'automatic', 'truck', 'gasoline');

-- Hatchback
exec add_vehicle_type('volkswagen', 'golf', 'manual', 'hatchback', 'petrol');
exec add_vehicle_type('ford', 'fiesta', 'automatic', 'hatchback', 'gasoline');


-- Convertible
exec add_vehicle_type('ford', 'mustang', 'automatic', 'convertible', 'petrol');
exec add_vehicle_type('chevrolet', 'camaro', 'manual', 'convertible', 'petrol');


-- Add discount types
EXEC add_discount_type('FIRST', 5.00, 10.00);
EXEC add_discount_type('NO_DISC', 0.00, 0.00);
EXEC add_discount_type('NEW2024', 10.00, 30.00);
EXEC add_discount_type('WONDER10', 20.00, 100.00);
EXEC add_discount_type('PEACEOUT', 30.00, 120.00);

-- Add insurance types
EXEC add_insurance_type('star all', 2000);
EXEC add_insurance_type('safety first', 5000);
EXEC add_insurance_type('travel shield', 3000);
EXEC add_insurance_type('care first', 1000);


-- Add users
EXEC add_user('customer', 'Abigail', 'Gring', 'New York', 'DL12345678901234', 25, NULL, NULL);
EXEC add_user('vendor', 'Bob', 'Cat', 'Los Angeles', NULL, NULL, 'BobCat rentals', 'TaxID1234567890123');
EXEC add_user('customer', 'Cat', 'Stevens', 'Boston', 'DL98765432109876', 30, NULL, NULL);
EXEC add_user('vendor', 'Dina', 'Jones', 'Minneapolis', NULL, NULL, 'New Old rentals', 'TaxID8765432109876');
EXEC add_user('vendor', 'Lewis', 'Alonso', 'Minneapolis', NULL, NULL, 'Merc rentals', 'TaxID8765432109875');
EXEC add_user('customer', 'Ocon', 'Riccardo', 'Boston', 'DL98765432109877', 30, NULL, NULL);
EXEC add_user('customer', 'Nico', 'Bottas', 'Chicago', 'DL98765432109888', 35, NULL, NULL);
EXEC add_user('customer', 'James', 'Hunt', 'Seattle', 'DL98765432109866', 27, NULL, NULL);
EXEC add_user('customer', 'Adam', 'Jameson', 'Boston', 'DL98765432109855', 40, NULL, NULL);
EXEC add_user('customer', 'Jos', 'Broad', 'Boston', 'DL98765432109844', 50, NULL, NULL);
EXEC add_user('vendor', 'Rick', 'Johnson', 'Chicago', NULL, NULL, 'Haas rentals', 'TaxID8765432109874');
EXEC add_user('vendor', 'Mick', 'Bottas', 'Seattle', NULL, NULL, 'Alpine rentals', 'TaxID8765432109873');
EXEC add_user('vendor', 'Fernando', 'Hulkenberg', 'Seattle', NULL, NULL, 'Force rentals', 'TaxID8765432109873');


-- Add vehicles
EXEC add_vehicle(25.00, 5000, 'true', 5, 'BOS123NE0W456OOP', 'New York', 'Bob', 'accord')
EXEC add_vehicle(40.00, 5000, 'true', 5, 'NYE345MID0456OOP', 'New York', 'Dina', 'corolla')
EXEC add_vehicle(50.00, 5000, 'true', 5, 'NYE678MID4056OOP', 'New York', 'Dina', 'cherokee')
EXEC add_vehicle(30.00, 5000, 'true', 5, 'ARK678NEW7908OOP', 'New York', 'Bob', 'cr-v')
EXEC add_vehicle(40.00, 5000, 'true', 5, 'ARK678NEW79081OP', 'Chicago', 'Lewis', 'silverado')
EXEC add_vehicle(30.00, 5000, 'true', 5, 'ARK678NEW79082OP', 'Minneapolis', 'Rick', 'f-250')
EXEC add_vehicle(40.00, 5000, 'true', 5, 'ARK678NEW79083OP', 'Seattle', 'Mick', 'golf')
EXEC add_vehicle(35.00, 5000, 'true', 5, 'ARK678NEW79084OP', 'Seattle', 'Fernando', 'fiesta')


-- Insert 20 16-digit random numbers into cc_catalog table
INSERT INTO cc_catalog (card_number) VALUES ('1234567890123456');
INSERT INTO cc_catalog (card_number) VALUES ('2345678901234567');
INSERT INTO cc_catalog (card_number) VALUES ('3456789012345678');
INSERT INTO cc_catalog (card_number) VALUES ('4567890123456789');
INSERT INTO cc_catalog (card_number) VALUES ('5678901234567890');
INSERT INTO cc_catalog (card_number) VALUES ('6789012345678901');
INSERT INTO cc_catalog (card_number) VALUES ('7890123456789012');
INSERT INTO cc_catalog (card_number) VALUES ('8901234567890123');
INSERT INTO cc_catalog (card_number) VALUES ('9012345678901234');
INSERT INTO cc_catalog (card_number) VALUES ('0123456789012345');
INSERT INTO cc_catalog (card_number) VALUES ('0987654321098765');
INSERT INTO cc_catalog (card_number) VALUES ('9876543210987654');
INSERT INTO cc_catalog (card_number) VALUES ('8765432109876543');
INSERT INTO cc_catalog (card_number) VALUES ('7654321098765432');
INSERT INTO cc_catalog (card_number) VALUES ('6543210987654321');
INSERT INTO cc_catalog (card_number) VALUES ('5432109876543210');
INSERT INTO cc_catalog (card_number) VALUES ('4321098765432109');
INSERT INTO cc_catalog (card_number) VALUES ('3210987654321098');
INSERT INTO cc_catalog (card_number) VALUES ('2109876543210987');
INSERT INTO cc_catalog (card_number) VALUES ('1098765432109876');
INSERT INTO cc_catalog (card_number) VALUES ('6363712392387245');
INSERT INTO cc_catalog (card_number) VALUES ('6363712392387236');
INSERT INTO cc_catalog (card_number) VALUES ('6363712392387233');
INSERT INTO cc_catalog (card_number) VALUES ('6363712392387232');
INSERT INTO cc_catalog (card_number) VALUES ('7432738484381812');
INSERT INTO cc_catalog (card_number) VALUES ('1234567890123456');
INSERT INTO cc_catalog (card_number) VALUES ('1234876539081234');
INSERT INTO cc_catalog (card_number) VALUES ('3000300030003002');
INSERT INTO cc_catalog (card_number) VALUES ('3000300030003004');


-- Add payment methods
EXEC add_payment_method('1234876539081234','true', '2024-01-31','186','1 kev St, New York, USA','Abigail');
EXEC add_payment_method('1234567890123456','true', '2027-12-31','123','1 kev St, Seattle, USA','James');
EXEC add_payment_method('7432738484381812','true', '2026-03-31','354','34 Main St, Boston, USA','Cat');
EXEC add_payment_method('6363712392387232','true', '2027-10-31','154','123 Main St, Boston, USA','Ocon');
EXEC add_payment_method('6363712392387233','true', '2027-11-30','154','122 Main St, Chicago, USA','Nico');
EXEC add_payment_method('6363712392387236','true', '2027-08-31','152','120 Main St, Boston, USA','Adam');
EXEC add_payment_method('6363712392387245','true', '2027-07-31','151','126 Main St, Boston, USA','Jos');

-- Add reservations
EXEC add_reservation('pending',100.00,'2023-12-01','2023-12-10','SA001','New York','Boston', 2,'BOS123NE0W456OOP','Abigail','star all');
EXEC add_reservation('active',200.00,'2023-12-02','2023-12-11','TS012','New York','Boston', 4,'NYE345MID0456OOP','Abigail','travel shield');
EXEC add_reservation('completed',300.00,'2023-01-01','2023-01-10','SF005','New York','Chicago', 2,'NYE678MID4056OOP','Cat','safety first');
EXEC add_reservation('active',350.00,'2023-12-01','2023-12-12','CF001','Seattle','Boston', 6,'ARK678NEW7908OOP','Cat','care first');
EXEC add_reservation('cancelled',110.00,'2024-11-01','2023-11-10','SF034','New York','Seattle', 2,'ARK678NEW79081OP','Abigail','safety first');
EXEC add_reservation('active',200.00,'2023-05-11','2023-05-14','TS013','New York','Minneapolis', 4,'ARK678NEW79082OP','Abigail','travel shield');
EXEC add_reservation('completed',300.00,'2023-03-20','2023-04-10','SF004','Seattle','Los Angeles', 2,'ARK678NEW79083OP','Cat','safety first');
EXEC add_reservation('active',350.00,'2023-12-01','2023-12-12','CF002','Los Angeles','Boston', 6,'NYE678MID4056OOP','Cat','care first');
EXEC add_reservation('active',350.00,'2023-12-01','2023-12-13','CF003','New York','Boston', 4,'ARK678NEW79084OP','Ocon','care first');
EXEC add_reservation('completed',450.00,'2023-05-01','2023-06-13','CF004','Los Angeles','Boston', 4,'ARK678NEW79084OP','Ocon','safety first');
EXEC add_reservation('completed',400.00,'2023-06-14','2023-07-13','SF035','Chicago','Seattle', 6,'ARK678NEW79081OP','Nico','star all');
EXEC add_reservation('completed',400.00,'2023-07-14','2023-08-13','SF036','Boston','Seattle', 4,'ARK678NEW79083OP','Nico','star all');
EXEC add_reservation('completed',400.00,'2023-08-14','2023-09-13','SF037','Boston','Seattle', 2,'ARK678NEW79083OP','James','travel shield');
EXEC add_reservation('completed',450.00,'2023-10-14','2023-11-13','SF038','Seattle','Boston', 4,'ARK678NEW79083OP','James','care first');
EXEC add_reservation('completed',350.00,'2023-05-14','2023-06-13','SF039','Chicago','Minneapolis', 4,'ARK678NEW79081OP','Adam','safety first');
EXEC add_reservation('cancelled',380.00,'2023-07-14','2023-08-13','SF051','Chicago','Los Angeles', 6,'ARK678NEW79081OP','Adam','travel shield');
EXEC add_reservation('cancelled',400.00,'2024-08-14','2024-09-13','SF052','Minneapolis','Los Angeles', 4,'ARK678NEW79081OP','Jos','care first');
EXEC add_reservation('completed',300.00,'2022-12-02','2022-12-11','SF053','Boston','New York', 4,'BOS123NE0W456OOP','Abigail','star all');
EXEC add_reservation('completed',350.00,'2022-12-02','2022-12-11','SF054','Chicago','Los Angeles', 2,'NYE345MID0456OOP','Cat','travel shield');
EXEC add_reservation('completed',500.00,'2022-12-02','2022-12-11','SF055','Minneapolis','Seattle', 4,'NYE678MID4056OOP','Ocon','safety first');
EXEC add_reservation('completed',400.00,'2022-12-02','2022-12-11','SF056','New York','Seattle', 6,'ARK678NEW7908OOP','Nico','care first');
EXEC add_reservation('completed',550.00,'2022-12-02','2022-12-11','SF057','Minneapolis','Chicago', 4,'ARK678NEW79081OP','James','star all');
EXEC add_reservation('completed',600.00,'2022-12-02','2022-12-11','SF058','Los Angeles','Boston', 2,'ARK678NEW79082OP','Adam','travel shield');
EXEC add_reservation('completed',250.00,'2022-12-02','2022-12-11','SF059','Chicago','Seattle', 4,'ARK678NEW79083OP','Jos','star all');



-- Add Payment transactions
EXEC add_payment_transaction('completed', 100.00, 'VAR300com', 1, '1234876539081234', 'WONDER10');
EXEC add_payment_transaction('completed', 200.00, 'WERE200', 2, '1234876539081234', 'NEW2024');
EXEC add_payment_transaction('completed', 300.00, 'COMP20', 3, '7432738484381812', 'FIRST');
EXEC add_payment_transaction('completed', 350.00, 'COP20wr', 4, '7432738484381812', 'NO_DISC');
EXEC add_payment_transaction('completed', 110.00, 'COP20wt', 5, '1234876539081234', 'NO_DISC');
EXEC add_payment_transaction('completed', 200.00, 'COP20wy', 6, '1234876539081234', 'NO_DISC');
EXEC add_payment_transaction('completed', 300.00, 'COP20wu', 7, '7432738484381812', 'NO_DISC');
EXEC add_payment_transaction('completed', 350.00, 'COP20wi', 8, '7432738484381812', 'FIRST');
EXEC add_payment_transaction('completed', 350.00, 'COP20wo', 9, '6363712392387232', 'NO_DISC');
EXEC add_payment_transaction('completed', 450.00, 'COP20wp', 10, '6363712392387232', 'NO_DISC');
EXEC add_payment_transaction('completed', 400.00, 'COP20wl', 11, '6363712392387233', 'WONDER10');
EXEC add_payment_transaction('completed', 400.00, 'COP20wk', 12, '6363712392387233', 'NO_DISC');
EXEC add_payment_transaction('completed', 400.00, 'COP20wj', 13, '1234567890123456', 'NEW2024');
EXEC add_payment_transaction('completed', 450.00, 'COP20wh', 14, '1234567890123456', 'NO_DISC');
EXEC add_payment_transaction('completed', 350.00, 'COP20wg', 15, '6363712392387236', 'NEW2024');
EXEC add_payment_transaction('completed', 380.00, 'COP20wf', 16, '6363712392387236', 'NO_DISC');
EXEC add_payment_transaction('completed', 400.00, 'COP20wd', 17, '6363712392387245', 'NO_DISC');
EXEC add_payment_transaction('completed', 300.00, 'COP20ws', 18, '1234876539081234', 'FIRST');
EXEC add_payment_transaction('completed', 350.00, 'COP20wa', 19, '7432738484381812', 'NO_DISC');
EXEC add_payment_transaction('completed', 500.00, 'COP20wz', 20, '6363712392387232', 'NO_DISC');
EXEC add_payment_transaction('completed', 400.00, 'COP20wx', 21, '6363712392387233', 'NEW2024');
EXEC add_payment_transaction('completed', 550.00, 'COP20wc', 22, '1234567890123456', 'NO_DISC');
EXEC add_payment_transaction('completed', 600.00, 'COP20wv', 23, '6363712392387236', 'NEW2024');
EXEC add_payment_transaction('completed', 250.00, 'COP20wb', 24, '6363712392387245', 'NO_DISC');



