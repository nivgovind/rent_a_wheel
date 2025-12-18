SET SERVEROUTPUT ON;

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE payment_transactions';
    EXECUTE IMMEDIATE 'DROP TABLE reservations';
    EXECUTE IMMEDIATE 'DROP TABLE vehicles';
    EXECUTE IMMEDIATE 'DROP TABLE payment_methods';
    EXECUTE IMMEDIATE 'DROP TABLE insurance_types';
    EXECUTE IMMEDIATE 'DROP TABLE discount_types';
    EXECUTE IMMEDIATE 'DROP TABLE vehicle_types';  
    EXECUTE IMMEDIATE 'DROP TABLE users';
    EXECUTE IMMEDIATE 'DROP TABLE locations';
    EXECUTE IMMEDIATE 'DROP TABLE cc_catalog';
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE != -942 THEN
         RAISE;
      END IF;
END;
/

-- Drop sequences if already exists
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE locations_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE discount_types_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE insurance_types_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE payment_methods_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE payment_transactions_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE reservations_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE users_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE vehicle_types_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE vehicles_seq';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -2289 THEN
            RAISE;
        END IF;
END;
/
-- Create sequences
CREATE SEQUENCE locations_seq START WITH 1;
CREATE SEQUENCE users_seq START WITH 1;
CREATE SEQUENCE vehicle_types_seq START WITH 1;
CREATE SEQUENCE discount_types_seq START WITH 1;
CREATE SEQUENCE insurance_types_seq START WITH 1;
CREATE SEQUENCE payment_methods_seq START WITH 1;
CREATE SEQUENCE payment_transactions_seq START WITH 1;
CREATE SEQUENCE reservations_seq START WITH 1;
CREATE SEQUENCE vehicles_seq START WITH 1;

-- Create tables
CREATE TABLE locations (
    id       NUMBER DEFAULT locations_seq.nextval NOT NULL,
    name     VARCHAR2(100) NOT NULL,
    CONSTRAINT locations_pk PRIMARY KEY (id)
);

CREATE TABLE vehicle_types (
    id                NUMBER DEFAULT vehicle_types_seq.nextval NOT NULL,
    make              VARCHAR2(20) NOT NULL,
    model             VARCHAR2(100) NOT NULL,
    transmission_type VARCHAR2(100),
    category          VARCHAR2(100) NOT NULL,
    fuel_type         VARCHAR2(20) NOT NULL,
    CONSTRAINT vehicle_types_pk PRIMARY KEY (id)
);

CREATE TABLE discount_types (
    id              NUMBER DEFAULT discount_types_seq.nextval NOT NULL,
    code            VARCHAR2(10) NOT NULL,
    discount_amount NUMBER(7,2) NOT NULL,
    min_eligible_charge NUMBER(7,2) NOT NULL,
    CONSTRAINT discount_types_pk PRIMARY KEY (id)
);

CREATE TABLE insurance_types (
    id       NUMBER DEFAULT insurance_types_seq.nextval NOT NULL,
    coverage NUMBER(7,2) NOT NULL,
    name     VARCHAR2(100) NOT NULL,
    CONSTRAINT insurance_types_pk PRIMARY KEY (id)
);

CREATE TABLE users (
    id                 NUMBER DEFAULT users_seq.nextval NOT NULL,
    role               VARCHAR2(10) NOT NULL,
    fname              VARCHAR2(100) NOT NULL,
    lname              VARCHAR2(100),
    current_location_id NUMBER,
    driver_license   VARCHAR2(20),
    age              NUMBER,
    company_name     VARCHAR2(100),
    tax_id           VARCHAR2(20),
    CONSTRAINT users_pk PRIMARY KEY (id),
    CONSTRAINT users_locations_fk FOREIGN KEY (current_location_id)
        REFERENCES locations(id)
);

