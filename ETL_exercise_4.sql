/* ******************************************************************************************************************************
 * Scenario 4: Build a special bridge table for the organization structure (using Closure table approach)
 *
 * Inputs:
 *   2 target tables:
 *     1) dim_employee (already prepolulated)
 *     2) bridge_employee_hierachy table where hierarchical data should be populate according to Closure table approach
 *
 *   1 input table:
 *     1) stg_employee table where each record contains parent_id
 *
 ****************************************************************************************************************************** */

------------------------------------------------------------------------------------------------------------------
-- Initialization (target tables)
------------------------------------------------------------------------------------------------------------------
drop table if exists dim_employee;
create table dim_employee(
    employee_sk serial primary key,
    employee_bk varchar(255),
    full_name  varchar(255)
);
truncate table dim_employee;
insert into dim_employee(employee_bk, full_name)
values
('uk100', 'Lori Smith'),
('uk101', 'Ivan Kohut'),
('uk102', 'Oksana Lysytsia'),
('uk103', 'Iryna Vovk'),
('uk104', 'Mag Smith'),
('uk105', 'Ivanka Kohut'),
('uk106', 'Leyla Lysytsia'),
('uk107', 'Olesia Vovk'),
('uk108', 'John Smith'),
('uk109', 'Ivan Piven'),
('uk110', 'Oksana Baran'),
('uk111', 'Iryna Zayets');

drop table if exists bridge_employee_hierachy;
create table bridge_employee_hierachy(
    ancestor_employee_sk int not null,
    descendant_employee_sk int not null,
    depth_from_parent int,
    is_leave boolean,
    primary key (ancestor_employee_sk,descendant_employee_sk)
);

------------------------------------------------------------------------------------------------------------------
-- Initialization (target tables)
------------------------------------------------------------------------------------------------------------------
drop table if exists stg_employee;
create table stg_employee(
    employee_bk varchar(255) not null primary key,
    full_name  varchar(255),
    parent_bk varchar(255)
);

truncate table stg_employee;
insert into stg_employee(employee_bk, full_name, parent_bk)
values
('uk100', 'Lori Smith',null),
('uk101', 'Ivan Kohut','uk100'),
('uk102', 'Oksana Lysytsia','uk100'),
('uk103', 'Iryna Vovk','uk101'),
('uk104', 'Mag Smith','uk101'),
('uk105', 'Ivanka Kohut','uk102'),
('uk106', 'Leyla Lysytsia','uk102'),
('uk107', 'Olesia Vovk','uk104'),
('uk108', 'John Smith','uk104'),
('uk109', 'Ivan Piven','uk107'),
('uk110', 'Oksana Baran','uk108'),
('uk111', 'Iryna Zayets','uk109');


/* ******************************************************************************************************************************
 * Exercize #4 (build hierarchy bridge table):
 * Prepare a SQL script (sequence of SQL statements) to build the bridge_employee_hierachy table according to closure table algorithm
 ****************************************************************************************************************************** */
 drop table if exists employee;
 create table employee(
     employee_sk serial primary key,
     employee_bk varchar(255),
     full_name varchar(255),
     parent_bk varchar(255)
 );

truncate table employee;
insert into employee(employee_sk, employee_bk, full_name, parent_bk)
select dim_employee.employee_sk, dim_employee.employee_bk, dim_employee.full_name, parent_bk
from dim_employee
join stg_employee on dim_employee.employee_bk = stg_employee.employee_bk;

drop table if exists employee_updated;
create table employee_updated(
    employee_sk serial primary key,
    employee_bk varchar(255),
    full_name varchar(255),
    parent_bk varchar(255),
    parent_sk int
);

truncate table employee_updated;
insert into employee_updated(employee_sk, employee_bk, full_name, parent_bk, parent_sk)
select employee.employee_sk, employee.employee_bk, employee.full_name, employee.parent_bk, dim_employee.employee_sk
from employee
left join dim_employee on employee.parent_bk = dim_employee.employee_bk
order by employee.employee_sk;

with recursive empdata as (
  (select employee_sk, employee_bk, full_name, parent_bk, parent_sk, 0 as depth_from_parent
  from employee_updated
  where employee_sk = 1)
  union all
  (select this.employee_sk, this.employee_bk, this.full_name, this.parent_bk, this.parent_sk, prior.depth_from_parent + 1
  from empdata as prior
  inner join employee_updated as this ON this.parent_bk = prior.employee_bk)
)
select e.employee_sk, e.employee_bk, e.full_name, e.parent_sk, e.depth_from_parent
from empdata as e
order by e.employee_sk;
