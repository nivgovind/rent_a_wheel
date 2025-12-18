-- Start all files with exception handling
-- Users and roles
-- Not use the default admin

SET SERVEROUTPUT ON;

begin
    execute immediate 'drop user customer cascade';
    execute immediate 'drop user vendor cascade';
    execute immediate 'drop user insurance_agent cascade';
    execute immediate 'drop user system_analyst cascade';
exception
    when others then
        if sqlcode!=-1918 then
            raise;
        end if;    
end;
/

-- Customer
create user customer identified by "BlightPass#111";
grant create session to customer;
grant execute on booking_package to customer;
grant execute on cancel_reservation to customer;
grant execute on add_payment_method to customer;
grant execute on get_payment_methods to customer;
grant execute on get_user_reservations_history to customer;
GRANT SELECT ON view_all_available_cars to customer;


-- Vendor
create user vendor identified by "BlightPass#111";
grant create session to vendor;
GRANT EXECUTE ON add_vehicle TO vendor;
GRANT EXECUTE ON update_car_availability TO vendor;
GRANT EXECUTE ON get_vendor_reservations_history TO vendor;
GRANT EXECUTE ON get_vendor_vehicle_list TO vendor;

-- Insurance Agent
create user insurance_agent identified by "BlightPass#111";
grant create session to insurance_agent;
GRANT EXECUTE ON add_insurance_type TO insurance_agent;
GRANT EXECUTE ON update_insurance_type TO insurance_agent;
GRANT SELECT ON view_insurance_res_rev TO insurance_agent;
GRANT SELECT ON view_insurance_top_performer TO insurance_agent;


-- Analyst
create user system_analyst identified by "BlightPass#111";
grant create session to system_analyst;
GRANT SELECT ON rentals_and_revenue_by_vehicle_type TO system_analyst;
GRANT SELECT ON rentals_revenue_by_vendor TO system_analyst;
GRANT SELECT ON revenue_by_demographic TO system_analyst;
GRANT SELECT ON revenue_by_location_view TO system_analyst;
GRANT SELECT ON view_rentals_by_discount_type TO system_analyst;
GRANT SELECT ON view_total_booking_last_week TO system_analyst;
GRANT SELECT ON view_all_rental_history TO system_analyst;