CREATE TABLE payment_methods (
    id              NUMBER DEFAULT payment_methods_seq.nextval NOT NULL,
    active_status   NUMBER NOT NULL CHECK (active_status IN (1,0)),
    card_number     VARCHAR2(16) NOT NULL,
    expiration_date DATE NOT NULL,
    security_code   VARCHAR2(3) NOT NULL,
    billing_address VARCHAR2(100),
    users_id        NUMBER NOT NULL,
    CONSTRAINT payment_methods_pk PRIMARY KEY (id),
    CONSTRAINT payment_methods_users_fk FOREIGN KEY (users_id)
        REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE vehicles (
    id                  NUMBER DEFAULT vehicles_seq.nextval NOT NULL,
    hourly_rate         NUMBER(7,2) NOT NULL,
    miles_driven        NUMBER,
    availability_status NUMBER NOT NULL CHECK (availability_status IN (1,0)),
    passenger_capacity  NUMBER,
    registration_id     VARCHAR2(20) NOT NULL,
    current_location_id NUMBER,
    users_id            NUMBER,
    vehicle_type_id     NUMBER,
    CONSTRAINT vehicles_pk PRIMARY KEY (id),
    CONSTRAINT vehicles_users_fk FOREIGN KEY ( users_id )
        REFERENCES users ( id ) ON DELETE CASCADE,
    CONSTRAINT vehicles_vehicle_type_fk FOREIGN KEY ( vehicle_type_id )
        REFERENCES vehicle_types ( id ),
    CONSTRAINT vehicles_locations_fk FOREIGN KEY (current_location_id)
        REFERENCES locations(id)
);


CREATE TABLE reservations (
    id                 NUMBER DEFAULT reservations_seq.nextval NOT NULL,
    status             VARCHAR2(10) NOT NULL,
    charge             NUMBER(7,2),
    pickup_date        DATE NOT NULL,
    dropoff_date       DATE NOT NULL,
    insurance_id       VARCHAR2(20) NOT NULL,
    pickup_location_id NUMBER,
    dropoff_location_id NUMBER,
    passenger_count    NUMBER,
    vehicles_id        NUMBER NOT NULL,
    users_id           NUMBER,
    insurance_types_id NUMBER,
    CONSTRAINT reservations_pk PRIMARY KEY (id),
    CONSTRAINT reservations_insurance_types_fk FOREIGN KEY ( insurance_types_id )
        REFERENCES insurance_types ( id ),
    CONSTRAINT reservations_users_fk FOREIGN KEY ( users_id )
        REFERENCES users ( id ),
    CONSTRAINT reservations_vehicles_fk FOREIGN KEY ( vehicles_id )
        REFERENCES vehicles ( id ),
    CONSTRAINT pickup_location_fk FOREIGN KEY (pickup_location_id)
        REFERENCES locations(id),
    CONSTRAINT dropoff_location_fk FOREIGN KEY (dropoff_location_id)
        REFERENCES locations(id),
    CONSTRAINT status_check CHECK (status IN ('pending', 'active', 'completed', 'cancelled'))
);

CREATE TABLE payment_transactions (
    id                 NUMBER DEFAULT payment_transactions_seq.nextval NOT NULL,
    status             NUMBER NOT NULL,
    amount             NUMBER(7,2) NOT NULL,
    approval_code      VARCHAR2(20),
    reservations_id    NUMBER,
    payment_methods_id NUMBER,
    discount_types_id  NUMBER,
    CONSTRAINT payment_transactions_pk PRIMARY KEY (id),
    CONSTRAINT payment_transactions_discount_types_fk FOREIGN KEY ( discount_types_id )
        REFERENCES discount_types ( id ),
    CONSTRAINT payment_transactions_payment_methods_fk FOREIGN KEY ( payment_methods_id )
        REFERENCES payment_methods ( id ),
    CONSTRAINT payment_transactions_reservations_fk FOREIGN KEY ( reservations_id )
        REFERENCES reservations ( id ),
    CONSTRAINT payment_transactions_status_check CHECK (status IN (1, 0))
);

CREATE TABLE cc_catalog (
    card_number VARCHAR(16)
);

-- Procedure for adding location
CREATE OR REPLACE PROCEDURE add_location (
    pi_name VARCHAR2
) AS
    v_name_count NUMBER;
    e_unique_name EXCEPTION;

BEGIN
    SELECT COUNT(*) INTO v_name_count FROM locations WHERE name = pi_name;

    IF v_name_count = 0 THEN
        INSERT INTO locations VALUES (locations_seq.nextval, pi_name);
        DBMS_OUTPUT.PUT_LINE(pi_name || ' added');
    ELSE
        RAISE e_unique_name;
    END IF;

    COMMIT;

EXCEPTION
    WHEN e_unique_name THEN
        DBMS_OUTPUT.PUT_LINE(pi_name || 'already exists');
    WHEN OTHERS THEN
        RAISE;
        COMMIT;

END add_location;
/

-- Procedure for adding vehicle types
CREATE OR REPLACE PROCEDURE add_vehicle_type (
    pi_make VARCHAR2,
    pi_model VARCHAR2,
    pi_transmission_type VARCHAR2,
    pi_category VARCHAR2,
    pi_fuel_type VARCHAR2
) AS
    v_model_count NUMBER;
    e_unique_name EXCEPTION;

BEGIN
    SELECT COUNT(*) INTO v_model_count FROM vehicle_types WHERE make = pi_make AND model = pi_model;

    IF v_model_count = 0 THEN
        INSERT INTO vehicle_types VALUES (vehicle_types_seq.nextval, pi_make, pi_model, pi_transmission_type, pi_category, pi_fuel_type);
        DBMS_OUTPUT.PUT_LINE(pi_make || '-' || pi_model || ' added');
    ELSE
        RAISE e_unique_name;
    END IF;

    COMMIT;

EXCEPTION
    WHEN e_unique_name THEN
        DBMS_OUTPUT.PUT_LINE(pi_make || '-' || pi_model || ' already exists');
    WHEN OTHERS THEN
        RAISE;
        COMMIT;

END add_vehicle_type;
/


-- Procedure for adding discount types
CREATE OR REPLACE PROCEDURE add_discount_type (
    pi_code VARCHAR2,
    pi_min_amount NUMBER,
    pi_amount NUMBER
) AS
    v_code_count NUMBER;
    e_unique_code EXCEPTION;
    e_invalid_amount EXCEPTION;

BEGIN
    SELECT COUNT(*) INTO v_code_count FROM discount_types WHERE code = pi_code;
    IF pi_amount < 0 THEN
        RAISE e_invalid_amount;
    END IF;

    IF v_code_count = 0 THEN
        INSERT INTO discount_types VALUES (discount_types_seq.nextval, pi_code, pi_min_amount, pi_amount);
        DBMS_OUTPUT.PUT_LINE(pi_code || ' added');
    ELSE
        RAISE e_unique_code;
    END IF;

    COMMIT;

EXCEPTION
    WHEN e_unique_code THEN
        DBMS_OUTPUT.PUT_LINE(pi_code || 'already exists');
    WHEN e_invalid_amount THEN
        DBMS_OUTPUT.PUT_LINE(pi_amount || 'is not a valid discount amount');
    WHEN OTHERS THEN
        RAISE;
        COMMIT;

END add_discount_type;
/

-- Procedure for adding insurance types
CREATE OR REPLACE PROCEDURE add_insurance_type (
    pi_name VARCHAR2,
    pi_coverage NUMBER
) AS
    v_name_count NUMBER;
    e_unique_code EXCEPTION;
    e_invalid_amount EXCEPTION;

BEGIN
    SELECT COUNT(*) INTO v_name_count FROM insurance_types WHERE name = pi_name;
    IF pi_coverage <= 0 THEN
        RAISE e_invalid_amount;
    END IF;

    IF v_name_count = 0 THEN
        INSERT INTO insurance_types VALUES (insurance_types_seq.nextval, pi_coverage, pi_name);
        DBMS_OUTPUT.PUT_LINE(pi_name || ' added');
    ELSE
        RAISE e_unique_code;
    END IF;

    COMMIT;

EXCEPTION
    WHEN e_unique_code THEN
        DBMS_OUTPUT.PUT_LINE(pi_name || 'already exists');
    WHEN e_invalid_amount THEN
        DBMS_OUTPUT.PUT_LINE(pi_coverage || 'is not a valid coverage amount');
    WHEN OTHERS THEN
        RAISE;
        COMMIT;

END add_insurance_type;
/


-- Procedure for adding users
CREATE OR REPLACE PROCEDURE add_user (
    pi_role VARCHAR2,
    pi_fname VARCHAR2,
    pi_lname VARCHAR2,
    pi_location VARCHAR2,
    pi_DL VARCHAR2,
    pi_age NUMBER,
    pi_cname VARCHAR2,
    pi_taxid VARCHAR2
) AS
    v_user_count NUMBER;
    v_location_id locations.id%TYPE;
    e_unique_code EXCEPTION;
    e_incomplete_customer_info EXCEPTION;
    e_incomplete_vendor_info EXCEPTION;
    e_invalid_location_info EXCEPTION;
    e_invalid_role EXCEPTION;
    e_invalid_age EXCEPTION;

BEGIN
    SELECT COUNT(*) INTO v_user_count FROM users WHERE fname = pi_fname AND lname = pi_lname;
    
    IF pi_role != 'customer' AND pi_role != 'vendor' THEN
        RAISE e_invalid_role;
    END IF;

    SELECT id
        INTO v_location_id
        FROM locations
        WHERE name = pi_location;

    IF v_location_id IS NULL THEN
        raise e_invalid_location_info;
    END IF;

    IF pi_role = 'customer' THEN
        IF pi_age < 23 THEN
            RAISE e_invalid_age;
        END IF;

        IF LENGTH(pi_DL) < 16 THEN
            RAISE e_incomplete_customer_info;
        END IF;
    ELSIF pi_role = 'vendor' AND LENGTH(pi_taxid) < 16 AND LENGTH(pi_cname) < 5 THEN
        RAISE e_incomplete_vendor_info;
    END IF;

    IF v_user_count = 0 THEN
        INSERT INTO users (
            role,
            fname,
            lname,
            current_location_id,
            driver_license,
            age,
            company_name,
            tax_id
        ) VALUES (
            pi_role,
            pi_fname,
            pi_lname,
            v_location_id,
            pi_DL,
            pi_age,
            pi_cname,
            pi_taxid
        );

        DBMS_OUTPUT.PUT_LINE(pi_fname || ' added');
    ELSE
        RAISE e_unique_code;
    END IF;

    COMMIT;

EXCEPTION
    WHEN e_unique_code THEN
        DBMS_OUTPUT.PUT_LINE(pi_fname || 'already exists');
    WHEN e_incomplete_customer_info THEN
        DBMS_OUTPUT.PUT_LINE(pi_fname || 'does not have valid customer info');
    WHEN e_incomplete_vendor_info THEN
        DBMS_OUTPUT.PUT_LINE(pi_fname || 'does not have valid vendor info');
    WHEN e_invalid_location_info THEN
        DBMS_OUTPUT.PUT_LINE(pi_location || 'is not valid location info');
    WHEN e_invalid_role THEN
        DBMS_OUTPUT.PUT_LINE(pi_role || 'is not valid role info');
    WHEN e_invalid_age THEN
        DBMS_OUTPUT.PUT_LINE(pi_age || 'is not valid age info');
    WHEN OTHERS THEN
        RAISE;
        COMMIT;

END add_user;
/

-- Procedure for adding vehicles
CREATE OR REPLACE PROCEDURE add_vehicle (
    pi_hourly_rate NUMBER,
    pi_miles_driven NUMBER,
    pi_availability_status VARCHAR2,
    pi_passenger_capacity NUMBER,
    pi_registration_id VARCHAR,
    pi_location_name VARCHAR,
    pi_user_name VARCHAR,
    pi_make VARCHAR

) AS
    v_reg_count NUMBER;
    v_status NUMBER;
    v_location_id vehicle_types.id%TYPE;
    v_vendor_id users.id%TYPE;
    v_vendor_name users.fname%TYPE;
    v_vendor_taxid users.tax_id%TYPE;
    v_role users.role%TYPE;
    v_vehicle_type_id vehicles.id%TYPE;
    e_unique_reg_id EXCEPTION;
    e_invalid_reg_id EXCEPTION;
    e_invalid_ref EXCEPTION;
    e_invalid_pger_count EXCEPTION;
    e_invalid_data EXCEPTION;
    e_invalid_vendor EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO v_reg_count FROM vehicles WHERE registration_id = pi_registration_id;

    IF pi_availability_status = 'true' THEN
        v_status := 1;
    ELSIF pi_availability_status = 'false' THEN
        v_status := 0;
    ELSE
        RAISE e_invalid_data;
    END IF;
    
    IF v_reg_count != 0 THEN
        RAISE e_unique_reg_id;
    END IF;
    
    IF pi_passenger_capacity > 10 THEN
        RAISE e_invalid_pger_count;
    END IF;

    IF LENGTH(pi_registration_id) != 16 THEN
        raise e_invalid_reg_id;
    END IF;

    SELECT id
        INTO v_location_id
        FROM locations
        WHERE name = pi_location_name;

    SELECT id, company_name, tax_id, role
        INTO v_vendor_id, v_vendor_name, v_vendor_taxid, v_role
        FROM users
        WHERE fname = pi_user_name;

    if v_role != 'vendor' OR v_vendor_name IS NULL OR v_vendor_taxid IS NULL THEN
        raise e_invalid_vendor;
    END IF;
    
    SELECT id
        INTO v_vehicle_type_id
        FROM vehicle_types
        WHERE model = pi_make;

    IF v_vendor_id IS NULL OR v_vehicle_type_id IS NULL OR v_location_id IS NULL THEN
        raise e_invalid_ref;
    END IF;

    INSERT INTO vehicles
        VALUES(
            vehicles_seq.nextval,
            pi_hourly_rate,
            pi_miles_driven,
            v_status,
            pi_passenger_capacity,
            pi_registration_id,
            v_location_id,
            v_vendor_id,
            v_vehicle_type_id
        );
    
    DBMS_OUTPUT.PUT_LINE(pi_registration_id || ' vehicle added');
    COMMIT;

EXCEPTION
    WHEN e_unique_reg_id THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || pi_registration_id || ' already exists');
    WHEN e_invalid_reg_id THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || pi_registration_id || ' is invalid');
    WHEN e_invalid_ref THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: References do not exist');
    WHEN e_invalid_pger_count THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || pi_passenger_capacity || ' is invalid');
    WHEN e_invalid_data THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Data is invalid');
    WHEN e_invalid_vendor THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Vendor is invalid');
    WHEN OTHERS THEN
        RAISE;
        COMMIT;

