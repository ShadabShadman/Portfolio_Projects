Select *
From PortfolioProject..covid_deaths
-- Where continent is not null
Order By 3, 4

--Select *
--From PortfolioProject..covid_vaccinations
--Order By 3, 4

-- Select Data that we will use

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..covid_deaths
Order By 1, 2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage 
From PortfolioProject..covid_deaths
Where location like '%Canada%'
Order By 1, 2

-- Looking at Total Cases vs Population
-- Shows what percentage of population got covid

Select location, date, population,total_cases, (total_cases/population)*100 as percent_pop_infected 
From PortfolioProject..covid_deaths
-- Where location like '%Canada%'
Order By 1, 2

-- Looking at Countries with highest infection rate compared to population

Select location, population,MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as 
	percent_pop_infected
From PortfolioProject..covid_deaths
-- Where location like '%Canada%'
Group By location, population
Order By percent_pop_infected DESC

-- Showing Countries with highest death count per population
-- cast because total_deaths is a nvarchar255 and doesn't work for aggregate functions well
Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..covid_deaths
-- Where location like '%Canada%'
Where continent is not null
Group By location
Order By TotalDeathCount DESC

-- Break things down by continent

-- Showing continents with highest death rate count per population

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProject..covid_deaths
-- Where location like '%Canada%'
Where continent is not null
Group By continent
Order By TotalDeathCount DESC


-- Global numbers

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_percentage 
From PortfolioProject..covid_deaths
-- Where location like '%Canada%'
Where continent is not null
-- Group By date
Order By 1, 2


-- Looking at Total Population vs Vaccinations
-- using partition by for a cumulative sum

Select death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
	SUM(cast(vacc.new_vaccinations as int)) Over (Partition By death.location Order By death.location,
	death.date) as CumulatedPeopleVaccinated
	-- (CumulatedPeopleVaccinated/population)*100
From PortfolioProject..covid_deaths death
Join PortfolioProject..covid_vaccinations vacc
	On death.location = vacc.location
	and death.date = vacc.date
Where death.continent is not null
Order By 2, 3

-- Use CTE

With PopvsVacc (continent, location, date, population, new_vaccinations, CumulatedPeopleVaccinated)
as
(
Select death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
	SUM(cast(vacc.new_vaccinations as int)) Over (Partition By death.location Order By death.location,
	death.date) as CumulatedPeopleVaccinated
	-- (CumulatedPeopleVaccinated/population)*100
From PortfolioProject..covid_deaths death
Join PortfolioProject..covid_vaccinations vacc
	On death.location = vacc.location
	and death.date = vacc.date
Where death.continent is not null
-- Order By 2, 3
)
Select *, (CumulatedPeopleVaccinated/population)*100
From PopvsVacc


-- Use TEMP TABLE

Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
CumulativePeopleVaccinated numeric
)

Insert Into #PercentPopulationVaccinated
Select death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
	SUM(cast(vacc.new_vaccinations as int)) Over (Partition By death.location Order By death.location,
	death.date) as CumulatedPeopleVaccinated
	-- (CumulatedPeopleVaccinated/population)*100
From PortfolioProject..covid_deaths death
Join PortfolioProject..covid_vaccinations vacc
	On death.location = vacc.location
	and death.date = vacc.date
Where death.continent is not null
-- Order By 2, 3

Select *, (CumulativePeopleVaccinated/population)*100 as Cumulative_vacc_percent
From #PercentPopulationVaccinated
Order By location, date


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
	SUM(cast(vacc.new_vaccinations as int)) Over (Partition By death.location Order By death.location,
	death.date) as CumulatedPeopleVaccinated
	-- (CumulatedPeopleVaccinated/population)*100
From PortfolioProject..covid_deaths death
Join PortfolioProject..covid_vaccinations vacc
	On death.location = vacc.location
	and death.date = vacc.date
Where death.continent is not null
--Order By 2, 3