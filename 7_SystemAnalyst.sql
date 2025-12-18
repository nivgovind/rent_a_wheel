alter session set current_schema=cr_app_admin;
set serveroutput on;

-- View: Analytics rental frequency and revenue by vehicle type
select * from rentals_and_revenue_by_vehicle_type;

-- View: no of rentals and revenue by vendor
select * from rentals_revenue_by_vendor;

-- View: revenue by demographic (10 years age range)
select * from revenue_by_demographic;

-- View: revenue by user’s location
select * from revenue_by_location_view;

-- View: no of rentals by discount_type
select * from view_rentals_by_discount_type;

-- View: total booking last week
select * from view_total_booking_last_week;

-- view: all rental history
select * from view_all_rental_history;