END add_vehicle;
/

-- Procedure for adding reservations
CREATE OR REPLACE PROCEDURE add_reservation (
    pi_status VARCHAR2,
    pi_charge NUMBER,
    pi_pickup_date VARCHAR2,
    pi_dropoff_date VARCHAR2,
    pi_insurance_id VARCHAR2,
    pi_pickup_location_name VARCHAR2,
    pi_dropoff_location_name VARCHAR2,
    pi_passenger_count NUMBER,
    pi_vehicle_registration_id VARCHAR2,
    pi_user_name VARCHAR2,
    pi_insurance_type_name VARCHAR2
) AS
    v_pickup_location_id locations.id%TYPE;
    v_dropoff_location_id locations.id%TYPE;
    v_insurance_type_id insurance_types.id%TYPE;
    v_user_id users.id%TYPE;
    v_vehicle_id vehicles.id%TYPE;
    e_invalid_location EXCEPTION;
    e_invalid_insurance EXCEPTION;
    e_invalid_user EXCEPTION;
    e_invalid_vehicle EXCEPTION;
BEGIN
    SELECT id INTO v_pickup_location_id FROM locations WHERE name = pi_pickup_location_name;
    SELECT id INTO v_dropoff_location_id FROM locations WHERE name = pi_dropoff_location_name;
    SELECT id INTO v_insurance_type_id FROM insurance_types WHERE lower(name) LIKE lower(pi_insurance_type_name);
    SELECT id INTO v_user_id FROM users WHERE fname = pi_user_name;
    SELECT id INTO v_vehicle_id FROM vehicles WHERE registration_id = pi_vehicle_registration_id;

    IF v_pickup_location_id IS NULL OR v_dropoff_location_id IS NULL THEN
        RAISE e_invalid_location;
    END IF;

    IF v_insurance_type_id IS NULL THEN
        RAISE e_invalid_insurance;
    END IF;

    IF v_user_id IS NULL THEN
        RAISE e_invalid_user;
    END IF;

    IF v_vehicle_id IS NULL THEN
        RAISE e_invalid_vehicle;
    END IF;

    INSERT INTO reservations (
        id,
        status,
        charge,
        pickup_date,
        dropoff_date,
        insurance_id,
        pickup_location_id,
        dropoff_location_id,
        passenger_count,
        vehicles_id,
        users_id,
        insurance_types_id
    ) VALUES (
        reservations_seq.nextval,
        pi_status,
        ABS(pi_charge),
        TO_DATE(pi_pickup_date, 'YYYY-MM-DD'),
        TO_DATE(pi_dropoff_date, 'YYYY-MM-DD'),
        pi_insurance_id,
        v_pickup_location_id,
        v_dropoff_location_id,
        pi_passenger_count,
        v_vehicle_id,
        v_user_id,
        v_insurance_type_id
    );

    DBMS_OUTPUT.PUT_LINE('Reservation added');
    COMMIT;

EXCEPTION
    WHEN e_invalid_location THEN
        DBMS_OUTPUT.PUT_LINE('Invalid pickup or dropoff location');
    WHEN e_invalid_insurance THEN
        DBMS_OUTPUT.PUT_LINE('Invalid insurance type');
    WHEN e_invalid_user THEN
        DBMS_OUTPUT.PUT_LINE('Invalid user');
    WHEN e_invalid_vehicle THEN
        DBMS_OUTPUT.PUT_LINE('Invalid vehicle');
    WHEN OTHERS THEN
        RAISE;
        COMMIT;

END add_reservation;
/

-- Procedure for adding payment transactions
CREATE OR REPLACE PROCEDURE add_payment_transaction (
    pi_status VARCHAR2,
    pi_amount NUMBER,
    pi_approval_code VARCHAR2,
    pi_reservation_id NUMBER,
    pi_card_number VARCHAR2,
    pi_discount_code VARCHAR2
) AS
    v_reservation_id reservations.id%TYPE;
    v_status NUMBER;
    v_payment_method_id payment_methods.id%TYPE;
    v_discount_type_id discount_types.id%TYPE;
    e_invalid_reservation EXCEPTION;
    e_invalid_payment_method EXCEPTION;
    e_invalid_discount_type EXCEPTION;
    e_invalid_data EXCEPTION;
