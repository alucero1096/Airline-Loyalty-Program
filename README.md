# Analisis de Campaña de promocion de un Programa de Membresia

Proyecto de Data Analysis end-to-end, que incluye ETL, modelado de datos y visualizacion en Power BI

## Caso de analisis

Norther Light Airlines (NLA) es una aerolinea ficticia que realiza vuelos locales en Canada. Continuando con su objetivo por mantenerse entre las aerolineas lideres de la region, NLA realizo una campaña de promocion sobre su Programa de Membresia, destinada a impulsar la inscripción de nuevos miembros, que se extendio entre Febrero y Abril de 2018. La compañia recaudo datos y ahora busca conocer el impacto que genero la campaña.

## Preguntas del negocio

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
- Conclusiones del analisis
- Oportunidades de mejora

-----

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

-----

### Organizacion de los datos

La idea en el proyecto es estructurar los datos bajo una arquitectura Medallion (capas Bronze, Silver y Gold), como se represente en el sgte esquema:

<<<<<<<<<<<<<   Insertar aca  grafico del esquema Bronze-Silver-Gold    >>>>>>>>>>>>>>>>>>>>>>>>>>

Con tal fin, se crean en BigQuery los respectivos datasets  _Loyalty-bronze_ y _Loyalty_silver_ para contener las tablas en sus respectivas capas.

-----

### Carga de datos

Se procede a crear las tablas en Bigquery sobre la capa Bronze, utilizando la herramienta de creacion de tablas de Bigquery haciendo un upload de los archivos CSV.

