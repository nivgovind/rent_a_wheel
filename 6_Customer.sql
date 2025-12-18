alter session set current_schema=cr_app_admin;
set serveroutput on;

-- View: all available cars in said location (note: reduce location data)
SELECT * FROM view_all_available_cars;

-- - [ ] Procedure: Cancel a booking (should happen only if reservation isn't active yet)
EXEC cancel_reservation(1);
-- - [ ] Procedure: Add a payment method a payment method
EXEC add_payment_method('3000300030003002','true', '2024-01-31','186','1 kev St, New York, USA','Abigail');
EXEC add_payment_method('3000300030003004','true', '01-2024','186','1 kev St, New York, USA','Abigail');
EXEC add_payment_method('3111300030003004','true', '01-2024','186','1 kev St, New York, USA','Abigail');

-- - [ ] View payment methods
EXEC get_payment_methods('Abigail');
-- - [ ] View: rental history
EXEC get_user_reservations_history(1);
EXEC get_user_reservations_history(3);

-- - [ ] Procedure: Initiate a booking / Update a booking
-- Customer reservation flow
DECLARE
    v_pickup_location_name VARCHAR2(100) := 'Los Angeles';
    v_dropoff_location_name VARCHAR2(100) := 'New York';
    v_insurance_type_name VARCHAR2(100) := 'travel shield';
    v_user_name VARCHAR2(100) := 'Abigail';
    v_vehicle_registration_id VARCHAR2(100) := 'ARK678NEW7908OOP';
    v_pickup_date VARCHAR2(100) := '2024-05-11';
    v_dropoff_date VARCHAR2(100) := '2024-04-10';
    v_passenger_count NUMBER := 5;
    v_card_number VARCHAR2(100) := '1234567890123456';
    v_discount_code VARCHAR2(100) := 'WONDER10';
BEGIN
    booking_package.initiate_booking(
        pi_pickup_date => v_pickup_date,
        pi_dropoff_date => v_dropoff_date,
        pi_pickup_location_name => v_pickup_location_name,
        pi_dropoff_location_name => v_dropoff_location_name,
        pi_passenger_count => v_passenger_count,
        pi_vehicle_registration_id => v_vehicle_registration_id,
        pi_user_name => v_user_name,
        pi_insurance_type_name => v_insurance_type_name
    );

    booking_package.initiate_payment_transaction(
        pi_user_name => v_user_name,
        pi_vehicle_registration_id => v_vehicle_registration_id,
        pi_pick_up_date => v_pickup_date,
        pi_card_number => v_card_number,
        pi_discount_code => v_discount_code
    );

    booking_package.approve_transaction(
        pi_user_name => v_user_name,
        pi_vehicle_registration_id => v_vehicle_registration_id,
        pi_pick_up_date => v_pickup_date
    );
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
        ROLLBACK;
END;