BEGIN
    SELECT id INTO v_reservation_id FROM reservations WHERE id = pi_reservation_id;

    IF v_reservation_id IS NULL THEN
        RAISE e_invalid_reservation;
    END IF;

    IF pi_status = 'pending' THEN
        v_status := 0;
    ELSIF pi_status = 'completed' THEN
        v_status := 1;
    ELSE
        RAISE e_invalid_data;
    END IF;

    SELECT id INTO v_payment_method_id FROM payment_methods WHERE card_number = pi_card_number;

    IF v_payment_method_id IS NULL THEN
        RAISE e_invalid_payment_method;
    END IF;

    
    SELECT id INTO v_discount_type_id FROM discount_types WHERE code = pi_discount_code;
    
    IF pi_discount_code IS NULL OR pi_discount_code = '' THEN
        SELECT id INTO v_discount_type_id FROM discount_types WHERE code = 'NO_DISC';
    ELSE
        SELECT id INTO v_discount_type_id FROM discount_types WHERE code = pi_discount_code;
    END IF;

    INSERT INTO payment_transactions (
        id,
        status,
        amount,
        approval_code,
        reservations_id,
        payment_methods_id,
        discount_types_id
    ) VALUES (
        payment_transactions_seq.nextval,
        v_status,
        pi_amount,
        pi_approval_code,
        v_reservation_id,
        v_payment_method_id,
        v_discount_type_id
    );

    DBMS_OUTPUT.PUT_LINE('Payment transaction added');
    COMMIT;

EXCEPTION
    WHEN e_invalid_reservation THEN
        DBMS_OUTPUT.PUT_LINE('Invalid reservation');
    WHEN e_invalid_payment_method THEN
        DBMS_OUTPUT.PUT_LINE('Invalid payment method');
    WHEN e_invalid_discount_type THEN
        DBMS_OUTPUT.PUT_LINE('Invalid discount type');
    WHEN e_invalid_data THEN
        DBMS_OUTPUT.PUT_LINE('Invalid status');
    WHEN OTHERS THEN
        RAISE;
        ROLLBACK;

END add_payment_transaction;
/

-- Update procedures

-- Update insurance type (available to insurnace analust)
CREATE OR REPLACE PROCEDURE update_insurance_type (
    pi_insurance_type_name VARCHAR2,
    pi_new_coverage NUMBER
) AS
    v_insurance_type_id insurance_types.id%TYPE;
    e_not_found EXCEPTION;
BEGIN
    -- Find the insurance type ID based on the name
    SELECT id INTO v_insurance_type_id
    FROM insurance_types
    WHERE lower(name) LIKE lower(pi_insurance_type_name);

    -- Check if the insurance type exists
    IF v_insurance_type_id IS NOT NULL THEN
        -- Update the coverage amount
        UPDATE insurance_types
        SET coverage = pi_new_coverage
        WHERE id = v_insurance_type_id;

        DBMS_OUTPUT.PUT_LINE('Insurance type ' || pi_insurance_type_name || ' updated with new coverage: ' || pi_new_coverage);
    ELSE
        RAISE e_not_found;
    END IF;

    COMMIT;

EXCEPTION
    WHEN e_not_found THEN
        DBMS_OUTPUT.PUT_LINE(pi_insurance_type_name || 'does not exist');
    WHEN OTHERS THEN
        RAISE;
        ROLLBACK;

END update_insurance_type;
/


-- View: insurance analytics (count of reservations for each and total revenue from each)
CREATE OR REPLACE VIEW view_insurance_res_rev AS
SELECT
    it.id AS insurance_type_id,
    it.name AS insurance_type_name,
    COUNT(r.id) AS reservation_count,
    NVL(SUM(pt.amount), 0) AS total_revenue
FROM
    reservations r 
LEFT JOIN
    insurance_types it ON r.insurance_types_id = it.id
LEFT JOIN
    (SELECT * FROM payment_transactions WHERE status = 1) pt ON r.id = pt.reservations_id
GROUP BY
    it.id, it.name;


-- view: Insurance analytics (top performing insurance type by vehicle type) (note:rank over)
CREATE OR REPLACE VIEW view_insurance_top_performer AS
SELECT
    v.make,
    v.model,
    it.name AS insurance_type_name,
    COUNT(r.id) AS reservation_count
FROM reservations r
JOIN insurance_types it ON r.insurance_types_id = it.id
JOIN (
        SELECT tv.id as id, tvtp.make, tvtp.model 
        FROM vehicles tv 
        JOIN vehicle_types tvtp 
            ON tv.vehicle_type_id = tvtp.id
    ) v ON r.vehicles_id = v.id
GROUP BY
    v.make,
    v.model,
    it.name
ORDER BY
    COUNT(r.id) DESC;


-- View: Analytics rental frequency and revenue by vehicle type
CREATE OR REPLACE VIEW rentals_and_revenue_by_vehicle_type AS
SELECT
    vt.id AS vehicle_type_id,
    vt.make AS make,
    vt.model AS model,
    COUNT(r.id) AS number_of_rentals,
    NVL(SUM(pt.amount), 0) AS total_revenue
FROM
    vehicle_types vt
LEFT JOIN
    vehicles v ON vt.id = v.vehicle_type_id
LEFT JOIN
    reservations r ON v.id = r.vehicles_id
LEFT JOIN
    payment_transactions pt ON r.id = pt.reservations_id
GROUP BY
    vt.id, vt.make, vt.model
ORDER BY
    NVL(SUM(pt.amount), 0) DESC, COUNT(r.id) DESC;


-- View: no of rentals and revenue by vendor
CREATE OR REPLACE VIEW rentals_revenue_by_vendor AS
SELECT 
    u.fname || ' ' || u.lname AS vendor_name,
    count(r.id) as no_of_rentals,
    ABS(NVL(SUM(r.charge), 0)) AS total_revenue
FROM reservations r
join vehicles v on r.vehicles_id = v.id
join users u on v.users_id = u.id   
group by u.fname, u.lname
order by count(r.id) desc, NVL(SUM(r.charge), 0) desc;


-- View: revenue by demographic (10 years age range)
CREATE OR REPLACE VIEW revenue_by_demographic AS
SELECT
    FLOOR((u.age - 1) / 10) * 10 AS age_range_start,
    FLOOR((u.age - 1) / 10) * 10 + 9 AS age_range_end,
    COUNT(r.id) AS reservation_count,
    SUM(pt.amount) AS total_revenue
FROM
    reservations r
JOIN
    users u ON r.users_id = u.id
JOIN
    (select * from payment_transactions where STATUS = 1) pt ON r.id = pt.reservations_id
GROUP BY
    FLOOR((u.age - 1) / 10) * 10, FLOOR((u.age - 1) / 10) * 10 + 9
ORDER BY
    COUNT(r.id) DESC, SUM(pt.amount) DESC;

-- View: revenue by user’s location
CREATE OR REPLACE VIEW revenue_by_location_view AS
SELECT
    l.name,
    NVL(SUM(vt.amount), 0) AS revenue
FROM
    (
        SELECT
            pt.reservations_id AS id,
            r.pickup_location_id AS location_id,
            pt.amount AS amount
        FROM
            payment_transactions pt
        JOIN
            reservations r ON pt.reservations_id = r.id
        WHERE
            pt.status = 1
            AND r.status = 'completed'
    ) vt
JOIN
    locations l ON vt.location_id = l.id
GROUP BY
    l.name
ORDER BY
    NVL(SUM(vt.amount), 0) DESC;

-- View: no of rentals by discount_type
CREATE OR REPLACE VIEW view_rentals_by_discount_type as
select dt.code, count(r.id) as reservation_frequency
from reservations r
join payment_transactions pt on r.id = pt.reservations_id
join discount_types dt on pt.discount_types_id = dt.id
group by dt.code
order by count(r.id) desc;

-- View: total booking last week
CREATE OR REPLACE VIEW view_total_booking_last_week as
select * 
from reservations
where pickup_date >= sysdate - 7
order by pickup_date desc;

-- View: all available cars
CREATE OR REPLACE VIEW view_all_available_cars as
select * 
from vehicles 
where id not in (
    select vehicles_id from reservations where status = 'active'
);

