-- Covid data for all countries from early 2020 to end of april 2021


-- sanity check

SELECT *
FROM coviddeaths
where continent is null
ORDER BY 3 , 4;

SELECT *
FROM covidVaccinations
where continent is not null
ORDER BY 3 , 4;

-- Data in chronological order 
select location,str_to_date(date, '%d/%m/%Y'),total_cases,new_cases,total_deaths,population
from coviddeaths
where continent is not null
ORDER BY 1 , 2;

-- Looking at total cases vs total deaths
-- shows likelihood of dying contracting Covid in respective country
select location,date,total_cases,total_deaths,((total_deaths/total_cases)*100) as percentage_deaths_per_case
from coviddeaths
where location like '%kingdom%' and
continent is not null
ORDER BY 1 , year(2) asc;

-- looking at total cases vs population
-- shows percentage of population got covid in respective country

select location,date,total_cases,population,((total_cases/population)*100) as case_per_person
from coviddeaths
where location like '%kingdom%' and 
continent is not null
ORDER BY 1 , year(2) asc;

-- countries with highest infection rates compared to population

select location,max(total_cases) as highest_infection_count,population,max((total_cases/population)*100) as population_infected
from coviddeaths
where continent is not null
group by population, location
ORDER BY population_infected desc;

-- countries with highest total number of deaths 
-- (had to change type of total_deaths to int from text by updating table and replacing empty cells with 0's then change data type back to int)

/*update coviddeaths 
set total_deaths = 0 
where total_deaths= '';*/

select location, max(total_deaths)
from coviddeaths
where continent is not null
group by location
order by 2 desc;

-- continents with highest number of deaths + countries in asia

select location, max(total_deaths)
from coviddeaths
where continent is null or continent ='asia'
group by location
order by 2 desc;

-- countries with highest proportion of deaths compared to population

select location, max(total_deaths),population,max((total_deaths/population)*100) as proportion_of_deaths
from coviddeaths 
where continent is not null
group by location, population
order by proportion_of_deaths desc;

-- show continents with highest death rate per population

select location,max(total_deaths),population,max(total_deaths/population)*100 as proportion_of_deaths
from coviddeaths 
where continent is null
group by location,population
order by proportion_of_deaths desc;

-- global numbers for daily proportion of deaths per infected
-- converted date from varchar(255) to date using str_to_date function




-- join both tables
select *
from coviddeaths
join covidvaccinations using(location,date);


-- looking at total population vs new_vaccinations per day

select de.continent, de.location,str_to_date(de.date,'%d/%m/%Y'), de.population, va.new_vaccinations
from coviddeaths as de
join covidvaccinations as va using(location,date)
where de.continent is not null
order by 2,3;

-- doing a running total of the new vaccinations for each country

select de.continent, de.location,str_to_date(de.date,'%d/%m/%Y'), de.population, va.new_vaccinations,sum(va.new_vaccinations) over (partition by de.location order by de.location, str_to_date(de.date,'%d/%m/%Y')) as cumulative_new_vaccinations
from coviddeaths as de
join covidvaccinations as va using(location,date)
where de.continent is not null 
order by 2,3;

-- create CTE of cumulative vaccinations and then work out cumulative proportion vaxxed

 with pop_vac(continent,location,date,population,new_vaccinations,cumulative_new_vaccinations)
as
(select de.continent, de.location,str_to_date(de.date,'%d/%m/%Y'), de.population, va.new_vaccinations,sum(va.new_vaccinations) over (partition by de.location order by de.location, str_to_date(de.date,'%d/%m/%Y')) as cumulative_new_vaccinations
from coviddeaths as de
join covidvaccinations as va using(location,date)
where de.continent is not null and location like '%kingdom%'
)
select *,(cumulative_new_vaccinations/population)*100 as cumulative_proportion_vaxxed
from pop_vac;

-- use temp table for the above

drop table if exists £pop_vac;
create table £pop_vac
(continent varchar(255),
location varchar (255),
date date,
population int,
new_vaccinations int,
cumulative_new_vaccinations int);


insert into £pop_vac
select de.continent, de.location,str_to_date(de.date,'%d/%m/%Y'), de.population, va.new_vaccinations,sum(va.new_vaccinations) over (partition by de.location order by de.location, str_to_date(de.date,'%d/%m/%Y')) as cumulative_new_vaccinations
from coviddeaths as de
join covidvaccinations as va using(location,date)
where de.continent is not null and location like'%kingdom%'
order by 2,3;

select *,(cumulative_new_vaccinations/population)*100 as cumulative_proportion_vaxxed
from £pop_vac;


-- create view to store data for later visualisation

drop view if exists pop_vac;
create view pop_vac
as 
select de.continent, de.location,str_to_date(de.date,'%d/%m/%Y'), de.population, va.new_vaccinations,sum(va.new_vaccinations) over (partition by de.location order by de.location, str_to_date(de.date,'%d/%m/%Y')) as cumulative_vaccinations
from coviddeaths as de
join covidvaccinations as va using(location,date)
where de.continent is not null and de.location like '%kingdom%'
order by 2,3;
select *,(cumulative_vaccinations/population)*100 as proprotion_cumulative_vaccinations
from pop_vac;

-- from here, unguided (no help from alex the analyst)

--  creating multiple views
--  look at relationship between stringency index and number of new deaths, new cases 

drop view if exists StringencyVScases_and_deaths;
create view StringencyVScases_and_deaths
as
select de.continent, de.location,str_to_date(de.date,'%d/%m/%Y'), de.population,sum(de.new_cases) over (partition by de.location order by de.location, str_to_date(de.date, '%d/%m/%Y')) as cumulative_new_cases,sum(de.new_deaths) over (partition by de.location order by de.location, str_to_date(de.date,'%d/%m/%Y')) as cumulative_new_deaths,va.stringency_index
from coviddeaths as de
join covidvaccinations as va using (location,date) 
where de.continent is not null and de.location like '%kingdom%'
order by 2,3;

select *, (cumulative_new_deaths/cumulative_new_cases)*100 as cumulative_proportion_deaths_per_case
from StringencyVScases_and_deaths;
 
-- looking at new vaccinations and number of deaths 

drop view if exists vacc_deaths;
create view vacc_deaths
as
select de.continent, de.location,str_to_date(de.date,'%d/%m/%Y'), de.population,sum(de.new_deaths) over (partition by de.location order by de.location, str_to_date(de.date,'%d/%m/%Y')) as cumulative_new_deaths,sum(va.new_vaccinations) over (partition by de.location order by de.location, str_to_date(de.date,'%d/%m/%Y')) as cumulative_new_vaccinations
from coviddeaths as de
join covidvaccinations as va using (location,date)
where de.continent is not null and de.location like '%kingdom%'
order by 2,3;

select *, (cumulative_new_deaths/population)*100 as cumulative_proportion_of_deaths
from vacc_deaths;






-- sum of new_cases, and new deaths and poroportion for all countries
-- for tableau table 1
select sum(new_cases), sum(new_deaths) as total_deaths, 
(sum(new_deaths)/ sum(new_cases))*100 as percentage_of_deaths
from coviddeaths
order by 1,2;

-- for tableau table 2

select location,sum(new_deaths) as totaldeathcount
from coviddeaths
where continent is null 
and location not in ('International','European Union') or continent='asia'
group by location 
order by 2 desc;

-- for tableau table 3

select location, population, max(total_cases) as highestinfectioncount,
(max(total_cases)/population)*100 as percentage_population_infected
from coviddeaths
group by location,population
order by 4 desc;

-- for tableau table 4

select location,population,date,max(total_cases) as highestinfectioncount,
(max(total_cases)/population)*100 as percentage_population_infected
from coviddeaths
group by location,population,date
order by percentage_population_infected desc;























































