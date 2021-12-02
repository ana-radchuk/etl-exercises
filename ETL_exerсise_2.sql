/* ******************************************************************************************************************************
 * Scenario 2: Multivalued Relationships. Part 1
 *
 * Inputs:
 *   4 target tables:
 *     1) dim_technician (already prepolulated)
 *     2) dim_technician_group: table where each combination of people (each group) would have just one record
 *     3) bridge_technician_group: bridge table which would bound dim_technician with dim_technician_group
 *     4) fact_inspection with granularity of one record per inspection.
 *
 *   1 input table:
 *     1) staging fact-like table with inspections info. Each inspection(defined by inspection_id) is performed by a couple of employees
 *
 ****************************************************************************************************************************** */

------------------------------------------------------------------------------------------------------------------
-- Initialization (target tables)
------------------------------------------------------------------------------------------------------------------
drop table if exists dim_technician;
create table dim_technician(
    employee_sk serial primary key,
    employee_bk varchar(255),
    full_name  varchar(255)
);
truncate table dim_technician;
insert into dim_technician(employee_bk, full_name)
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

drop table if exists dim_technician_group;
create table dim_technician_group(
    employee_group_sk serial primary key,
    group_code varchar(1024)
);

drop table if exists bridge_technician_group;
create table bridge_technician_group(
    employee_group_sk int,
    employee_sk int
);

drop table if exists fact_inspection;
create table fact_inspection(
    inspection_id int not null primary key,
    employee_group_sk int
);

------------------------------------------------------------------------------------------------------------------
-- Initialization (source data)
------------------------------------------------------------------------------------------------------------------
drop table if exists stg_inspection;
create table stg_inspection(
  inspection_id int not null,
  employee_bk varchar(255) not null,
  primary key (inspection_id, employee_bk)
);
insert into stg_inspection values
(1,'uk100'),(1,'uk101'),(2,'uk100'),(2,'uk101'),(3,'uk100'),(3,'uk101'),(3,'uk102'),(4,'uk102'),
(4,'uk103'),(4,'uk104'),(5,'uk102'),(5,'uk103'),(6,'uk105'),(6,'uk106'),(6,'uk107'),(7,'uk107'),
(7,'uk105'),(7,'uk106'),(8,'uk106'),(8,'uk107'),(8,'uk105'),(9,'uk109'),(10,'uk109'),(10,'uk110'),
(11,'uk109'),(11,'uk110'),(11,'uk111'),(12,'uk108'),(12,'uk109'),(13,'uk107'),(13,'uk108'),
(14,'uk107'),(14,'uk108'),(15,'uk108'),(15,'uk107'),(16,'uk104'),(16,'uk105'),(16,'uk106'),
(17,'uk104'),(17,'uk105'),(17,'uk106'),(18,'uk104'),(18,'uk105'),(18,'uk106'),
(19,'uk103'),(19,'uk104'),(19,'uk105');

/* ******************************************************************************************************************************
 * Exercise #2 (initial population):
 * Prepare a SQL script (sequence of SQL statements) to populate the first time all the empty target tables:
 *   1) dim_technician_group;
 *   2) bridge_technician_group;
 *   3) fact_inspection;
 ****************************************************************************************************************************** */

 ------------------------------------------------------------------------------------------------------------------
 -- PostgreSQL
 ------------------------------------------------------------------------------------------------------------------
truncate table dim_technician_group;
insert into dim_technician_group(group_code)
select distinct string_agg(employee_bk, ',') employee_bk
from stg_inspection
group by inspection_id
order by employee_bk;

drop table if exists additional;
create table additional (
    id serial primary key,
    employee_group_sk int,
    employee_bk varchar(255)
);

insert into additional(employee_group_sk, employee_bk)
select employee_group_sk, unnest(string_to_array(group_code, ',')) AS employee_bk
from dim_technician_group;

truncate table bridge_technician_group;
insert into bridge_technician_group(employee_group_sk, employee_sk)
select additional.employee_group_sk, dim_technician.employee_sk
from additional, dim_technician
where additional.employee_bk = dim_technician.employee_bk;

drop table if exists additional2;
create table additional2 (
  employee_group_sk serial primary key,
  group_code varchar(1024)
);

truncate table additional2;
insert into additional2(group_code)
select string_agg(employee_bk, ',') employee_bk
from stg_inspection
group by inspection_id
order by employee_bk;

truncate table fact_inspection;
insert into fact_inspection(inspection_id, employee_group_sk)
select additional2.employee_group_sk as inspection_id, dim_technician_group.employee_group_sk
from additional2, dim_technician_group
where additional2.group_code = dim_technician_group.group_code;

select * from dim_technician_group;
select * from bridge_technician_group;
select * from fact_inspection;

/* ******************************************************************************************************************************
 * Scenario 3: Multivalued Relationships. Part 2
 *
 * Incremental data processing. After the initial data population the new portion of the source data has been arrived.
 * The requirements are to incrementally merge this data into the target tables.
 *
 ****************************************************************************************************************************** */

/* ******************************************************************************************************************************
-- New portion of the source data
****************************************************************************************************************************** */
insert into stg_inspection values
(21,'uk102'),(21,'uk103'),
(22,'uk107'),(22,'uk106'),(22,'uk105'),
(23,'uk103'),(23,'uk104'),(23,'uk105'),
(24,'uk100'),(24,'uk105'),
(25,'uk100'),(25,'uk103'),(25,'uk111'),
(26,'uk100'),(26,'uk105'),
(27,'uk100'),(27,'uk103'),(27,'uk111');

/* ******************************************************************************************************************************
 * Exercise #3 (incremental processing):
 * Prepare a SQL script (sequence of SQL statements) to merge the new portion of the data into the target table:
 *   1) dim_technician_group;
 *   2) bridge_technician_group;
 *   3) fact_inspection;
 ****************************************************************************************************************************** */
