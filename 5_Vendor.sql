alter session set current_schema=cr_app_admin;
set serveroutput on;

-- Add a car to the database
EXEC add_vehicle(30.00, 5000, 'true', 5, 'MIN123NE0W456OOP', 'New York', 'Bob', 'silverado');

-- Update the rate of a car
EXEC update_car_availability('BOS123NE0W456OOP', 'false');

-- Rental history
EXEC get_vendor_reservations_history(2);
EXEC get_vendor_reservations_history(4);

-- Get vendor vehicles
EXEC get_vendor_vehicle_list(2);
EXEC get_vendor_vehicle_list(4);