CREATE TABLE NashvilleHousing (
    UniqueID INT,
    ParcelID VARCHAR(100),
    LandUse VARCHAR(100),
    PropertyAddress VARCHAR(200),
    SaleDate DATE,
    SalePrice INT,
    LegalReference VARCHAR(100),
    SoldAsVacant VARCHAR(3),
    OwnerName VARCHAR(200),
    OwnerAddress VARCHAR(200),
    Acreage DECIMAL(3 , 2 ),
    TaxDistrict VARCHAR(100),
    LandValue INT,
    BuildingValue INT,
    TotalValue INT,
    YearBuilt INT,
    Bedrooms INT,
    FullBath INT,
    HalfBath INT
);

SHOW GLOBAL VARIABLES LIKE 'local_infile';

load data local infile 'C:/Users/ehanz/OneDrive/Documents/data_analysis/Nashville Housing/Nashville Housing Data for Data Cleaning.csv'
into table nashvillehousing
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

/*
-- Standardize Date Format in SQL SERVER (THIS IS FOR FUTURE REFERENCE ONLY)

Select saleDateConverted, CONVERT(Date,SaleDate)
From PortfolioProject.dbo.NashvilleHousing


Update NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

-- If it doesn't Update properly

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)
*/

SELECT *
FROM NashvilleHousing
WHERE PropertyAddress IS NULL
ORDER BY parcelid;

UPDATE NashvilleHousing 
SET PropertyAddress = NULL
WHERE PropertyAddress = '';

SELECT 
    a.uniqueid,
    a.parcelid,
    a.propertyaddress,
    b.uniqueid,
    b.parcelid,
    b.propertyaddress,
    IFNULL(a.propertyaddress, b.propertyaddress)
FROM NashvilleHousing AS a
	JOIN NashvilleHousing AS b ON a.parcelid = b.parcelid
        AND a.uniqueid <> b.uniqueid
WHERE a.propertyaddress IS NULL;

UPDATE NashvilleHousing AS a
JOIN
    (SELECT b.parcelid, IFNULL(a.propertyaddress, b.propertyaddress) AS new_propertyaddress
    FROM NashvilleHousing AS a
    JOIN NashvilleHousing AS b ON a.parcelid = b.parcelid
        AND a.uniqueid <> b.uniqueid
    WHERE a.propertyaddress IS NULL) AS subquery ON a.parcelid = subquery.parcelid 
SET a.PropertyAddress = subquery.new_propertyaddress;

-- Breaking out Address into Individual Columns (Address, City, State)
SELECT propertyaddress
FROM NashvilleHousing;

SELECT 
    SUBSTRING(propertyaddress, 1,
        LOCATE(',', propertyaddress) - 1) AS Address,
    SUBSTRING(propertyaddress,
        LOCATE(',', propertyaddress) + 1) AS City
FROM NashvilleHousing;

ALTER TABLE NashvilleHousing
Add Address varchar (255);

UPDATE NashvilleHousing 
SET 
    Address = SUBSTRING(propertyaddress, 1,
        LOCATE(',', propertyaddress) - 1);

ALTER TABLE NashvilleHousing
RENAME COLUMN Address to PropertySplitAddress;

ALTER TABLE NashvilleHousing
Add City varchar (255);

UPDATE NashvilleHousing 
SET 
    City = SUBSTRING(propertyaddress,
        LOCATE(',', propertyaddress) + 1);

ALTER TABLE NashvilleHousing
RENAME COLUMN City to PropertySplitCity;

SELECT 
    SUBSTRING(OwnerAddress,  1,
        LOCATE(',', OwnerAddress) - 1) AS Address,
    SUBSTRING(OwnerAddress,
        LOCATE(',', OwnerAddress) + 1)
        AND SUBSTRING_INDEX() AS City
FROM NashvilleHousing;

SELECT 
    TRIM(SUBSTRING_INDEX(OwnerAddress, ',', 1)) AS OwnerAddress,
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', - 2), ',', 1)) AS OwnerCity,
    TRIM(SUBSTRING_INDEX(OwnerAddress, ',', - 1)) AS OwnerState
FROM NashvilleHousing;

ALTER TABLE NashvilleHousing
Add OwnerSplitAddress varchar (255);

UPDATE NashvilleHousing 
SET OwnerSplitAddress = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', 1));

ALTER TABLE NashvilleHousing
Add OwnerSplitCity varchar (255);

UPDATE NashvilleHousing 
SET OwnerSplitCity = TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', - 2), ',', 1));

ALTER TABLE NashvilleHousing
Add OwnerSplitState varchar (255);

UPDATE NashvilleHousing 
SET OwnerSplitState = TRIM(SUBSTRING_INDEX(OwnerAddress, ',', - 1));

-- Change Y and N to Yes and No in "Sold as Vacant" field

select distinct(SoldAsVacant), count(SoldAsVacant)
from nashvillehousing
group by SoldAsVacant;

select soldasvacant,
	case 
		when soldasvacant = 'Y' then 'Yes'
		when soldasvacant = 'N' then 'No'
		else soldasvacant
    end
from nashvillehousing;

update nashvillehousing
set soldasvacant = 
	case 
		when soldasvacant = 'Y' then 'Yes'
		when soldasvacant = 'N' then 'No'
		else soldasvacant
    end;
    
-- Remove Duplicates

with RowNumCTE as (
select *, 	
	row_number() over (
		partition by ParcelID, 
					 PropertyAddress, 
                     SaleDate, 
                     LegalReference
                     order by uniqueid) as row_num
from nashvillehousing)

-- Use the following statement to verify if the query above is correct and to look at the duplicates
select *
from RowNumCTE
where row_num > 1
order by propertyaddress;

DELETE 
	FROM nashvillehousing 
		USING nashvillehousing 
        JOIN RowNumCTE 
			ON nashvillehousing.ParcelID = RowNumCTE.ParcelID
WHERE RowNumCTE.row_num > 1;

select *
from RowNumCTE
where row_num > 1
order by propertyaddress;

-- Delete Unused Columns

select * 
from nashvillehousing;

alter table nashvillehousing
drop column OwnerAddress,
drop column TaxDistrict,
drop column propertyaddress;