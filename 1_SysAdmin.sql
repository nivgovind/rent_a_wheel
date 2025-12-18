begin
    execute immediate 'drop user cr_app_admin cascade';
exception
    when others then
        if sqlcode!=-1918 then
            raise;
        end if;    
end;
/


-- Car rental application admin
create user cr_app_admin identified by "BlightPass#111";
grant connect, resource to cr_app_admin;
grant create session to cr_app_admin with admin option;
grant create table to cr_app_admin;
alter user cr_app_admin quota unlimited on data;
grant create view, create procedure, create sequence,create trigger to cr_app_admin;
grant create user to cr_app_admin;
grant drop user to cr_app_admin;
