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

- Customer Loyalty History.csv   contiene datos de los miembros de la membresia (xxxx registros)
- Customer Flight Activity.csv   contiene resumen historico de los años 2017 y 2018 sobre cantidad de vuelos, millas acumuladas, canje de millas, etc, de los miembros de la membresia  (xxxx registros)

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

Se procede a crear las tablas en Bigquery sobre la capa bronze, utilizando la herramienta de creacion de tablas de Bigquery haciendo un upload de los archivos CSV.

![image](https://github.com/alucero1096/Airline-Loyalty-Program/assets/58011032/6a0e0f6d-75f6-4632-b96e-ea4fead6a711)