![Tabla flight-activity cargada en dataset bronze](https://github.com/alucero1096/Airline-Loyalty-Program/blob/main/assets/screenshots/flight-activity-bronze.png "Tabla flight-activity cargada en dataset bronze")

![Tabla loyalty-history cargada en dataset bronze](https://github.com/alucero1096/Airline-Loyalty-Program/blob/main/assets/screenshots/loyalty-history-bronze.png "Tabla loyalty-history cargada en dataset bronze")

-----

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

-----

### Modelado en Power BI

Primero se procede a realizar la conexion desde Power BI para que tome las tablas residentes en capa Silver de Bigquery.

![ ](https://github.com/alucero1096/Airline-Loyalty-Program/blob/main/assets/screenshots/PBI-load-data-from-bigquery.png "Conexion y Carga de datos en PBI")

Se genera una dimension Calendario _DimCalendar_ utilizando DAX, y se le agregan columnas de Año, Mes y Cuatrimeste:

```DAX
DimCalendar = CALENDAR(MIN(DimCustomers[fecha_enrollment]),MAX(DimCustomers[fecha_enrollment]))
Año = YEAR(DimCalendar[Date])
Mes = MONTH(DimCalendar[Date])
Trimestre = CONCATENATE("Q",QUARTER(DimCalendar[Date]))
```

Sobre la dimension _DimCustomers_ se crea el campo _Antiguedad_ mediante DAX:

```DAX
Antiguedad = DATEDIFF(DimCustomers[fecha_enrollment],IF(DimCustomers[fecha_cancelacion] = BLANK(),TODAY(),DimCustomers[fecha_cancelacion]),MONTH)
```

Luego se procede a la creacion de las relaciones entre tablas, resultando de la sgte forma:

![ ](https://github.com/alucero1096/Airline-Loyalty-Program/blob/main/assets/screenshots/PBI-manage-relationships.png "Creacion de relaciones entre tablas")


Resultando de esta manera el DER que constituye la capa Gold del modelo, como se muestra a continuacion:

![ ](https://github.com/alucero1096/Airline-Loyalty-Program/blob/main/assets/screenshots/DER-capa-gold.png "DER capa Gold en PBI")

-----

### Generacion de Metricas

Se parte de la generacion del [Plan de Metricas](https://github.com/alucero1096/Airline-Loyalty-Program/blob/main/assets/Loyalty_PlandeMetricas.xlsx), a partir del cual se crearan las correspondientes metricas en PowerBI

Como buena practica, se genero la tabla _Metricas_ para centralizar el repositorio de metricas, y se organizaron en carpetas, como se muestra ejemplo a continuacion:

![ ](https://github.com/alucero1096/Airline-Loyalty-Program/blob/main/assets/screenshots/PBI-metricas.png "Algunas metricas creadas para el reporte")


A modo de ejemplos, se detallan algunas metricas creadas para el reporte:

_Metrica para el calculo de nuevos miembros de la membresia_
```dax
QAltaPromo = 
CALCULATE(
    [QMiembros],
    DimCustomers[Enrollment_Year] <> BLANK(),
    DimCustomers[tipo_enrollment] = "P"
)
```

_Metrica para el calculo de bajas en la membresia durante el periodo de la campaña_
```dax
QBajasPromo = 
CALCULATE(
    [QMiembros],
    USERELATIONSHIP(DimCustomers[fecha_cancelacion],DimCalendar[Date]),
    DimCustomers[Cancellation_Year] = 2018,
    DimCustomers[Cancellation_Month] IN {2,3,4}
)
```

_Metrica para calcular acumulado mensual del Neto de miembros en el periodo_
```dax
QNeto_Accum = 
VAR _Fecha_Maxima = CALCULATE( MAX(DimCustomers[fecha_enrollment]), ALLSELECTED(DimCalendar[Date]) )
VAR _nueva = EOMONTH( _Fecha_Maxima, 0 )
VAR _Fecha_Inicio = DATE(YEAR(2012), 1, 1)
VAR _Valor =
CALCULATE( [QNeto]
    , FILTER( ALL(DimCalendar[Date])
        , DimCalendar[Date] >= _Fecha_Inicio && DimCalendar[Date] <= _nueva )
)

RETURN
_Valor
```

_Metrica para calcular relacion porcentual entre Total facturado año 2018 y Total facturado año 2017_
```dax
%YoY TotalCLV = 
VAR _up_arrow = UNICHAR(129137)
VAR _down_arrow = UNICHAR(129139)
VAR _porcentaje = ROUND(
    DIVIDE(
        [TotalCLV_LastYear] - [TotalCLV_PrevY], [TotalCLV_PrevY], 0
        ) * 100,
1)
RETURN 
IF (_porcentaje < 0,
ABS(_porcentaje) & "% " & _down_arrow,
 _porcentaje & "% " & _up_arrow)
```

_Metrica para el calculo de suma total de vuelos en un periodo_
```dax
QVuelos = 
CALCULATE(
    [TotalVuelos],
    USERELATIONSHIP(FFlightActivity[fecha_actividad],DimCalendar[Date])
)
```

_Metrica para calculo de suma total de puntos canjeados durante el periodo de la campaña_
```dax
sumPuntosRedeem = CALCULATE(
    [TotalPuntosRedeemed],
    DimCustomers[tipo_enrollment] = "P",
    USERELATIONSHIP(FFlightActivity[fecha_actividad],DimCalendar[Date])
)
```
-----

### Elaboracion del Reporte en PowerBI

El reporte se estructuro en 5 paginas, 1 como portada, y el resto para responder a las preguntas del negocio

| Pagina | Descripcion  |
| --- | --- |
| Inicio | Portada |
| Membresia | Altas en campaña, Historico Membresia, Comparativo de altas en campaña vs periodos anteriores |
| Retencion | Bajas en campaña, Historico de bajas, Comparativo bajas en 2018 vs 2017, Ratio de Retencion de miembros |
| Demografia | Visualizaciones de Altas segun genero, estado civil, tipo membresia, nivel educativo, ubicacion geografica |
| Impacto | Ratio de contribucion de la campaña en las reservas de vuelos, facturado total, canje de puntos |

Se diseño en Figma el background utilizado en cada pagina

Para la navegacion entre paginas se utilizaron botones con acciones para direccionar a las paginas correspondientes.

Se utilizaron iconos de uso libre de la pagina [Flaticon](https://www.flaticon.com/)


![ ](https://github.com/alucero1096/Airline-Loyalty-Program/blob/main/assets/screenshots/PBI-pagina-impacto.png "Reporte - Pagina Impacto")

En general se utilizaron las visualizaciones que provee por defecto PowerBI, salvo la visualizacion Tornado que se importo en la herramienta para visualizar el contraste de altas y bajas en los periodos Año.

![ ](https://github.com/alucero1096/Airline-Loyalty-Program/blob/main/assets/screenshots/PBI-tornado-viz.png "Visualizacion Tornado")

#### Hack sobre las visualizaciones Tarjetas

En algunas visualizaciones de tipo Tarjeta, se utilizo la opcion de agregar etiquetas de referencia para contrastar valores y mostrar diferencia porcentual destacada por formato con colores rojo/verde segun valor porcentaje.

![ ](https://github.com/alucero1096/Airline-Loyalty-Program/blob/main/assets/screenshots/PBI-tarjeta-viz.png "Viz tipo Tarjeta")

En este caso, para la tarjeta que se muestra arriba, la proporcion porcentual se calculo definiendo la metrica que se muestra a continuacion, que retorna un texto con el valor del porcentaje y el caracter ↑ ó ↓ segun corresponda si la proporcion es positiva o negativa, 

```dax
%YoY_QVuelos = 
VAR _up_arrow = UNICHAR(129137)
VAR _down_arrow = UNICHAR(129139)
VAR _porcentaje = ROUND(
    DIVIDE(
        [QVuelos_2018] - [QVuelos_2017], [QVuelos_2017], 0
        ) * 100,
1)
RETURN 
IF (_porcentaje < 0,
ABS(_porcentaje) & "% " & _down_arrow,
 _porcentaje & "% " & _up_arrow)
```

Y para dar formato de color a los valores, tambien se definio la metrica a continuacion y se aplico como formato condicional

```dax
%Color_QVuelos = 
VAR _porcentaje = ROUND(
    DIVIDE(
        [QVuelos_2018] - [QVuelos_2017], [QVuelos_2017], 0
        ) * 100,
1)
RETURN 
IF (_porcentaje < 0, "red", "green")
```

-----

### Conclusiones del analisis

A continuacion se describen conclusiones del analisis para responder a los preguntas del negocio.


_1. La campaña de promocion, ¿fue exitosa?_

Se puede concluir que fue exitosa en este sentido:
El historico de altas en la membresia, muestra claramente el pico de altas en el periodo de la campaña (Feb-Abr-2018). 
Ademas el promedio mensual de altas antes de la campaña era de 190 altas/mes, y durante la campaña subio un 69.8% , y post campaña se sostuvo en 250 altas/mes.

![ ](https://github.com/alucero1096/Airline-Loyalty-Program/blob/main/assets/screenshots/PBI-historico-altas.png "Historico de Altas")


_2. ¿Que impacto genero la campaña sobre el Programa de Membresia?_

En el comparativo de altas 2018 vs 2017 se observa mes a mes que durante 2018 las altas fueron superiores al 2017

![ ](https://github.com/alucero1096/Airline-Loyalty-Program/blob/main/assets/screenshots/PBI-altas-2018vs2017.png "YoY Altas 2018vs2017")

La contribucion de la campaña al incremento de reserva de vuelos fue positiva. La cantidad de reservas de vuelos en 2018 se incremento un 27.9%

![ ](https://github.com/alucero1096/Airline-Loyalty-Program/blob/main/assets/screenshots/PBI-reserva-vuelos.png "Contribucion en reserva de vuelos")

El total facturado por reservas se incremento un 24.8% respecto del 2017

Tambien se observaron incrementos en el acumulado de millas y en el canje de puntos 

![ ](https://github.com/alucero1096/Airline-Loyalty-Program/blob/main/assets/screenshots/PBI-puntos-y-canje.png "Puntos Acumulados y Canje")

_3. ¿La campaña resonó más entre ciertos grupos demográficos?_

Nivel Educativo: entre los nuevos miembros, el 65% posee titulo de grado, con lo que se podria asumir que se tratan de adultos trabajadores, siende este un target importante para NLA ya que presentarian un flujo ingresos constante y "hambre" por los viajes.

![ ](https://github.com/alucero1096/Airline-Loyalty-Program/blob/main/assets/screenshots/PBI-education.png "Nivel Educativo nuevos miembros")

Estado Civil:  mas del 57% de los nuevos miembros incorporados durante la campaña son Casados, esto puede presumir reserva de vuelos en pareja (o mas si cuentan con hijos), dato importante tambien para alguna campaña de marketing orientada a este grupo.

![ ](https://github.com/alucero1096/Airline-Loyalty-Program/blob/main/assets/screenshots/PBI-estado-civil.png "Estado Civil nuevos miembros")

Ubicacion: Ontario, Quebec y British Columbia presentan los lugares con mayores incorporaciones a la membresia. 

_4. ¿Cuál es la temporada más popular para que viajen los nuevos miembros?_

-----

### Oportunidades de mejora

- Se podrian suponer algunos targets que el negocio quisiera alcanzar con la campaña de promocion (por ejemplo #esperado de nuevos miembros) para mostrarlos como KPIs
- A nivel demografia de los miembros, realizar analisis por salarios (por ejemplo definiendo grupos por nivel de ingresos)
- 



