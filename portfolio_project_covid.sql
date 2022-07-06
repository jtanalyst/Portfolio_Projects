/*
Covid 19 Data Exploration 
Skills used: Joins, Common table expressions (CTE's), Partition, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
Tables used have about 200,000 rows
*/

-- Viewing the tables
SELECT *
FROM Portfolio_project..covid_deaths
ORDER BY 3,4

SELECT *
FROM Portfolio_project..covid_vaccinations
ORDER BY 3,4

-- Changing the data types
ALTER TABLE covid_deaths
ALTER COLUMN total_cases float;

ALTER TABLE covid_deaths
ALTER COLUMN total_deaths float;

ALTER TABLE Portfolio_project..covid_deaths
ALTER COLUMN population float;

ALTER TABLE Portfolio_project..covid_deaths
ALTER COLUMN new_cases float;

ALTER TABLE Portfolio_project..covid_deaths
ALTER COLUMN new_deaths float;

ALTER TABLE Portfolio_project..covid_vaccinations
ALTER COLUMN new_vaccinations float;

SET ARITHABORT OFF 
SET ANSI_WARNINGS OFF

-- Case-Fatality Rate
-- Percentage of people with COVID who end up of dying from it by country and date
SELECT Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as case_fatality
FROM Portfolio_project..covid_deaths
ORDER BY 1,2;

-- Case-Fatality Risk in Canada
-- Percentage of people with COVID who end up of dying from it in Canada by date
SELECT Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as case_fatality
FROM Portfolio_project..covid_deaths
WHERE Location = 'Canada'
ORDER BY 2;

-- Total Cases vs Population in Canada
-- Shows percentage of population that have been infected by COVID
SELECT Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
FROM Portfolio_project..covid_deaths
WHERE Location = 'Canada'
ORDER BY 2;

-- Highest Infection Rate by Country (as of July 3rd, 2022)
-- Total cases over population
SELECT Location, Population, MAX(total_cases) as total_cases_july,  MAX((total_cases/ NULLIF(population,0)))*100 as PercentPopulationInfected
FROM Portfolio_project..covid_deaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected desc;

-- Highest Mortality Rate by Country (as of July 3rd, 2022)
SELECT Location, MAX(total_deaths) as total_deaths_july, MAX((total_deaths) / NULLIF(population, 0))*100 as mortality_rate
FROM Portfolio_project..covid_deaths
WHERE continent is not null 
GROUP BY Location
ORDER BY mortality_rate desc;

-- Global Mortality Rate
SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as mortality_percentage
FROM Portfolio_project..covid_deaths;
WHERE continent <> ''

-- New vaccinations by country from Feb 2, 2020 - July 3, 2022
-- rolling_people_vaccinated the total number vaccinations for a country by date
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations, 
SUM(vaccine.new_vaccinations) OVER (PARTITION BY death.Location Order by death.location, death.Date) as rolling_people_vaccinated
FROM Portfolio_project..covid_deaths death
JOIN Portfolio_project..covid_vaccinations vaccine
	ON death.location = vaccine.location
	and death.date = vaccine.date
WHERE death.continent <> ''
ORDER BY 2,3;

-- Performing the same calculation as above using CTE
With rolling_vac (Continent, Location, Date, Population, new_vaccinations, rolling_people_vaccinated)
as
(
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations, 
SUM(vaccine.new_vaccinations) OVER (PARTITION BY death.Location Order by death.location, death.Date) as rolling_people_vaccinated
FROM Portfolio_project..covid_deaths death
JOIN Portfolio_project..covid_vaccinations vaccine
	ON death.location = vaccine.location
	and death.date = vaccine.date
WHERE death.continent <> '' 
--ORDER BY 2,3
)
Select *
From rolling_vac;

-- Performing the same calculation as above using temp table
DROP TABLE if exists #rolling_vac
Create Table #rolling_vac
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
rolling_people_vaccinated numeric
)
INSERT INTO #rolling_vac
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations, 
SUM(vaccine.new_vaccinations) OVER (PARTITION BY death.Location Order by death.location, death.Date) as rolling_people_vaccinated
FROM Portfolio_project..covid_deaths death
JOIN Portfolio_project..covid_vaccinations vaccine
	ON death.location = vaccine.location
	and death.date = vaccine.date
WHERE death.continent <> ''

Select *
From #rolling_vac;

-- View to store data for later visualization 
CREATE VIEW rolling_vac as
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations, 
SUM(vaccine.new_vaccinations) OVER (PARTITION BY death.Location Order by death.location, death.Date) as rolling_people_vaccinated
FROM Portfolio_project..covid_deaths death
JOIN Portfolio_project..covid_vaccinations vaccine
	ON death.location = vaccine.location
	and death.date = vaccine.date
WHERE death.continent <> ''