-- view all rental history
create or replace view view_all_rental_history as
SELECT
    r.id as id,
    u.id as user_id,
    u.fname || ' ' || u.lname AS customer_name,
    vt.make || '-' || vt.model AS car_name,
    r.pickup_date,
    r.dropoff_date,
    r.charge
FROM
    reservations r
JOIN
    users u ON r.users_id = u.id
JOIN
    vehicles ON r.vehicles_id = vehicles.id
JOIN
    vehicle_types vt ON vehicles.vehicle_type_id = vt.id
WHERE
    r.status = 'completed'
ORDER BY
    u.fname || ' ' || u.lname, r.pickup_date DESC;



-- Function: get_reservation_id
CREATE OR REPLACE FUNCTION get_reservation_id(
    pi_user_name VARCHAR2,
    pi_vehicle_registration_id VARCHAR2,
    pi_pickup_date VARCHAR2
) RETURN NUMBER IS
    v_reservation_id NUMBER;
    v_pick_date DATE;
    v_vehicle_id NUMBER;
    v_user_id NUMBER;
    e_invalid_reference EXCEPTION;
BEGIN
    v_pick_date:= TO_DATE(pi_pickup_date, 'YYYY-MM-DD');
    SELECT id INTO v_vehicle_id FROM vehicles WHERE registration_id = pi_vehicle_registration_id;
    SELECT id INTO v_user_id FROM users WHERE fname = pi_user_name;
    
    IF v_vehicle_id IS NULL OR v_user_id IS NULL THEN
        raise e_invalid_reference;
    END IF;
    
    SELECT id
    INTO v_reservation_id
    FROM reservations
    WHERE users_id = v_user_id
    AND vehicles_id = v_vehicle_id
    AND pickup_date = v_pick_date
    FETCH FIRST 1 ROW ONLY;

    RETURN v_reservation_id;
EXCEPTION
    WHEN e_invalid_reference THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Invalid vehicle or user');
        RETURN NULL;
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: No reservation found');
        RETURN NULL;
    WHEN OTHERS THEN
        RAISE;
END;
/

CREATE OR REPLACE FUNCTION IsDateFormat(input_string VARCHAR2)
RETURN NUMBER IS
    is_valid NUMBER := 1;
BEGIN
    IF LENGTH(input_string) <> 10 THEN
        is_valid := 0;
    ELSIF SUBSTR(input_string, 5, 1) <> '-' OR SUBSTR(input_string, 8, 1) <> '-' THEN
        is_valid := 0;
    ELSIF NOT (REGEXP_LIKE(SUBSTR(input_string, 1, 4), '^[0-9]+$')) THEN
        is_valid := 0;
    ELSIF NOT (REGEXP_LIKE(SUBSTR(input_string, 6, 2), '^[0-9]+$')) THEN
        is_valid := 0;
    ELSIF NOT (REGEXP_LIKE(SUBSTR(input_string, 9, 2), '^[0-9]+$')) THEN
        is_valid := 0;
    END IF;
    
    RETURN is_valid;
END;
/

CREATE OR REPLACE FUNCTION IsDateFormatmmyyyy(input_string VARCHAR2)
RETURN NUMBER IS
    is_valid NUMBER := 1;
BEGIN
    IF LENGTH(input_string) <> 7 THEN
        is_valid := 0;
    ELSIF SUBSTR(input_string, 3, 1) <> '-' THEN
        is_valid := 0;
    ELSIF NOT (REGEXP_LIKE(SUBSTR(input_string, 1, 2), '^[0-9]+$')) THEN
        is_valid := 0;
    ELSIF NOT (REGEXP_LIKE(SUBSTR(input_string, 4, 4), '^[0-9]+$')) THEN
        is_valid := 0;
    END IF;
    
    RETURN is_valid;
END;
/

CREATE OR REPLACE FUNCTION ConvertDateFormatmmyyyy(input_string VARCHAR2)
RETURN VARCHAR2 IS
    output_string VARCHAR2(10);
BEGIN
    output_string := SUBSTR(input_string, 4, 4) || '-' || SUBSTR(input_string, 1, 2) || '-01';
    RETURN output_string;
END;
/

CREATE OR REPLACE PROCEDURE add_payment_method (
    pi_card_number VARCHAR2,
    pi_active_status VARCHAR2,
    pi_expiration_date VARCHAR2,
    pi_security_code VARCHAR2,
    pi_billing_address VARCHAR2,
    pi_user_name VARCHAR
) AS
    v_card_count NUMBER;
    v_status NUMBER;
    v_expiration_date DATE;
    v_datecheck NUMBER;
    e_unique_name EXCEPTION;
    v_user_id users.id%TYPE;
    e_invalid_ref EXCEPTION;
    e_invalid_data EXCEPTION;

BEGIN
    SELECT COUNT(*) INTO v_card_count FROM payment_methods WHERE card_number = pi_card_number;
    
    v_datecheck := IsDateFormatmmyyyy(pi_expiration_date);
    IF v_datecheck = 1 THEN
        v_expiration_date := TO_DATE(ConvertDateFormatmmyyyy(pi_expiration_date), 'YYYY-MM-DD');
    ELSE
        v_expiration_date := TO_DATE(pi_expiration_date, 'YYYY-MM-DD');
    END IF;
    
    IF pi_active_status = 'true' THEN
        v_status := 1;
    ELSIF pi_active_status = 'false' THEN
        v_status := 0;
    ELSE
        RAISE e_invalid_data;
    END IF;
    
    SELECT id
        INTO v_user_id
        FROM users
        WHERE fname = pi_user_name;

    IF v_user_id IS NULL THEN
        RAISE e_invalid_ref;
    END IF;

    IF LENGTH(pi_card_number) != 16 OR LENGTH(pi_security_code) != 3 OR v_expiration_date < SYSDATE THEN
        RAISE e_invalid_data;
    END IF;

    IF v_card_count = 0 THEN
        INSERT INTO payment_methods (id, active_status, card_number, expiration_date, security_code, billing_address, users_id)
        VALUES (payment_methods_seq.nextval, v_status, pi_card_number, v_expiration_date, pi_security_code, pi_billing_address, v_user_id);

        DBMS_OUTPUT.PUT_LINE(pi_card_number || ' added');
    ELSE
        RAISE e_unique_name;
    END IF;

    COMMIT;

EXCEPTION
    WHEN e_unique_name THEN
        DBMS_OUTPUT.PUT_LINE(pi_card_number || ' already exists');
    WHEN e_invalid_ref THEN
        DBMS_OUTPUT.PUT_LINE('References do not exist');
    WHEN e_invalid_data THEN
        DBMS_OUTPUT.PUT_LINE('Invalid data');
    WHEN OTHERS THEN
        RAISE;
        ROLLBACK;

END add_payment_method;
/




-- Package: Customer reservation flow
CREATE OR REPLACE PACKAGE booking_package AS
    -- Procedure: initiate booking
    PROCEDURE initiate_booking (
        pi_pickup_date VARCHAR2,
        pi_dropoff_date VARCHAR2,
        pi_pickup_location_name VARCHAR2,
        pi_dropoff_location_name VARCHAR2,
        pi_passenger_count NUMBER,
        pi_vehicle_registration_id VARCHAR2,
        pi_user_name VARCHAR2,
        pi_insurance_type_name VARCHAR2
    );

    -- Function: generate insurance ID
    FUNCTION generate_insurance_id(insurance_name_string VARCHAR2) RETURN VARCHAR2;

    -- Procedure: initiate payment transaction
    PROCEDURE initiate_payment_transaction (
        pi_user_name IN VARCHAR2,
        pi_vehicle_registration_id IN VARCHAR2,
        pi_pick_up_date IN VARCHAR2,
        pi_card_number    IN VARCHAR2,
        pi_discount_code  IN VARCHAR2 DEFAULT NULL
    );

    -- Procedure: approve payment transactions
    PROCEDURE approve_transaction (
        pi_user_name IN VARCHAR2,
        pi_vehicle_registration_id IN VARCHAR2,
        pi_pick_up_date IN VARCHAR2
    );
