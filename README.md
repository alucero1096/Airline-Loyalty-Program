# Analisis de Campaña de promocion de un Programa de Membresia

Proyecto de Data Analysis end-to-end, que incluye ETL, modelado de datos y visualizacion en Power BI

## Caso de analisis

Norther Light Airlines (NLA) es una aerolinea ficticia que realiza vuelos locales en Canada. Continuando con su objetivo por mantenerse entre las aerolineas lideres de la region, NLA realizo una campaña de promocion sobre su Programa de Membresia, destinada a impulsar la inscripción de nuevos miembros, que se extendio entre Febrero y Abril de 2018. La compañia recaudo datos y ahora busca conocer el impacto que genero la campaña.

## Objetivos de negocio

1. La campaña de promocion, ¿fue exitosa?

2. ¿Que impacto genero la campaña sobre el Programa de Membresia?

3. ¿La campaña resonó más entre ciertos grupos demográficos?

4. ¿Cuál es la temporada más popular para que viajen los nuevos miembros?

## Objetivos del proyecto

- Descripcion del dataset con los datos de origen
- Carga de datos en capa bronze
- ETL en capa silver
- DER Modelado para usar en Power BI
- Generar plan de metricas
- Elaborar reporte en Power BI para responder los objetivos de negocio
- Conclusiones
- Oportunidades

## Desarrollo del proyecto

### Sobre el dataset

El dataset fue tomado del repo de [Maven Analytics](https://www.mavenanalytics.io/data-playground) e incluye 2 archivos CSV

- Customer Loyalty History.csv   contiene datos de los miembros de la membresia (16,737 registros)
- Customer Flight Activity.csv   contiene resumen historico de los años 2017 y 2018 sobre cantidad de vuelos, millas acumuladas, canje de millas, etc, de los miembros de la membresia  (392,936 registros)

| Tabla | Campo | Descripcion  |
| --- | --- | --- |
| Customer Loyalty History | Loyalty Number | ID del miembro en la membresia |
|     | Country | Pais de residencia del miembro |
|     | Province | Provincia de residencia del miembro |
|     | City | Ciudad de residencia del miembro |
|     | Postal Code | Codigo Postal de residencia |
|     | Gender | Sexo |
|     | Education | Nivel Educativo |
|     | Salary | Ingreso anual |
|     | Marital Status | Estado civil |
|     | Loyalty Card | Tipo de membresia (Star > Nova > Aurora) |
|     | CLV | Customer lifetime value - Total Facturado por las reservas realizadas por el miembro |
|     | Enrollment Type | Indica si miembro se enrolo por la promocion o no |
|     | Enrollment Month | Mes de enrolamiento |
|     | Enrollment Year | Año de enrolamiento |
|     | Cancellation Year | Año de baja en la membresia |
|     | Cancellation Month | Mes de baja en la membresia |
| Customer Flight Activity | Loyalty Number | ID del miembro en la membresia |
|     | Year | Año del periodo  |
|     | Month | Mes del periodo  |
|     | Total Flights | Total de vuelos reservados (tickets comprados) en el periodo |
|     | Distance | Suma total de las distancias recorridas por los vuelos (km) |
|     | Points Accumulated | Puntos acumulados en el periodo |
|     | Points Redeemed | Puntos canjeados en el periodo |
|     | Dollar Cost Points Redeemed | Valor en dolares equivalente a los puntos canjeados en el periodo |

### Organizacion de los datos

La idea en el proyecto es estructurar los datos bajo una arquitectura Medallion (capas Bronze, Silver y Gold), como se represente en el sgte esquema:

<<<<<<<<<<<<<   Insertar aca  grafico del esquema Bronze-Silver-Gold    >>>>>>>>>>>>>>>>>>>>>>>>>>

Con tal fin, se crean en BigQuery los respectivos datasets  _Loyalty-bronze_ y _Loyalty_silver_ para contener las tablas en sus respectivas capas.

### Carga de datos

Se procede a crear las tablas en Bigquery sobre la capa Bronze, utilizando la herramienta de creacion de tablas de Bigquery haciendo un upload de los archivos CSV.

![Tabla flight-activity cargada en dataset bronze](https://github.com/alucero1096/Airline-Loyalty-Program/blob/main/assets/screenshots/flight-activity-bronze.png "Tabla flight-activity cargada en dataset bronze")

![Tabla loyalty-history cargada en dataset bronze](https://github.com/alucero1096/Airline-Loyalty-Program/blob/main/assets/screenshots/loyalty-history-bronze.png "Tabla loyalty-history cargada en dataset bronze")

### ETL en capa Silver

Luego se procede a la generacion de las tablas en la capa Silver, para lo cual se generaron sentencias DDL. Para detalles referirse al [script de creacion de tablas en Silver](https://github.com/alucero1096/Airline-Loyalty-Program/blob/main/assets/create_tables_silver.sql)

```sql
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
```

Con esta estructura de tablas se procede a generar lo que seria el DER preliminar:

![ ](https://github.com/alucero1096/Airline-Loyalty-Program/blob/main/assets/screenshots/DER-capa-silver.png "DER en capa Silver")

### Modelado en Power BI

Primero se procede a realizar la conexion desde Power BI para que tome las tablas residentes en capa Silver de Bigquery.

![ ](https://github.com/alucero1096/Airline-Loyalty-Program/blob/main/assets/screenshots/PBI-load-data-from-bigquery.png "Conexion y Carga de datos en PBI")

