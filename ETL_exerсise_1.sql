/* ******************************************************************************************************************************
 *
 * Scenario 1: SCD1 and SCD2 incremental data processing
 *
 ****************************************************************************************************************************** */

------------------------------------------------------------------------------------------------------------------
-- Initialization
------------------------------------------------------------------------------------------------------------------
drop table if exists dim_customer;
create table dim_customer(
    customer_sk serial primary key,
    customer_bk varchar(255),
    full_name  varchar(255),   -- SCD1 attribute
    country varchar(255),      -- SCD2 attribute
    state_region varchar(255), -- SCD2 attribute
    valid_from timestamp,
    valid_to timestamp
);
truncate table dim_customer;
insert into dim_customer(customer_bk, full_name, country, state_region, valid_from, valid_to)
values
('us101', 'Lori Smith', 'US', 'Texas', '1900-01-01','9999-12-31 23:59:59'),
('uk101', 'Ivan Kohut', 'Ukraine', 'Lviv', '1900-01-01','2020-10-31 23:59:59'),
('uk101', 'Ivan Kohut', 'Ukraine', 'Kyiv', '2020-11-01','9999-12-31 23:59:59'),
('uk102', 'Oksana Lysytsia', 'Ukraine', 'Ternopil', '1900-01-01','9999-12-31 23:59:59'),
('uk103', 'Iryna Vovk', 'Ukraine', 'Ivano-Frankivsk', '1900-01-01','9999-12-31 23:59:59');


drop table if exists stg_customer;
create table stg_customer(
    customer_bk varchar(255) primary key,
    full_name  varchar(255),
    country varchar(255),
    state_region varchar(255)
);
truncate table stg_customer;
insert into stg_customer(customer_bk, full_name, country, state_region)
values
('us101', 'Lorelei Smith', 'US', 'Texas'),
('us102', 'Chris Black', 'US', 'California'),
('uk101', 'Ivan Kohut-Baran', 'Ukraine', 'Irpin'),
('uk102', 'Oksana Lysytsia-Vovk', 'Ukraine', 'Ternopil'),
('uk103', 'Iryna Vovk', 'Ukraine', 'Ivano-Frankivsk');


/* ******************************************************************************************************************************
 * Exercise #1:
 * Prepare a SQL script (sequence of SQL statements) to implement the merging of the stg_customer (increment of the customer data)
 * into the target dim_customer dimension table
 ****************************************************************************************************************************** */

 ------------------------------------------------------------------------------------------------------------------
 -- PostgreSQL
 ------------------------------------------------------------------------------------------------------------------
update dim_customer
  set full_name =
  case
    when (dim_customer.country is not distinct from stg.country and dim_customer.state_region is not distinct from stg.state_region) then stg.full_name
    else dim_customer.full_name
  end,
  valid_from =
  case
    when (dim_customer.country is not distinct from stg.country and dim_customer.state_region is not distinct from stg.state_region) then current_timestamp(0)
    else dim_customer.valid_from
  end
from stg_customer stg
where dim_customer.customer_bk = stg.customer_bk;

insert into dim_customer (customer_bk, full_name, country, state_region)
select customer_bk, full_name, country, state_region customer_bk from stg_customer
union
select customer_bk, full_name, country, state_region from stg_customer
except
select customer_bk, full_name, country, state_region from dim_customer;

update dim_customer
  set valid_from = current_timestamp(0),
  valid_to = '9999-12-31 23:59:59'
  where (valid_from is null and valid_to is null);

select * from dim_customer;