END booking_package;
/

CREATE OR REPLACE PACKAGE BODY booking_package AS
    -- Procedure: initiate booking
    PROCEDURE initiate_booking (
        pi_pickup_date VARCHAR2,
        pi_dropoff_date VARCHAR2,
        pi_pickup_location_name VARCHAR2,
        pi_dropoff_location_name VARCHAR2,
        pi_passenger_count NUMBER,
        pi_vehicle_registration_id VARCHAR2,
        pi_user_name VARCHAR2,
        pi_insurance_type_name VARCHAR2
    ) AS
        v_hourly_rate vehicles.hourly_rate%TYPE;    
        v_charge NUMBER;
        v_insurance_id reservations.insurance_id%TYPE;
        v_no_days NUMBER;
        v_pickup_location_id locations.id%TYPE;
        v_dropoff_location_id locations.id%TYPE;
        v_insurance_type_id insurance_types.id%TYPE;
        v_user_id users.id%TYPE;
        v_vehicle_id vehicles.id%TYPE;    
        v_pick_date DATE;
        v_drop_date DATE;
        e_invalid_location EXCEPTION;
        e_invalid_insurance EXCEPTION;
        e_invalid_user EXCEPTION;
        e_invalid_vehicle EXCEPTION;
        e_passenger_count EXCEPTION;
    BEGIN
        IF pi_passenger_count > 10 THEN
            RAISE e_passenger_count;
        END IF;

        SELECT id INTO v_pickup_location_id FROM locations WHERE name = pi_pickup_location_name;
        SELECT id INTO v_dropoff_location_id FROM locations WHERE name = pi_dropoff_location_name;
        SELECT id INTO v_insurance_type_id FROM insurance_types WHERE lower(name) LIKE lower(pi_insurance_type_name);
        SELECT id INTO v_user_id FROM users WHERE fname = pi_user_name;
        SELECT id, hourly_rate INTO v_vehicle_id, v_hourly_rate FROM vehicles WHERE registration_id = pi_vehicle_registration_id;

        IF v_pickup_location_id IS NULL OR v_dropoff_location_id IS NULL THEN
            RAISE e_invalid_location;
        END IF;

        IF v_insurance_type_id IS NULL THEN
            RAISE e_invalid_insurance;
        END IF;

        IF v_user_id IS NULL THEN
            RAISE e_invalid_user;
        END IF;

        IF v_vehicle_id IS NULL THEN
            RAISE e_invalid_vehicle;
        END IF;

        v_pick_date:= TO_DATE(pi_pickup_date, 'YYYY-MM-DD');
        v_drop_date:= TO_DATE(pi_dropoff_date, 'YYYY-MM-DD');
        v_no_days:= v_drop_date - v_pick_date;
        v_charge := v_hourly_rate * ABS(v_no_days) * 24;
        v_insurance_id := generate_insurance_id(pi_insurance_type_name);

        INSERT INTO reservations (
            id,
            status,
            charge,
            pickup_date,
            dropoff_date,
            insurance_id,
            pickup_location_id,
            dropoff_location_id,
            passenger_count,
            vehicles_id,
            users_id,
            insurance_types_id
        ) VALUES (
            reservations_seq.nextval,
            'pending',
            ABS(v_charge),
            v_pick_date,
            v_drop_date,
            v_insurance_id,
            v_pickup_location_id,
            v_dropoff_location_id,
            pi_passenger_count,
            v_vehicle_id,
            v_user_id,
            v_insurance_type_id
        );

        DBMS_OUTPUT.PUT_LINE('Reservation added');
        COMMIT;

    EXCEPTION
        WHEN e_invalid_location THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Invalid pickup or dropoff location');
        WHEN e_invalid_insurance THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Invalid insurance type');
        WHEN e_invalid_user THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Invalid user');
        WHEN e_invalid_vehicle THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Invalid vehicle');
        WHEN e_passenger_count THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: Passenger count exceeds limit');
        WHEN OTHERS THEN
            RAISE;
            COMMIT;

    END initiate_booking;

    -- Function: generate insurance ID
    FUNCTION generate_insurance_id(insurance_name_string VARCHAR2) RETURN VARCHAR2 IS
        v_prefix VARCHAR2(2) := SUBSTR(LOWER(insurance_name_string), 1, 2);
        v_suffix VARCHAR2(4) := LPAD(DBMS_RANDOM.VALUE(0, 9999), 4, '0');
    BEGIN
        RETURN v_prefix || v_suffix;
    END generate_insurance_id;

    -- Procedure: initiate payment transaction
    PROCEDURE initiate_payment_transaction (
        pi_user_name IN VARCHAR2,
        pi_vehicle_registration_id IN VARCHAR2,
        pi_pick_up_date IN VARCHAR2,
        pi_card_number    IN VARCHAR2,
        pi_discount_code  IN VARCHAR2 DEFAULT NULL
    ) AS
        pi_reservation_id reservations.id%TYPE;
        v_reservation_status reservations.status%TYPE;
        v_amount             reservations.charge%TYPE;
        v_discount_amount    discount_types.discount_amount%TYPE;
        v_payment_status     payment_transactions.status%TYPE;
        v_payment_method_id  payment_methods.id%TYPE;
        v_discount_type_id   discount_types.id%TYPE;
        v_users_id           reservations.users_id%TYPE;
        v_pm_users_id        payment_methods.users_id%TYPE;
        v_expiration_date    payment_methods.expiration_date%TYPE;
        e_reservation_not_found     EXCEPTION;
        e_payment_method_not_found  EXCEPTION;
        e_invalid_discount_code     EXCEPTION;
        e_invalid_reservation_state EXCEPTION;
        e_invalid_discount_amount   EXCEPTION;
        e_invalid_data              EXCEPTION;
    BEGIN
        pi_reservation_id := get_reservation_id(pi_user_name, pi_vehicle_registration_id, pi_pick_up_date);
        -- Check if the reservation ID exists
        SELECT status, charge, users_id
        INTO v_reservation_status, v_amount, v_users_id
        FROM reservations
        WHERE id = pi_reservation_id;

        -- Exception: Reservation ID not found
        IF v_reservation_status IS NULL THEN
            RAISE e_reservation_not_found;
        END IF;

        -- Check if the reservation status is 'active' or 'pending'
        IF v_reservation_status != 'active' and v_reservation_status != 'pending' THEN
            RAISE e_invalid_reservation_state;
        END IF;

        -- Check if the payment method exists
        SELECT id, active_status, users_id, expiration_date
        INTO v_payment_method_id, v_payment_status, v_pm_users_id, v_expiration_date
        FROM payment_methods
        WHERE card_number = pi_card_number;

        -- Exception: Payment method not found
        IF v_payment_method_id IS NULL THEN
            RAISE e_payment_method_not_found;
        END IF;

        -- Exception: Payment method is not active
        IF v_payment_status != 1 OR v_pm_users_id != v_users_id OR v_expiration_date < sysdate THEN
            RAISE e_invalid_data;
        END IF;

        -- Check if a discount code is provided
        IF pi_discount_code IS NOT NULL THEN
            -- Check if the discount code exists
            SELECT id, discount_amount
            INTO v_discount_type_id, v_discount_amount
            FROM discount_types
            WHERE code = pi_discount_code;

            -- Exception: Invalid discount code
            IF v_discount_type_id IS NULL THEN
                RAISE e_invalid_discount_code;
            END IF;

            -- Exception: Discount amount is negative
            IF v_discount_amount < 0 THEN
                RAISE e_invalid_discount_amount;
            END IF;
        END IF;

        -- Insert payment transaction record
        INSERT INTO payment_transactions (
            status,
            amount,
            approval_code,
            reservations_id,
            payment_methods_id,
            discount_types_id
        ) VALUES (
            0, -- Pending status
            (v_amount - NVL(v_discount_amount, 0)), -- Apply discount if available
            NULL,
            pi_reservation_id,
            v_payment_method_id,
            v_discount_type_id
        );

        DBMS_OUTPUT.PUT_LINE('Payment transaction initiated for Reservation ID: ' || pi_reservation_id || 'payment_id:' || payment_transactions_seq.currval);
        COMMIT;

    EXCEPTION
        WHEN e_reservation_not_found THEN
            DBMS_OUTPUT.PUT_LINE('Error: Reservation ID not found.');
        WHEN e_payment_method_not_found THEN
            DBMS_OUTPUT.PUT_LINE('Error: Payment method not found.');
        WHEN e_invalid_discount_code THEN
            DBMS_OUTPUT.PUT_LINE('Error: Invalid discount code.');
        WHEN e_invalid_reservation_state THEN
            DBMS_OUTPUT.PUT_LINE('Error: Reservation is not in active state.');
        WHEN e_invalid_discount_amount THEN
            DBMS_OUTPUT.PUT_LINE('Error: Invalid discount amount.');
        WHEN e_invalid_data THEN
            DBMS_OUTPUT.PUT_LINE('Error: Invalid data.');
        WHEN OTHERS THEN
            RAISE;
            ROLLBACK;
    END initiate_payment_transaction;

    -- Procedure: approve payment transactions
    PROCEDURE approve_transaction (
        pi_user_name IN VARCHAR2,
        pi_vehicle_registration_id IN VARCHAR2,
        pi_pick_up_date IN VARCHAR2
    ) AS
        pi_reservation_id reservations.id%TYPE;
        v_approval_code VARCHAR2(16);
        e_reservation_not_found EXCEPTION;
    BEGIN
        pi_reservation_id := get_reservation_id(pi_user_name, pi_vehicle_registration_id, pi_pick_up_date);
        
        -- Check if the reservation ID exists
        if pi_reservation_id IS NULL THEN
            RAISE e_reservation_not_found;
        END IF;
    
        -- Generate a random 16-character approval code
        v_approval_code := DBMS_RANDOM.STRING('A', 16);

        -- Update payment transaction record with the approval code and set status to approved
        UPDATE payment_transactions
        SET status = 1, -- Set status to approved
            approval_code = v_approval_code
        WHERE reservations_id = pi_reservation_id and approval_code IS NULL;

        DBMS_OUTPUT.PUT_LINE('Transaction Approved. Approval Code: ' || v_approval_code);
        COMMIT;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Error: Transaction ID not found.');
        WHEN OTHERS THEN
            RAISE;
            ROLLBACK;
    END approve_transaction;
