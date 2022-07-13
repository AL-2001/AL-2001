select *
from `nashville housing data`;

-- change saledate to date format

/*select saledate,saledate,substring_index(saledate,',',1) as month,
substr(saledate,-4,4) as year,
concat(substring_index(saledate,',',1),' ',substr(saledate,-4,4)) as sale_date
from `nashville housing data`;

update `nashville housing data`
set saledate=concat(substring_index(saledate,',',1),' ',substr(saledate,-4,4)); 

select saledate,str_to_date(saledate,"%M %d %Y")
from `nashville housing data`;*/

update `nashville housing data`
set saledate = str_to_date(saledate,"%M %d %Y");

select *
from `nashville housing data`;

-- populate property address data
 
select *
from `nashville housing data`
order by parcelID;

-- self join table and for two records of same parcelID, if one has empty property
-- address, populate it with the other propeertyaddress which is not null with nullif 
-- function

select a.parcelID,a.propertyaddress, b.parcelID,b.propertyaddress, nullif(b.propertyaddress,a.propertyaddress)
from `nashville housing data` as a
join `nashville housing data` as b
on a.parcelID=b.parcelID
AND a.uniqueID != b.uniqueID
where a.propertyaddress = '';


-- update table
update `nashville housing data` as a
join `nashville housing data` as b
on a.parcelID=b.parcelID
set a.propertyaddress = nullif(b.propertyaddress,a.propertyaddress)
AND a.uniqueID != b.uniqueID
where a.propertyaddress = '';

-- Break address to address, city, state

select propertyaddress
from `nashville housing data`;

-- seperate propertyaddress into address,city

select propertyaddress, substring_index(propertyaddress,',','1') as address,
substring_index(propertyaddress,',','-1') as city
from `nashville housing data`;

-- create two new columns

alter table `nashville housing data`
add (property_address varchar(255),
property_city varchar(255));

-- update new columns with the indexed values

update `nashville housing data`
set property_address = substring_index(propertyaddress,',','1'),
property_city = substring_index(propertyaddress,',','-1');

select *
from `nashville housing data`;

-- break owneraddress into address city,state

select substring_index(owneraddress,',','1') as address,
substring_index(substring_index(owneraddress,',',2),',',-1) as city,
substring_index(owneraddress,',','-1') as state
from `nashville housing data`;

-- create 3 new columns

alter table `nashville housing data`
add(owner_address varchar(255),
owner_city varchar (255),
owner_state varchar (255));

-- add the indexed records into the 3 new columns

update `nashville housing data`
set owner_address = substring_index(owneraddress,',','1'),
owner_city = substring_index(substring_index(owneraddress,',',2),',',-1),
owner_state = substring_index(owneraddress,',','-1');

select owner_address,owner_city,owner_state
from `nashville housing data`;

-- change Y and N to yes and no in 'sold as vacant' field

select distinct(`soldasvacant`),count(soldasvacant)
from `nashville housing data`
group by soldasvacant;

select soldasvacant,
case
when soldasvacant="Y" then "Yes"
when soldasvacant="N" then "No"
else soldasvacant
end
from `nashville housing data`;

update `nashville housing data`
set soldasvacant =
case
when soldasvacant="Y" then "Yes"
when soldasvacant="N" then "No"
else soldasvacant
end;

select distinct(soldasvacant),count(soldasvacant)
from `nashville housing data`
group by soldasvacant;


-- remove duplicates by creating CTE and assuming same records consist of the following same fields:
-- parcelID,propertyaddress,saleprice,saledate,legalreference and then delete those records

with row_noCTE 
as 
(select *,row_number() over
(partition by parcelID,propertyaddress,saleprice,saledate,legalreference
order by uniqueID) as row_no
from  `nashville housing data`
)
delete 
from `nashville housing data` using `nashville housing data`
join row_noCTE on `nashville housing data`.uniqueID = row_noCTE.uniqueID
where row_no > 1;



with row_noCTE 
as 
(select *,row_number() over
(partition by parcelID,propertyaddress,saleprice,saledate,legalreference
order by uniqueID) as row_no
from  `nashville housing data`
)
select *
from row_noCTE;


-- delete unused columns

alter table `nashville housing data`
drop column TaxDistrict;

select *
from `nashville housing data`;



















































 


