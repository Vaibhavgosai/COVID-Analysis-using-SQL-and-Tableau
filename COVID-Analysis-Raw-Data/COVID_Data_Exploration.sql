--SELECT *
--FROM SQL_Portfolio..CovidDeaths
--ORDER BY 3,4

--SELECT *
--FROM SQL_Portfolio..CovidVaccinations
--ORDER BY 3,4

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM SQL_Portfolio..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 1,2

-- Total Cases vs Total Deaths
-- Query indicates the likelihood of dying if you contract COVID in the specified country  
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM SQL_Portfolio..CovidDeaths
WHERE location like '%Canada%'
ORDER BY 1,2


-- Total cases vs Population
-- Query to show the percentage of population who got COVID
SELECT Location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM SQL_Portfolio..CovidDeaths
WHERE location like '%Canada%'
ORDER BY 1,2


--Countries with highest infection rate
SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM SQL_Portfolio..CovidDeaths
--WHERE Location like '%Canada%'
GROUP BY Location, population
ORDER BY PercentPopulationInfected DESC


--Countries with the highest death count per population
SELECT Location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM SQL_Portfolio..CovidDeaths
WHERE continent is NOT NULL
-- cast command used to convert the datatype of total_deaths to int in the database.

GROUP BY Location
ORDER BY TotalDeathCount DESC


-- Breaking things down by Continents


-- Showing continents with the highest death count per population
SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM SQL_Portfolio..CovidDeaths
WHERE continent is NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC



-- Global numbers per day 

SELECT date, SUM(new_cases) as Total_Cases, SUM(cast(new_deaths as int)) as Total_Deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100  AS DeathPercentage
FROM SQL_Portfolio..CovidDeaths
--WHERE location like '%Canada%'
WHERE continent is not null
GROUP BY date
ORDER BY 1,2


-- Death percentage for total cases across the globe

SELECT SUM(new_cases) as Total_Cases, SUM(cast(new_deaths as int)) as Total_Deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100  AS DeathPercentage
FROM SQL_Portfolio..CovidDeaths
--WHERE location like '%Canada%'
WHERE continent is not null
ORDER BY 1,2



-- Looking at Total Population vs Vaccinations using JOIN

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS RollingPeopleVaccinated
FROM SQL_Portfolio..CovidDeaths dea
JOIN SQL_Portfolio..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
order by 2,3


--Using CTE to find vaccination percentage popvsvac

WITH PopvsVac(Continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS RollingPeopleVaccinated
FROM SQL_Portfolio..CovidDeaths dea
JOIN SQL_Portfolio..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac



-- Using Temp Table

DROP Table If exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS RollingPeopleVaccinated
FROM SQL_Portfolio..CovidDeaths dea
JOIN SQL_Portfolio..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
--WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated


-- Creating View for Tableau

CREATE VIEW PercentPopulationVaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
dea.date) AS RollingPeopleVaccinated
FROM SQL_Portfolio..CovidDeaths dea
JOIN SQL_Portfolio..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent IS NOT NULL