END booking_package;
/


-- Procedure: Cancel a booking (should happen only if reservation isn't active yet)
CREATE OR REPLACE PROCEDURE cancel_reservation (
    pi_reservation_id IN NUMBER
) AS
    v_reservation_status VARCHAR2(10);

    -- Exceptions
    e_booking_not_found EXCEPTION;
    e_invalid_reservation_state EXCEPTION;

BEGIN
    -- Check if the reservation ID exists
    SELECT status
    INTO v_reservation_status
    FROM reservations
    WHERE id = pi_reservation_id;

    -- Exception: Booking ID not found
    IF v_reservation_status IS NULL THEN
        RAISE e_booking_not_found;
    END IF;

    -- Exception: Booking ID found but not in pending state
    IF v_reservation_status != 'pending' THEN
        RAISE e_invalid_reservation_state;
    END IF;

    -- Update the reservation status to canceled
    UPDATE reservations
    SET status = 'cancelled'
    WHERE id = pi_reservation_id;

    DBMS_OUTPUT.PUT_LINE('Reservation ' || pi_reservation_id || ' has been cancelled.');
    COMMIT;

EXCEPTION
    WHEN e_booking_not_found THEN
        DBMS_OUTPUT.PUT_LINE('Error: Reservation ID not found.');
    WHEN e_invalid_reservation_state THEN
        DBMS_OUTPUT.PUT_LINE('Error: Reservation is not in pending state.');
    WHEN OTHERS THEN
        RAISE;
        ROLLBACK;
END cancel_reservation;
/


-- Function: Retrieve rental records for a user
CREATE OR REPLACE FUNCTION get_user_completed_reservations(user_id IN NUMBER)
RETURN SYS_REFCURSOR
AS
    c_reservations SYS_REFCURSOR;
BEGIN
    OPEN c_reservations FOR
        SELECT
            r.id as id,
            u.id as user_id,
            u.fname || ' ' || u.lname AS customer_name,
            vt.make || '-' || vt.model AS car_name,
            r.pickup_date,
            r.dropoff_date,
            r.charge
        FROM
            reservations r
        JOIN
            users u ON r.users_id = u.id
        JOIN
            vehicles ON r.vehicles_id = vehicles.id
        JOIN
            vehicle_types vt ON vehicles.vehicle_type_id = vt.id
        WHERE
            r.status = 'completed' and u.id = user_id
        ORDER BY
            u.fname || ' ' || u.lname, r.pickup_date DESC;
    RETURN c_reservations;
END;
/

create or replace view cust_rental_history as
SELECT
    r.id as id,
    u.id as user_id,
    u.fname || ' ' || u.lname AS customer_name,
    vt.make || '-' || vt.model AS car_name,
    r.pickup_date,
    r.dropoff_date,
    r.charge
FROM
    reservations r
JOIN
    users u ON r.users_id = u.id
JOIN
    vehicles ON r.vehicles_id = vehicles.id
JOIN
    vehicle_types vt ON vehicles.vehicle_type_id = vt.id
WHERE
    r.status = 'completed'
ORDER BY
    u.fname || ' ' || u.lname, r.pickup_date DESC;

-- Procedure: Display rental history
CREATE OR REPLACE PROCEDURE get_user_reservations_history(user_id IN NUMBER) AS
    l_reservations SYS_REFCURSOR;
    r_reservation cust_rental_history%ROWTYPE;
BEGIN
    l_reservations := get_user_completed_reservations(user_id);
    LOOP
        BEGIN
            FETCH l_reservations INTO r_reservation;
            EXIT WHEN l_reservations%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE(r_reservation.id || ', ' || r_reservation.customer_name || ', ' || r_reservation.car_name || ', ' || r_reservation.pickup_date || ', ' || r_reservation.dropoff_date || ', ' || r_reservation.charge);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('No reservations found.');
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
        END;
    END LOOP;
    CLOSE l_reservations;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
/

-- Update expired reservations to cancelled
CREATE OR REPLACE TRIGGER trg_update_expired_reservations
BEFORE INSERT OR UPDATE ON reservations
FOR EACH ROW
BEGIN
-- Update vehicles availability_status to 0
    UPDATE vehicles
    SET availability_status = 0
    WHERE id = :NEW.vehicles_id and :NEW.status = 'active';

    IF :NEW.dropoff_date < SYSDATE AND :NEW.status != 'completed' THEN
        :NEW.status := 'cancelled';
        DBMS_OUTPUT.PUT_LINE('Reservation ' || :NEW.id || ' updated status: cancelled by trigger.');
    END IF;
END;
/

-- set vehicles to unavailable when reservation is active
-- CREATE OR REPLACE TRIGGER trg_update_vehicle_availability
-- AFTER INSERT OR UPDATE ON reservations
-- FOR EACH ROW
-- BEGIN
--     IF :NEW.status = 'active' THEN
--         UPDATE vehicles
--         SET availability_status = 0
--         WHERE id = :NEW.vehicles_id;

--         DBMS_OUTPUT.PUT_LINE('Vehicle availability status updated to 0 for Reservation ' || :NEW.id);
--     END IF;
-- END;
-- /

-- CREATE OR REPLACE TRIGGER trg_update_vehicle_availability
-- AFTER INSERT OR UPDATE ON reservations
-- FOR EACH ROW
-- BEGIN
--     IF :NEW.status = 'cancelled' OR :NEW.status = 'completed' THEN
--         UPDATE vehicles
--         SET availability_status = 1
--         WHERE id = :NEW.vehicles_id;

--         DBMS_OUTPUT.PUT_LINE('Vehicle availability status updated to 1 for Reservation ' || :NEW.id);
--     END IF;
-- END;
-- /


-- View payment methods for a user
CREATE OR REPLACE PROCEDURE get_payment_methods(
    p_user_name IN VARCHAR2
) AS
    p_payment_methods SYS_REFCURSOR;
    l_payment_method payment_methods%ROWTYPE;
    v_users_id users.id%TYPE;
BEGIN
    SELECT id INTO v_users_id FROM users WHERE fname = p_user_name;

    OPEN p_payment_methods FOR
    SELECT *
    FROM payment_methods
    WHERE users_id = v_users_id;
    
    LOOP
        FETCH p_payment_methods INTO l_payment_method;
        EXIT WHEN p_payment_methods%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Payment Method ID: ' || l_payment_method.card_number || ', expiration_date: ' || l_payment_method.expiration_date);
    END LOOP;
    
    CLOSE p_payment_methods;
END;
/

-- Procedure: Update car availability
create or replace procedure update_car_availability(
    pi_registration_id VARCHAR2,
    pi_available VARCHAR2
) as
    v_status number;
    e_invalid_data EXCEPTION;
begin
    IF pi_available = 'true' THEN
        v_status := 1;
    ELSIF pi_available = 'false' THEN
        v_status := 0;
    ELSE
        RAISE e_invalid_data;
    END IF;

    update vehicles
    set availability_status = v_status
    where registration_id = pi_registration_id;
    commit;
EXCEPTION
    WHEN e_invalid_data THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Invalid data');
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: Vehicle not found');
    WHEN OTHERS then
        raise;
        commit;
end update_car_availability;
/

CREATE OR REPLACE FUNCTION get_vendor_reservations(vendor_id IN NUMBER)
RETURN SYS_REFCURSOR
AS
    c_reservations SYS_REFCURSOR;
BEGIN
    OPEN c_reservations FOR
        SELECT
            r.id as id,
            u.id as customer_id,
            vhc.users_id as vendor_id,
            u.fname || ' ' || u.lname AS customer_name,
            vt.make || '-' || vt.model AS car_name,
            r.pickup_date,
            r.dropoff_date,
            r.charge
        FROM
            reservations r
        JOIN
            users u ON r.users_id = u.id
        JOIN
            vehicles vhc ON r.vehicles_id = vhc.id
        JOIN
            vehicle_types vt ON vhc.vehicle_type_id = vt.id
        WHERE
            vhc.users_id = vendor_id
        ORDER BY
            u.fname || ' ' || u.lname, r.pickup_date DESC;
    RETURN c_reservations;
END;
/

create or replace view vendor_rental_history as
SELECT
    r.id as id,
    u.id as customer_id,
    vhc.users_id as vendor_id,
    u.fname || ' ' || u.lname AS customer_name,
    vt.make || '-' || vt.model AS car_name,
    r.pickup_date,
    r.dropoff_date,
    r.charge
FROM
    reservations r
JOIN
    users u ON r.users_id = u.id
JOIN
    vehicles vhc ON r.vehicles_id = vhc.id
JOIN
    vehicle_types vt ON vhc.vehicle_type_id = vt.id
ORDER BY
    u.fname || ' ' || u.lname, r.pickup_date DESC;

-- Procedure: Display vendor rental history
CREATE OR REPLACE PROCEDURE get_vendor_reservations_history(vendor_id IN NUMBER) AS
    l_reservations SYS_REFCURSOR;
    r_reservation vendor_rental_history%ROWTYPE;
BEGIN
    l_reservations := get_vendor_reservations(vendor_id);
    LOOP
        BEGIN
            FETCH l_reservations INTO r_reservation;
            EXIT WHEN l_reservations%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE(r_reservation.id || ', ' || r_reservation.customer_name || ', ' || r_reservation.car_name || ', ' || r_reservation.pickup_date || ', ' || r_reservation.dropoff_date || ', ' || r_reservation.charge);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('No reservations found.');
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
        END;
    END LOOP;
    CLOSE l_reservations;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
/

-- Function: Get vendor vehicles
CREATE OR REPLACE FUNCTION get_vendor_vehicles(vendor_id IN NUMBER)
RETURN SYS_REFCURSOR
AS
    c_vehicles SYS_REFCURSOR;
BEGIN
    OPEN c_vehicles FOR
        SELECT
            vhc.id,
            vt.make || '-' || vt.model AS car_name,
            vhc.passenger_capacity,
            vhc.availability_status,
            vt.category,
            vt.fuel_type
        FROM
            vehicles vhc
        JOIN
            vehicle_types vt ON vhc.vehicle_type_id = vt.id
        JOIN
            users u ON vhc.users_id = u.id
        WHERE
            vhc.users_id = vendor_id;
    RETURN c_vehicles;
END;
/

-- View: All vendor vehicles
create or replace view all_vendor_vehicles as
SELECT
    vhc.id,
    vt.make || '-' || vt.model AS car_name,
    vhc.passenger_capacity,
    vhc.availability_status,
    vt.category,
    vt.fuel_type
FROM
    vehicles vhc
JOIN
    vehicle_types vt ON vhc.vehicle_type_id = vt.id
JOIN
    users u ON vhc.users_id = u.id;

-- Procedure: Display vendor vehicles
CREATE OR REPLACE PROCEDURE get_vendor_vehicle_list(vendor_id IN NUMBER) AS
    l_vehicles SYS_REFCURSOR;
    v_avail_status VARCHAR2(20);
    r_vehicles all_vendor_vehicles%ROWTYPE;
BEGIN
    l_vehicles := get_vendor_vehicles(vendor_id);
    LOOP
        BEGIN
            FETCH l_vehicles INTO r_vehicles;
            EXIT WHEN l_vehicles%NOTFOUND;
            IF r_vehicles.availability_status = 1 THEN
                v_avail_status := 'Available';
            ELSE
                v_avail_status := 'Not Available';
            END IF;
            DBMS_OUTPUT.PUT_LINE(r_vehicles.id || ', ' || r_vehicles.car_name || ', ' || r_vehicles.passenger_capacity || ', ' || v_avail_status || ', ' || r_vehicles.category || ', ' || r_vehicles.fuel_type);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('No vehicles found.');
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
        END;
    END LOOP;
    CLOSE l_vehicles;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
/

-- Update existing cards as expired if not active
CREATE OR REPLACE TRIGGER trg_update_expired_pm
BEFORE INSERT OR UPDATE ON payment_methods
FOR EACH ROW
BEGIN
    IF :NEW.expiration_date < SYSDATE AND :NEW.active_status != 0 THEN
        :NEW.active_status := 0;
        DBMS_OUTPUT.PUT_LINE('payment_method ' || :NEW.card_number || ' updated status: expired by trigger.');
    END IF;
END;
/

-- Check validity of card number
CREATE OR REPLACE TRIGGER trg_check_card_number
BEFORE INSERT OR UPDATE ON payment_methods
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM cc_catalog
    WHERE card_number = :NEW.card_number;
    
    IF v_count = 0 THEN
        :NEW.active_status := 0;
        DBMS_OUTPUT.PUT_LINE('Invalid card: ' || :NEW.card_number);
        DBMS_OUTPUT.PUT_LINE('payment_method ' || :NEW.card_number || ' updated status: expired by trigger.');
    END IF;
END;
/
