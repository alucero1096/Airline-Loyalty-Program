--Script DDL para la creacion de tablas en capa Silver
--Corresponde al proyecto Airline-Loyalty-Program
--Author: A.Lucero
--
CREATE TABLE `Loyalty_silver.DimLocations` AS
WITH temporal AS (
select distinct f.Country, f.Province, f.City, f.Postal_Code
from `Loyalty_bronze.loyalty-history` f
)
select ROW_NUMBER() OVER (ORDER BY f.Postal_Code) AS location_id, f.Country, f.Province, f.City, f.Postal_Code
from temporal f;

CREATE TABLE `Loyalty_silver.DimEducation` AS
select distinct SUBSTR(f.Education,1,1) education_id, f.Education
from `Loyalty_bronze.loyalty-history` f;


CREATE TABLE `Loyalty_silver.DimLoyaltyCard` AS
WITH temporal AS (
select distinct f.Loyalty_Card
from `Loyalty_bronze.loyalty-history` f
)
select ROW_NUMBER() OVER (ORDER BY t.Loyalty_Card) AS Card_id, t.Loyalty_Card
from temporal t;

CREATE TABLE `Loyalty_silver.DimCustomers` AS
select h.Loyalty_Number, l.location_id, h.Gender, e.education_id, h.Salary, h.Marital_Status, d.Card_id, h.CLV, 
CASE 
WHEN h.Enrollment_Type = 'Standard' THEN 'S'
WHEN h.Enrollment_Type = '2018 Promotion' THEN 'P'
END as tipo_enrollment, 
h.Enrollment_Year, h.Enrollment_Month, CAST(h.Enrollment_Year || '/' || h.Enrollment_Month || '/01' AS DATE FORMAT 'YYYY/MM/DD')  as fecha_enrollment,
CASE
WHEN h.Enrollment_Month IN (6,7,8) THEN 'Verano'
WHEN h.Enrollment_Month IN (9,10,11) THEN 'Otono'
WHEN h.Enrollment_Month IN (1,2,12) THEN 'Invierno'
WHEN h.Enrollment_Month IN (3,4,5) THEN 'Primavera'
END as estacion_enrollment,
h.Cancellation_Year, h.Cancellation_Month,
CAST(h.Cancellation_Year || '/' || h.Cancellation_Month || '/01' AS DATE FORMAT 'YYYY/MM/DD')  as fecha_cancelacion
from `Loyalty_bronze.loyalty-history` h
inner join `Loyalty_silver.DimLocations` l 
on h.Country = l.Country AND h.Province = l.Province AND h.City = l.City AND h.Postal_Code = l.Postal_Code 
inner join `Loyalty_silver.DimEducation` e
on e.Education = h.Education
inner join `Loyalty_silver.DimLoyaltyCard` d
on h.Loyalty_Card = d.Loyalty_Card;

CREATE TABLE `Loyalty_silver.FFlightActivity` AS
select f.Loyalty_Number, f.Year as period_year, f.Month as period_month,
CAST(f.Year || '/' || f.Month || '/01' AS DATE FORMAT 'YYYY/MM/DD')  as fecha_actividad,
 CASE
  WHEN f.Month IN (6,7,8) THEN 'Verano'
  WHEN f.Month IN (9,10,11) THEN 'Otoño'
  WHEN f.Month IN (1,2,12) THEN 'Invierno'
  WHEN f.Month IN (3,4,5) THEN 'Primavera'
  END as estacion_actividad,
f.Total_Flights, f.Distance, f.points_accumulated, f.Points_Redeemed, f.Dollar_Cost_Points_Redeemed as cost_points_redeemed
from `Loyalty_bronze.flight-activity` f;
