-- Drop and recreate application admin user for car-rental platform (v3 logical model)
begin
   execute immediate 'drop user cr_app_admin cascade';
exception
   when others then
      if sqlcode != -1918 then
         raise;
      end if;
end;
/


-- Car rental application admin
-- Car rental application admin (owns core OLTP schemas)
create user cr_app_admin identified by "my_password";

-- Grant necessary privileges to the application admin user
grant connect,resource to cr_app_admin;

grant create session to cr_app_admin with admin option;
grant create table to cr_app_admin;
alter user cr_app_admin
   quota unlimited on data;
grant create view,
   create procedure,
   create sequence,
   create trigger,
   create type,
   create synonym
to cr_app_admin;

-- Tablespace quota (adjust TABLESPACE name if you use a named one)
alter user cr_app_admin
   quota unlimited on data;

-- Allow schema-level DDL for dev/demo (NOT for production)
-- grant unlimited tablespace to cr_app_admin;

grant create user to cr_app_admin;
grant drop user to cr_app_admin;