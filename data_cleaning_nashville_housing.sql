/*
Cleaning Nashville Housing Data by 
standardizing the format of fields, populate missing data, splitting addresses to street name, city and state,
removing duplicates and removing unwanted columns
*/

-- Selecting database
USE data_cleaning

SELECT *
FROM nashville_housing


-- Standardize Date Format

Update nashville_housing
SET SaleDate = CONVERT(Date, SaleDate)

SELECT SaleDate
FROM nashville_housing

-- Another way to standardize date 

ALTER TABLE nashville_housing
ADD SaleDateConverted Date;

UPDATE nashville_housing
SET SaleDateConverted = CONVERT(Date,SaleDate)



-- Populate Property Address data
-- There are nulls in the Property Address
-- Rows with the same Parcel ID have thes same address
-- Populate NULL property address with addresses with the matching parcel ID
-- Use self-join
-- After update, there should be no NULLs

SELECT *
FROM nashville_housing
--Where PropertyAddress is null
ORDER BY ParcelID


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM nashville_housing a
JOIN data_cleaning..nashville_housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null


Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM nashville_housing a
JOIN data_cleaning..nashville_housing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null



-- Breaking out Addresses into Individual Columns (Address, City, State)

-- Splitting Property Address using substrings
SELECT PropertyAddress
FROM nashville_housing

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as Address
FROM nashville_housing


ALTER TABLE nashville_housing
ADD PropertySplitAddress NVARCHAR(255);

Update nashville_housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )


ALTER TABLE nashville_housing
ADD PropertySplitCity NVARCHAR(255);

Update nashville_housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))



--Splitting OwnerAddress by parsename
SELECT OwnerAddress
FROM nashville_housing


SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
FROM nashville_housing


ALTER TABLE nashville_housing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE nashville_housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE nashville_housing
Add OwnerSplitCity NVARCHAR(255);

Update nashville_housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)


ALTER TABLE nashville_housing
Add OwnerSplitState Nvarchar(255);

Update nashville_housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)



-- The SoldAsVacant field has a mix of Yes, No, Y, N
-- Change Y and N to Yes and No in SoldAsVacant field


SELECT Distinct(SoldAsVacant), Count(SoldAsVacant)
FROM nashville_housing
Group by SoldAsVacant
order by 2

Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM nashville_housing


Update nashville_housing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END


-- Remove Duplicates

-- View list of duplicates
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM nashville_housing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

-- Delete the duplicates 
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM nashville_housing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1



-- Delete Unwanted Columns

ALTER TABLE nashville_housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

