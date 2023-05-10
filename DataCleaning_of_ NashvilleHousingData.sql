/* Nashville Housing Data Cleaning Project . 
   Imported Data Using SQL Server Import and Export Wizard */

---------------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM dbo.NashvilleHousingData;
USE Projects ;

-------------------------------------------------------1) Standardizing Date Format ---------------------------------------------------------

SELECT SaleDate , CONVERT(Date, SaleDate)
FROM StudyProjects.dbo.NashvilleHousingData;

ALTER TABLE StudyProjects.dbo.NashvilleHousingData ADD SaleDateConverted DATE; ---- Adding a new column------

UPDATE NashvilleHousingData SET SaleDateConverted= CONVERT(Date, SaleDate) ;   -----Updating the table with data from SaleDate column.--

SELECT * From NashvilleHousingData ;  --- For Checking---

------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------2) Populate PropertyAddress Data -------------------------------------------------------

SELECT * FROM NashvilleHousingData Where PropertyAddress IS NULL ; 

SELECT * FROM NashvilleHousingData 
Where PropertyAddress IS NULL  
Order BY ParcelID ; 

/*  We observed that with the help of ParcelID we can provide the PropertyAdrdress to the rows which don't have Property Address. 
 We will be using Self Join so that we can get the table where ParcelIds are same but UniqueIds are different.  */

SELECT a.ParcelID , a.PropertyAddress , b.ParcelID , b.PropertyAddress 
FROM NashvilleHousingData a
JOIN NashvilleHousingData b 
ON a.ParcelID = b.ParcelID and a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress IS NULL ;

SELECT a.ParcelID , a.PropertyAddress , b.ParcelID , b.PropertyAddress , ISNULL(a.PropertyAddress, b.PropertyAddress) 
FROM NashvilleHousingData a
JOIN NashvilleHousingData b 
ON a.ParcelID = b.ParcelID and a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress IS NULL ; --- We want to populate the rows that are null rows with the address from column got from self join .  

UPDATE a
SET PropertyAddress= ISNULL(a.PropertyAddress, b.PropertyAddress) 
FROM NashvilleHousingData a
JOIN NashvilleHousingData b 
ON a.ParcelID = b.ParcelID and a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress IS NULL;

-----------------------------(3) Breaking out Addresses into individual columns ( Address , city , state ) ------------------------------

SELECT PropertyAddress from NashvilleHousingData ;
SELECT PropertyAddress,
SUBSTRING(PropertyAddress , 1 , CHARINDEX(',',PropertyAddress)-1) as Address ,
SUBSTRING(PropertyAddress , CHARINDEX(',',PropertyAddress)+1 , LEN(PropertyAddress)) as City 
from NashvilleHousingData;

/* (a) We used CHARINDEX function which basically gives postion on any character here we are using "," as our 
       separator that we observed was present in every row and between property address and city. 
   (b) SUBSTRING is helping us to incapsulate the particular portion of the string i.e. property address.
*/ 

--- Adding a new column for our property address and updating the columns with results of substring method we checked earlier.  --

ALTER TABLE NashvilleHousingData ADD PropertySplitAddress Nvarchar(255); -
UPDATE NashvilleHousingData 
SET PropertySplitAddress = SUBSTRING(PropertyAddress , 1 , CHARINDEX(',',PropertyAddress)-1) ;

ALTER TABLE NashvilleHousingData ADD PropertySplitCity Nvarchar(255);
UPDATE NashvilleHousingData 
SET PropertySplitCity= SUBSTRING(PropertyAddress , CHARINDEX(',',PropertyAddress)+1 , LEN(PropertyAddress));

SELECT * from NashvilleHousingData; ---For Checking---
SELECT OwnerAddress from NashvilleHousingData; ---For Checking---

/*a. Using PARSENAME() function for dividing the Owner's Address same as done above. 
  b. PARSENAME only takes period i.e "." as delimiter therefore we first converted our "," to "." with the help of REPLACE() function.
*/ 

SELECT 
PARSENAME(Replace(OwnerAddress,',','.'),3),
PARSENAME(Replace(OwnerAddress,',','.'),2),
PARSENAME(Replace(OwnerAddress,',','.'),1)
from NashvilleHousingData;

ALTER TABLE NashvilleHousingData ADD OwnerSplitAddress Nvarchar(255);
UPDATE NashvilleHousingData 
SET OwnerSplitAddress = PARSENAME(Replace(OwnerAddress,',','.'),3);

ALTER TABLE NashvilleHousingData ADD OwnerSplitCity Nvarchar(255);
UPDATE NashvilleHousingData 
SET OwnerSplitCity = PARSENAME(Replace(OwnerAddress,',','.'),2);

ALTER TABLE NashvilleHousingData ADD OwnerSplitState Nvarchar(255);
UPDATE NashvilleHousingData 
SET OwnerSplitState = PARSENAME(Replace(OwnerAddress,',','.'),1);

SELECT * from NashvilleHousingData; ----For Checking----

-----------------------------------------------------------------------------------------------------------------------------------------------

-----------------(4) Changing "Y" and "N" to "Yes" and "No" respectively in SoldAsVacant column for better unifromity.-------------------------

SELECT SoldAsVacant , COUNT(SoldAsVacant) -- To see how many Y and N are there which are 399 and 52 repectively--
from NashvilleHousingData 
GROUP BY SoldAsVacant;

SELECT SoldAsVacant, CASE WHEN SoldAsVacant= 'Y' THEN 'Yes'
                       WHEN SoldAsVacant= 'N' THEN 'No' 
					   ELSE SoldAsVacant  END
from NashvilleHousingData;

UPDATE NashvilleHousingData 
SET SoldAsVacant= CASE WHEN SoldAsVacant= 'Y' THEN 'Yes'
                       WHEN SoldAsVacant= 'N' THEN 'No' 
					   ELSE SoldAsVacant  
					   END

SELECT SoldAsVacant , COUNT(SoldAsVacant) -- For Checking --
from NashvilleHousingData 
GROUP BY SoldAsVacant;

--------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------- (5) Removing Duplicates -----------------------------------------------------------------

WITH RowNumCTE as(
SELECT *,ROW_NUMBER() OVER 
( Partition BY ParcelID , PropertyAddress , SalePrice, SaleDate, LegalReference Order BY UniqueID) as row_num
FROM NashvilleHousingData)

SELECT * from RowNumCTE where row_num>1; 

-- Made a CTE using window function ROW_NUMBER() to get duplictaes and then we will delete the rows which have row number greater than 1.--- 

WITH RowNumCTE as(
SELECT *,ROW_NUMBER() OVER 
( Partition BY ParcelID , PropertyAddress , SalePrice, SaleDate, LegalReference Order BY UniqueID) as row_num
FROM NashvilleHousingData)
DELETE  from RowNumCTE where row_num>1;     --Deleting the rows which have row number greater than 1 . There were 104 such rows.-------------
SELECT * from NashvilleHousingData; ---For Checking-----


----------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------(6) Deleting Non-Important Columns ----------------------------------------------------------

SELECT * from NashvilleHousingData; 

ALTER TABLE NashvilleHousingData
DROP COLUMN PropertyAddress , SaleDate, OwnerAddress , TaxDistrict ;
