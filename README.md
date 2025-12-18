
# Covered use cases
### App
- [x] (trigger)Update expired reservations to cancelled
```
trg_update_expired_reservations
```
- [x] retrieve rental records for a user
```
EXEC get_user_completed_reservations(user_id IN NUMBER);
```


### Insurance analyst
- [x] Procedure: create insurance type
```
add_insurance_type (pi_name VARCHAR2, pi_coverage NUMBER)
```

- [x] Procedure: update existing insurance type
```
update_insurance_type (pi_insurance_type_name VARCHAR2, pi_new_coverage NUMBER);
```

- [x] View: insurance analytics (count of reservations for each and total revenue from each)
```
select * from view_insurance_res_rev;
```

- [x] View: Insurance analytics (top performing insurance type by vehicle type)
```
select * from view_insurance_top_performer;
```

### App analyst
- [x] View: No of rentals and revenue by vehicle type
```
select * from rentals_and_revenue_by_vehicle_type;
```
- [x] View: no of rentals and revenue by vendor
```
select * from rentals_revenue_by_vendor;
```
- [x] View: revenue by demographic (10 years age range)
```
select * from revenue_by_demographic;
```
- [x] View: revenue by user’s location
```
select * from revenue_by_location_view;
```
- [x] View: no of rentals by discount_type
```
select * from view_rentals_by_discount_type;
```
- [x] View: total booking last week
```
select * from view_total_booking_last_week;
```
### Customer
- [x] View: all available cars
```
select * from view_all_available_cars;
```
- [x] Package: Customer new reservation flow
    - [x] Procedure: Initiate a complete booking (reservation with successful payment)
    - [x] Procedure: initiate payment transactions
    - [x] Procedure: approve payment transactions
```
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
-- Procedure: initiate payment transactions
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
```
- [x] Procedure: Cancel a booking (should happen only if reservation isn't active yet)
```
EXEC cancel_reservation(RESERVATION_ID as number);
```
- [x] Procedure: Add a payment method
```
EXEC add_payment_method('3000300030003002','true', '2024-01-31','186','1 kev St, New York, USA','Abigail');
EXEC add_payment_method('3000300030003004','true', '01-2024','186','1 kev St, New York, USA','Abigail');
```
- [x] Procedure: View payment methods
```
EXEC get_payment_methods('Abigail');
```
- [x] View: rental history
```
-- history by a user
EXEC get_user_reservations_history(user_id as number);
```

### Vendor
- [x] Add a new car
```
EXEC add_vehicle(30.00, 5000, 'true', 5, 'MIN123NE0W456OOP', 'New York', 'Bob', 'silverado')
```
- [x] update availability
```
EXEC update_car_availability('BOS123NE0W456OOP', 'false');
```
- [x] View vendor cars
```
EXEC get_vendor_vehicle_list(2);
EXEC get_vendor_vehicle_list(4);
```
- [x] View rental history who has rented his cars 
```
EXEC get_vendor_reservations_history(2);
EXEC get_vendor_reservations_history(4);
```
