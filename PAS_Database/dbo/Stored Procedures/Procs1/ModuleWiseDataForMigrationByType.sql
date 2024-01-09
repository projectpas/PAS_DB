/* 
[dbo].[ModuleWiseDataForMigrationByType] 1, 10, 'CreatedDate', -1, 'Customer', 2, 12
*/
CREATE   PROCEDURE [dbo].[ModuleWiseDataForMigrationByType]
	@PageNumber INT = NULL,
	@PageSize INT = NULL,
	@SortColumn VARCHAR(50) = NULL,
	@SortOrder INT = NULL,
	@ModuleName VARCHAR(50) = NULL,
	@TypeId INT = NULL,
	@MasterCompanyId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

	DECLARE @RecordFrom INT;
	DECLARE @Count INT;
	DECLARE @IsActive BIT;
	
	SET @RecordFrom = (@PageNumber - 1) * @PageSize;
	
	IF @SortColumn IS NULL
	BEGIN
		SET @SortColumn = UPPER('CreatedDate')
	END 
	ELSE
	BEGIN 
		Set @SortColumn = UPPER(@SortColumn)
	END	
	
	SET @IsActive = NULL;
		
		DECLARE @MSModuelId int; 
		SET @MSModuelId = 2;   -- For Stockline

		IF (@ModuleName = 'Customer')
		BEGIN
			IF (@TypeId = 1)
			BEGIN
				;WITH Result AS (
				SELECT DISTINCT 
					Cs.Migrated_Id,
					Cs.CustomerId, 
					Cs.Company_Name [Name],
					Cs.Company_Code CustomerCode,
					Cs.Email_Address Email,
					'CUSTOMER' AS AccountType,
					ISNULL(CD.DESCRIPTION, '') 'CustomerClassification',
					Cs.City,
					Cs.State StateOrProvince,
					ISNULL(Cs.Contact_Name,'') AS 'Contact',
					'' AS 'SalesPersonPrimary',
					1 IsActive,
					0 IsDeleted,
					Cs.CreatedDate,
					CA.[Description] AS CustomerType,
					CASE WHEN ISNULL(Cs.Track_Changes, 'F') = 'T' THEN 1 ELSE 0 END AS IsTrackScoreCard,
					SuccessMsg,
					ErrorMsg
				FROM [Quantum_Staging].dbo.Customers Cs WITH (NOLOCK)
				LEFT JOIN [Quantum].QCTL_NEW_3.CLASS_CODES CD ON CD.CLC_AUTO_KEY = Cs.CustomerClassCodeId
				LEFT JOIN dbo.Customer C  WITH (NOLOCK) ON C.CustomerId = Cs.Migrated_Id
				LEFT JOIN dbo.CustomerAffiliation CA  WITH (NOLOCK) ON C.CustomerAffiliationId = CA.CustomerAffiliationId
		 		  WHERE Cs.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(CustomerId) AS totalItems FROM Result)
				SELECT * INTO #TempResultC1 FROM  Result

				SELECT @Count = COUNT(CustomerId) FROM #TempResultC1			

				SELECT *, @Count AS NumberOfItems FROM #TempResultC1 ORDER BY  
				CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='EMAIL')  THEN Email END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='City')  THEN City END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='STATEORPROVINCE')  THEN StateOrProvince END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='ACCOUNTTYPE')  THEN AccountType END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERTYPE')  THEN CustomerType END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERCLASSIFICATION')  THEN CustomerClassification END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='CONTACT')  THEN Contact END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='SALESPERSONPRIMARY')  THEN SalesPersonPrimary END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='NAME')  THEN [Name] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERCODE')  THEN CustomerCode END ASC,

				CASE WHEN (@SortOrder=-1 AND @SortColumn='EMAIL')  THEN Email END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='City')  THEN City END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='STATEORPROVINCE')  THEN StateOrProvince END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ACCOUNTTYPE')  THEN AccountType END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERTYPE')  THEN CustomerType END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERCLASSIFICATION')  THEN CustomerClassification END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CONTACT')  THEN Contact END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='SALESPERSONPRIMARY')  THEN SalesPersonPrimary END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='NAME')  THEN [Name] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERCODE')  THEN CustomerCode END DESC
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
			ELSE IF (@TypeId = 2)
			BEGIN
				;WITH Result AS (
				SELECT DISTINCT Cs.Migrated_Id CustomerId, 
					Cs.Migrated_Id,
					1 ModuleId,
					Cs.Company_Name [Name],
					Cs.Company_Code CustomerCode,
					Cs.Email_Address Email,
					'CUSTOMER' AS AccountType,
					ISNULL(CD.DESCRIPTION, '') 'CustomerClassification',
					Cs.City,
					Cs.State StateOrProvince,
					ISNULL(Cs.Contact_Name,'') AS 'Contact',
					'' AS 'SalesPersonPrimary',
					1 IsActive,
					0 IsDeleted,
					Cs.CreatedDate,
					CA.[Description] AS CustomerType,
					CASE WHEN ISNULL(Cs.Track_Changes, 'F') = 'T' THEN 1 ELSE 0 END AS IsTrackScoreCard,
					SuccessMsg,
					ErrorMsg
				FROM [Quantum_Staging].dbo.Customers Cs WITH (NOLOCK)
				LEFT JOIN [Quantum].QCTL_NEW_3.CLASS_CODES CD ON CD.CLC_AUTO_KEY = Cs.CustomerClassCodeId
				LEFT JOIN dbo.Customer C  WITH (NOLOCK) ON C.CustomerId = Cs.Migrated_Id
				LEFT JOIN dbo.CustomerAffiliation CA  WITH (NOLOCK) ON C.CustomerAffiliationId = CA.CustomerAffiliationId
		 		  WHERE Cs.Migrated_Id IS NOT NULL AND Cs.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(CustomerId) AS totalItems FROM Result)
				SELECT * INTO #TempResultC2 FROM  Result

				SELECT @Count = COUNT(CustomerId) FROM #TempResultC2			

				SELECT *, @Count AS NumberOfItems FROM #TempResultC2 ORDER BY  
				CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='EMAIL')  THEN Email END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='City')  THEN City END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='STATEORPROVINCE')  THEN StateOrProvince END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='ACCOUNTTYPE')  THEN AccountType END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERTYPE')  THEN CustomerType END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERCLASSIFICATION')  THEN CustomerClassification END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='CONTACT')  THEN Contact END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='SALESPERSONPRIMARY')  THEN SalesPersonPrimary END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='NAME')  THEN [Name] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERCODE')  THEN CustomerCode END ASC,

				CASE WHEN (@SortOrder=-1 AND @SortColumn='EMAIL')  THEN Email END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='City')  THEN City END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='STATEORPROVINCE')  THEN StateOrProvince END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ACCOUNTTYPE')  THEN AccountType END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERTYPE')  THEN CustomerType END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERCLASSIFICATION')  THEN CustomerClassification END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CONTACT')  THEN Contact END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='SALESPERSONPRIMARY')  THEN SalesPersonPrimary END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='NAME')  THEN [Name] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERCODE')  THEN CustomerCode END DESC
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
			ELSE IF (@TypeId = 3)
			BEGIN
				;WITH Result AS (
				SELECT DISTINCT Cs.CustomerId, 
					Cs.Migrated_Id,
					Cs.Company_Name [Name],
					Cs.Company_Code CustomerCode,
					Cs.Email_Address Email,
					'CUSTOMER' AS AccountType,
					ISNULL(CD.DESCRIPTION, '') 'CustomerClassification',
					Cs.City,
					Cs.State StateOrProvince,
					ISNULL(Cs.Contact_Name,'') AS 'Contact',
					'' AS 'SalesPersonPrimary',
					1 IsActive,
					0 IsDeleted,
					Cs.CreatedDate,
					CA.[Description] AS CustomerType,
					CASE WHEN ISNULL(Cs.Track_Changes, 'F') = 'T' THEN 1 ELSE 0 END AS IsTrackScoreCard,
					SuccessMsg,
					ErrorMsg
				FROM [Quantum_Staging].dbo.Customers Cs WITH (NOLOCK)
				LEFT JOIN [Quantum].QCTL_NEW_3.CLASS_CODES CD ON CD.CLC_AUTO_KEY = Cs.CustomerClassCodeId
				LEFT JOIN dbo.Customer C  WITH (NOLOCK) ON C.CustomerId = Cs.Migrated_Id
				LEFT JOIN dbo.CustomerAffiliation CA  WITH (NOLOCK) ON C.CustomerAffiliationId = CA.CustomerAffiliationId
		 		  WHERE Cs.Migrated_Id IS NULL AND (Cs.ErrorMsg IS NOT NULL AND Cs.ErrorMsg NOT like '%Customer already exists%') AND Cs.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(CustomerId) AS totalItems FROM Result)
				SELECT * INTO #TempResultC3 FROM  Result

				SELECT @Count = COUNT(CustomerId) FROM #TempResultC3			

				SELECT *, @Count AS NumberOfItems FROM #TempResultC3 ORDER BY  
				CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='EMAIL')  THEN Email END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='City')  THEN City END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='STATEORPROVINCE')  THEN StateOrProvince END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='ACCOUNTTYPE')  THEN AccountType END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERTYPE')  THEN CustomerType END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERCLASSIFICATION')  THEN CustomerClassification END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='CONTACT')  THEN Contact END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='SALESPERSONPRIMARY')  THEN SalesPersonPrimary END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='NAME')  THEN [Name] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERCODE')  THEN CustomerCode END ASC,

				CASE WHEN (@SortOrder=-1 AND @SortColumn='EMAIL')  THEN Email END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='City')  THEN City END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='STATEORPROVINCE')  THEN StateOrProvince END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ACCOUNTTYPE')  THEN AccountType END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERTYPE')  THEN CustomerType END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERCLASSIFICATION')  THEN CustomerClassification END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CONTACT')  THEN Contact END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='SALESPERSONPRIMARY')  THEN SalesPersonPrimary END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='NAME')  THEN [Name] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERCODE')  THEN CustomerCode END DESC
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
			ELSE IF (@TypeId = 4)
			BEGIN
				;WITH Result AS (
				SELECT DISTINCT Cs.CustomerId, 
					Cs.Migrated_Id,
					Cs.Company_Name [Name],
					Cs.Company_Code CustomerCode,
					Cs.Email_Address Email,
					'CUSTOMER' AS AccountType,
					ISNULL(CD.DESCRIPTION, '') 'CustomerClassification',
					Cs.City,
					Cs.State StateOrProvince,
					ISNULL(Cs.Contact_Name,'') AS 'Contact',
					'' AS 'SalesPersonPrimary',
					1 IsActive,
					0 IsDeleted,
					Cs.CreatedDate,
					CA.[Description] AS CustomerType,
					CASE WHEN ISNULL(Cs.Track_Changes, 'F') = 'T' THEN 1 ELSE 0 END AS IsTrackScoreCard,
					SuccessMsg,
					ErrorMsg
				FROM [Quantum_Staging].dbo.Customers Cs WITH (NOLOCK)
				LEFT JOIN [Quantum].QCTL_NEW_3.CLASS_CODES CD ON CD.CLC_AUTO_KEY = Cs.CustomerClassCodeId
				LEFT JOIN dbo.Customer C  WITH (NOLOCK) ON C.CustomerId = Cs.Migrated_Id
				LEFT JOIN dbo.CustomerAffiliation CA  WITH (NOLOCK) ON C.CustomerAffiliationId = CA.CustomerAffiliationId
		 		  WHERE Cs.Migrated_Id IS NULL AND (Cs.ErrorMsg IS NOT NULL AND Cs.ErrorMsg like '%Customer already exists%') AND Cs.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(CustomerId) AS totalItems FROM Result)
				SELECT * INTO #TempResultC4 FROM  Result

				SELECT @Count = COUNT(CustomerId) FROM #TempResultC4			

				SELECT *, @Count AS NumberOfItems FROM #TempResultC4 ORDER BY  
				CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='EMAIL')  THEN Email END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='City')  THEN City END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='STATEORPROVINCE')  THEN StateOrProvince END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='ACCOUNTTYPE')  THEN AccountType END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERTYPE')  THEN CustomerType END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERCLASSIFICATION')  THEN CustomerClassification END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='CONTACT')  THEN Contact END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='SALESPERSONPRIMARY')  THEN SalesPersonPrimary END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='NAME')  THEN [Name] END ASC,
				CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERCODE')  THEN CustomerCode END ASC,

				CASE WHEN (@SortOrder=-1 AND @SortColumn='EMAIL')  THEN Email END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='City')  THEN City END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='STATEORPROVINCE')  THEN StateOrProvince END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ACCOUNTTYPE')  THEN AccountType END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERTYPE')  THEN CustomerType END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERCLASSIFICATION')  THEN CustomerClassification END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CONTACT')  THEN Contact END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='SALESPERSONPRIMARY')  THEN SalesPersonPrimary END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='NAME')  THEN [Name] END DESC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERCODE')  THEN CustomerCode END DESC
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
		END
		IF (@ModuleName = 'Vendor')
		BEGIN
			IF (@TypeId = 1)
			BEGIN
				;WITH Result AS (
				SELECT DISTINCT 
					Vs.Migrated_Id,
					Vs.VendorId,
                    Vs.Company_Name VendorName,
                    Vs.Company_Code VendorCode,                   
					VT.[Description] [Description],  
                    Vs.Email_Address VendorEmail,               
					(ISNULL(Vs.City,'')) 'City',
                    (ISNULL(Vs.State, '')) 'StateOrProvince',
					(ISNULL(Vs.Contact_Name, '')) 'VendorPhoneContact',                   
                    Vs.CreatedDate,
                    0 IsDeleted,
					1 IsActive,
					ISNULL(CD.DESCRIPTION, '') 'ClassificationName',
					SuccessMsg,
					ErrorMsg
				FROM [Quantum_Staging].dbo.Vendors Vs WITH (NOLOCK)
				LEFT JOIN [Quantum].QCTL_NEW_3.CLASS_CODES CD ON CD.CLC_AUTO_KEY = Vs.CustomerClassCodeId
				LEFT JOIN dbo.Vendor V WITH (NOLOCK) ON V.VendorId = Vs.Migrated_Id
				LEFT JOIN dbo.VendorType VT WITH (NOLOCK) ON V.VendorTypeId = VT.VendorTypeId
		 		  WHERE Vs.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(VendorId) AS totalItems FROM Result)
				SELECT * INTO #TempResultV1 FROM  Result

				SELECT @Count = COUNT(VendorId) FROM #TempResultV1			

				SELECT *, @Count AS NumberOfItems FROM #TempResultV1 ORDER BY  
				CASE WHEN (@SortOrder=1  AND @SortColumn='VendorCode')  THEN VendorCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorCode')  THEN VendorCode END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorEmail')  THEN VendorEmail END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorEmail')  THEN VendorEmail END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='Description')  THEN [Description] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Description')  THEN [Description] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='City')  THEN City END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='City')  THEN City END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='StateOrProvince')  THEN StateOrProvince END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='StateOrProvince')  THEN StateOrProvince END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorPhoneContact')  THEN VendorPhoneContact END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorPhoneContact')  THEN VendorPhoneContact END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='ClassificationName')  THEN ClassificationName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ClassificationName')  THEN ClassificationName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC	
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
			ELSE IF (@TypeId = 2)
			BEGIN
				;WITH Result AS (
				SELECT DISTINCT Vs.Migrated_Id VendorId,
					Vs.Migrated_Id,
					2 ModuleId,
                    Vs.Company_Name VendorName,
                    Vs.Company_Code VendorCode,                   
					VT.[Description] [Description],  
                    Vs.Email_Address VendorEmail,               
					(ISNULL(Vs.City,'')) 'City',
                    (ISNULL(Vs.State, '')) 'StateOrProvince',
					(ISNULL(Vs.Contact_Name, '')) 'VendorPhoneContact',                   
                    Vs.CreatedDate,
                    0 IsDeleted,
					1 IsActive,
					ISNULL(CD.DESCRIPTION, '') 'ClassificationName',
					SuccessMsg,
					ErrorMsg
				FROM [Quantum_Staging].dbo.Vendors Vs WITH (NOLOCK)
				LEFT JOIN [Quantum].QCTL_NEW_3.CLASS_CODES CD ON CD.CLC_AUTO_KEY = Vs.CustomerClassCodeId
				LEFT JOIN dbo.Vendor V WITH (NOLOCK) ON V.VendorId = Vs.Migrated_Id
				LEFT JOIN dbo.VendorType VT WITH (NOLOCK) ON V.VendorTypeId = VT.VendorTypeId
		 		  WHERE Vs.Migrated_Id IS NOT NULL AND Vs.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(VendorId) AS totalItems FROM Result)
				SELECT * INTO #TempResultV2 FROM  Result

				SELECT @Count = COUNT(VendorId) FROM #TempResultV2			

				SELECT *, @Count AS NumberOfItems FROM #TempResultV2 ORDER BY  
				CASE WHEN (@SortOrder=1  AND @SortColumn='VendorCode')  THEN VendorCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorCode')  THEN VendorCode END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorEmail')  THEN VendorEmail END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorEmail')  THEN VendorEmail END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='Description')  THEN [Description] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Description')  THEN [Description] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='City')  THEN City END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='City')  THEN City END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='StateOrProvince')  THEN StateOrProvince END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='StateOrProvince')  THEN StateOrProvince END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorPhoneContact')  THEN VendorPhoneContact END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorPhoneContact')  THEN VendorPhoneContact END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='ClassificationName')  THEN ClassificationName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ClassificationName')  THEN ClassificationName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC	
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
			ELSE IF (@TypeId = 3)
			BEGIN
				;WITH Result AS (
				SELECT DISTINCT Vs.VendorId,
					Vs.Migrated_Id,
                    Vs.Company_Name VendorName,
                    Vs.Company_Code VendorCode,                   
					VT.[Description] [Description],  
                    Vs.Email_Address VendorEmail,               
					(ISNULL(Vs.City,'')) 'City',
                    (ISNULL(Vs.State, '')) 'StateOrProvince',
					(ISNULL(Vs.Contact_Name, '')) 'VendorPhoneContact',                   
                    Vs.CreatedDate,
                    0 IsDeleted,
					1 IsActive,
					ISNULL(CD.DESCRIPTION, '') 'ClassificationName',
					SuccessMsg,
					ErrorMsg
				FROM [Quantum_Staging].dbo.Vendors Vs WITH (NOLOCK)
				LEFT JOIN [Quantum].QCTL_NEW_3.CLASS_CODES CD ON CD.CLC_AUTO_KEY = Vs.CustomerClassCodeId
				LEFT JOIN dbo.Vendor V WITH (NOLOCK) ON V.VendorId = Vs.Migrated_Id
				LEFT JOIN dbo.VendorType VT WITH (NOLOCK) ON V.VendorTypeId = VT.VendorTypeId
		 		  WHERE Vs.Migrated_Id IS NULL AND (Vs.ErrorMsg IS NOT NULL AND Vs.ErrorMsg NOT like '%Vendor already exists%') AND Vs.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(VendorId) AS totalItems FROM Result)
				SELECT * INTO #TempResultV3 FROM  Result

				SELECT @Count = COUNT(VendorId) FROM #TempResultV3

				SELECT *, @Count AS NumberOfItems FROM #TempResultV3 ORDER BY  
				CASE WHEN (@SortOrder=1  AND @SortColumn='VendorCode')  THEN VendorCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorCode')  THEN VendorCode END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorEmail')  THEN VendorEmail END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorEmail')  THEN VendorEmail END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='Description')  THEN [Description] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Description')  THEN [Description] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='City')  THEN City END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='City')  THEN City END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='StateOrProvince')  THEN StateOrProvince END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='StateOrProvince')  THEN StateOrProvince END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorPhoneContact')  THEN VendorPhoneContact END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorPhoneContact')  THEN VendorPhoneContact END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='ClassificationName')  THEN ClassificationName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ClassificationName')  THEN ClassificationName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC	
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
			ELSE IF (@TypeId = 4)
			BEGIN
				;WITH Result AS (
				SELECT DISTINCT Vs.VendorId,
					Vs.Migrated_Id,
                    Vs.Company_Name VendorName,
                    Vs.Company_Code VendorCode,                   
					VT.[Description] [Description],  
                    Vs.Email_Address VendorEmail,               
					(ISNULL(Vs.City,'')) 'City',
                    (ISNULL(Vs.State, '')) 'StateOrProvince',
					(ISNULL(Vs.Contact_Name, '')) 'VendorPhoneContact',                   
                    Vs.CreatedDate,
                    0 IsDeleted,
					1 IsActive,
					ISNULL(CD.DESCRIPTION, '') 'ClassificationName',
					SuccessMsg,
					ErrorMsg
				FROM [Quantum_Staging].dbo.Vendors Vs WITH (NOLOCK)
				LEFT JOIN [Quantum].QCTL_NEW_3.CLASS_CODES CD ON CD.CLC_AUTO_KEY = Vs.CustomerClassCodeId
				LEFT JOIN dbo.Vendor V WITH (NOLOCK) ON V.VendorId = Vs.Migrated_Id
				LEFT JOIN dbo.VendorType VT WITH (NOLOCK) ON V.VendorTypeId = VT.VendorTypeId
		 		  WHERE Vs.Migrated_Id IS NULL AND (Vs.ErrorMsg IS NOT NULL AND Vs.ErrorMsg like '%Vendor already exists%') AND Vs.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(VendorId) AS totalItems FROM Result)
				SELECT * INTO #TempResultV4 FROM  Result

				SELECT @Count = COUNT(VendorId) FROM #TempResultV4			

				SELECT *, @Count AS NumberOfItems FROM #TempResultV4 ORDER BY  
				CASE WHEN (@SortOrder=1  AND @SortColumn='VendorCode')  THEN VendorCode END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorCode')  THEN VendorCode END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorEmail')  THEN VendorEmail END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorEmail')  THEN VendorEmail END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='Description')  THEN [Description] END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Description')  THEN [Description] END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='City')  THEN City END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='City')  THEN City END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='StateOrProvince')  THEN StateOrProvince END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='StateOrProvince')  THEN StateOrProvince END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='VendorPhoneContact')  THEN VendorPhoneContact END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorPhoneContact')  THEN VendorPhoneContact END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='ClassificationName')  THEN ClassificationName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ClassificationName')  THEN ClassificationName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC	
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
		END
		ELSE IF (@ModuleName = 'ItemMaster')
		BEGIN
			IF (@TypeId = 1)
			BEGIN
				;WITH Result AS (
				SELECT DISTINCT 
					IMs.Migrated_Id,
					IMs.ItemMasterId,
					IMs.PartNumber,
					IMs.PartDescription,
					(ISNULL(mf.Name,'')) 'Manufacturerdesc',
					ic.Description 'Classificationdesc',
					(ISNULL(ig.ItemGroupCode,'')) 'ItemGroup',
					'' AS NationalStockNumber,	
					CASE WHEN IMs.IsSerialized = 'T' THEN 'Yes' ELSE 'No' END AS IsSerialized,
					CASE WHEN IMs.IsTimeLife = 'T' THEN 'Yes' ELSE 'No' END AS IsTimeLife,
					CASE WHEN IMs.IsActive = 'T' THEN 1 ELSE 0 END AS IsActive,
					'Stock' AS ItemType,					   
					CASE WHEN IMs.Hazard_Material = 'T' THEN 'Yes' ELSE 'No' END AS 'IsHazardousMaterial',
					StockType = (CASE WHEN IMs.PMA_Flag = 'T' AND IMs.DER_Flag = 'T' THEN 'PMA&DER'
										WHEN IMs.PMA_Flag = 'T' AND IMs.DER_Flag = 'F' THEN 'PMA' 
										WHEN IMs.PMA_Flag = 'F' AND IMs.DER_Flag = 'T'  THEN 'DER' 
										ELSE 'OEM'
								END),                       
					IMs.Date_Created AS CreatedDate,
					'' AS CreatedBy,
					'' AS UpdatedBy,	
					0 AS IsDeleted,
					SuccessMsg,
					ErrorMsg
				FROM [Quantum_Staging].dbo.ItemMasters IMs WITH (NOLOCK)
				LEFT JOIN dbo.ItemClassification ic ON IMs.ItemClassificationId = ic.ItemClassificationId
				LEFT JOIN dbo.ItemGroup ig ON IMs.ItemGroupId = ig.ItemGroupId
				LEFT JOIN dbo.ItemMaster im ON IMs.Migrated_Id = im.ItemMasterId
				LEFT JOIN dbo.Manufacturer mf ON im.ManufacturerId = mf.ManufacturerId
		 		  WHERE IMs.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(ItemMasterId) AS totalItems FROM Result)
				SELECT * INTO #TempResult FROM  Result

				SELECT @Count = COUNT(ItemMasterId) FROM #TempResult			

				SELECT *, @Count AS NumberOfItems FROM #TempResult ORDER BY  
				CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PartNumber')  THEN PartNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
				CASE WHEN (@SortOrder = 1 AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
				CASE WHEN (@SortOrder = 1 AND @SortColumn='Manufacturerdesc')  THEN Manufacturerdesc END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturerdesc')  THEN Manufacturerdesc END DESC,			
				CASE WHEN (@SortOrder=1  AND @SortColumn='Classificationdesc')  THEN Classificationdesc END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Classificationdesc')  THEN Classificationdesc END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='ItemGroup')  THEN ItemGroup END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemGroup')  THEN ItemGroup END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='NationalStockNumber')  THEN NationalStockNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='NationalStockNumber')  THEN NationalStockNumber END DESC, 			
				CASE WHEN (@SortOrder=1  AND @SortColumn='IsSerialized')  THEN IsSerialized END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='IsSerialized')  THEN IsSerialized END DESC, 
				CASE WHEN (@SortOrder=1  AND @SortColumn='IsTimeLife')  THEN IsTimeLife END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTimeLife')  THEN IsTimeLife END DESC,	
				CASE WHEN (@SortOrder=1  AND @SortColumn='ItemType')  THEN ItemType END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemType')  THEN ItemType END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='StockType')  THEN StockType END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='StockType')  THEN StockType END DESC,			
				CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC		
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
			ELSE IF (@TypeId = 2)
			BEGIN
				;WITH Result AS (
				SELECT DISTINCT IMs.Migrated_Id ItemMasterId,
					IMs.Migrated_Id,
					20 ModuleId,
					IMs.PartNumber,
					IMs.PartDescription,
					(ISNULL(mf.Name,'')) 'Manufacturerdesc',
					ic.Description 'Classificationdesc',
					(ISNULL(ig.ItemGroupCode,'')) 'ItemGroup',
					'' AS NationalStockNumber,	
					CASE WHEN IMs.IsSerialized = 'T' THEN 'Yes' ELSE 'No' END AS IsSerialized,
					CASE WHEN IMs.IsTimeLife = 'T' THEN 'Yes' ELSE 'No' END AS IsTimeLife,
					CASE WHEN IMs.IsActive = 'T' THEN 1 ELSE 0 END AS IsActive,
					'Stock' AS ItemType,					   
					CASE WHEN IMs.Hazard_Material = 'T' THEN 'Yes' ELSE 'No' END AS 'IsHazardousMaterial',
					StockType = (CASE WHEN IMs.PMA_Flag = 'T' AND IMs.DER_Flag = 'T' THEN 'PMA&DER'
										WHEN IMs.PMA_Flag = 'T' AND IMs.DER_Flag = 'F' THEN 'PMA' 
										WHEN IMs.PMA_Flag = 'F' AND IMs.DER_Flag = 'T'  THEN 'DER' 
										ELSE 'OEM'
								END),                       
					IMs.Date_Created AS CreatedDate,
					'' AS CreatedBy,
					'' AS UpdatedBy,	
					0 AS IsDeleted,
					SuccessMsg,
					ErrorMsg
				FROM [Quantum_Staging].dbo.ItemMasters IMs WITH (NOLOCK)
				LEFT JOIN dbo.ItemClassification ic ON IMs.ItemClassificationId = ic.ItemClassificationId
				LEFT JOIN dbo.ItemGroup ig ON IMs.ItemGroupId = ig.ItemGroupId
				LEFT JOIN dbo.ItemMaster im ON IMs.Migrated_Id = im.ItemMasterId
				LEFT JOIN dbo.Manufacturer mf ON im.ManufacturerId = mf.ManufacturerId
		 		  WHERE IMs.Migrated_Id IS NOT NULL AND IMs.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(ItemMasterId) AS totalItems FROM Result)
				SELECT * INTO #TempResult1 FROM  Result

				SELECT @Count = COUNT(ItemMasterId) FROM #TempResult1			

				SELECT *, @Count AS NumberOfItems FROM #TempResult1 ORDER BY  
				CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PartNumber')  THEN PartNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
				CASE WHEN (@SortOrder = 1 AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
				CASE WHEN (@SortOrder = 1 AND @SortColumn='Manufacturerdesc')  THEN Manufacturerdesc END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturerdesc')  THEN Manufacturerdesc END DESC,			
				CASE WHEN (@SortOrder=1  AND @SortColumn='Classificationdesc')  THEN Classificationdesc END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Classificationdesc')  THEN Classificationdesc END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='ItemGroup')  THEN ItemGroup END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemGroup')  THEN ItemGroup END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='NationalStockNumber')  THEN NationalStockNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='NationalStockNumber')  THEN NationalStockNumber END DESC, 			
				CASE WHEN (@SortOrder=1  AND @SortColumn='IsSerialized')  THEN IsSerialized END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='IsSerialized')  THEN IsSerialized END DESC, 
				CASE WHEN (@SortOrder=1  AND @SortColumn='IsTimeLife')  THEN IsTimeLife END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTimeLife')  THEN IsTimeLife END DESC,	
				CASE WHEN (@SortOrder=1  AND @SortColumn='ItemType')  THEN ItemType END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemType')  THEN ItemType END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='StockType')  THEN StockType END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='StockType')  THEN StockType END DESC,			
				CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC		
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
			ELSE IF (@TypeId = 3)
			BEGIN
				;WITH Result AS (
				SELECT DISTINCT IMs.ItemMasterId,
					IMs.Migrated_Id,
					IMs.PartNumber,
					IMs.PartDescription,
					(ISNULL(mf.Name,'')) 'Manufacturerdesc',
					ic.Description 'Classificationdesc',
					(ISNULL(ig.ItemGroupCode,'')) 'ItemGroup',
					'' AS NationalStockNumber,	
					CASE WHEN IMs.IsSerialized = 'T' THEN 'Yes' ELSE 'No' END AS IsSerialized,
					CASE WHEN IMs.IsTimeLife = 'T' THEN 'Yes' ELSE 'No' END AS IsTimeLife,
					CASE WHEN IMs.IsActive = 'T' THEN 1 ELSE 0 END AS IsActive,
					'Stock' AS ItemType,					   
					CASE WHEN IMs.Hazard_Material = 'T' THEN 'Yes' ELSE 'No' END AS 'IsHazardousMaterial',
					StockType = (CASE WHEN IMs.PMA_Flag = 'T' AND IMs.DER_Flag = 'T' THEN 'PMA&DER'
										WHEN IMs.PMA_Flag = 'T' AND IMs.DER_Flag = 'F' THEN 'PMA' 
										WHEN IMs.PMA_Flag = 'F' AND IMs.DER_Flag = 'T'  THEN 'DER' 
										ELSE 'OEM'
								END),                       
					IMs.Date_Created AS CreatedDate,
					'' AS CreatedBy,
					'' AS UpdatedBy,	
					0 AS IsDeleted,
					SuccessMsg,
					ErrorMsg
				FROM [Quantum_Staging].dbo.ItemMasters IMs WITH (NOLOCK)
				LEFT JOIN dbo.ItemClassification ic ON IMs.ItemClassificationId = ic.ItemClassificationId
				LEFT JOIN dbo.ItemGroup ig ON IMs.ItemGroupId = ig.ItemGroupId
				LEFT JOIN dbo.ItemMaster im ON IMs.Migrated_Id = im.ItemMasterId
				LEFT JOIN dbo.Manufacturer mf ON im.ManufacturerId = mf.ManufacturerId
		 		  WHERE IMs.Migrated_Id IS NULL AND (IMs.ErrorMsg IS NOT NULL AND IMs.ErrorMsg NOT like '%Item Master record already exists%') AND IMs.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(ItemMasterId) AS totalItems FROM Result)
				SELECT * INTO #TempResult2 FROM  Result

				SELECT @Count = COUNT(ItemMasterId) FROM #TempResult2			

				SELECT *, @Count AS NumberOfItems FROM #TempResult2 ORDER BY  
				CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PartNumber')  THEN PartNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
				CASE WHEN (@SortOrder = 1 AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
				CASE WHEN (@SortOrder = 1 AND @SortColumn='Manufacturerdesc')  THEN Manufacturerdesc END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturerdesc')  THEN Manufacturerdesc END DESC,			
				CASE WHEN (@SortOrder=1  AND @SortColumn='Classificationdesc')  THEN Classificationdesc END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Classificationdesc')  THEN Classificationdesc END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='ItemGroup')  THEN ItemGroup END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemGroup')  THEN ItemGroup END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='NationalStockNumber')  THEN NationalStockNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='NationalStockNumber')  THEN NationalStockNumber END DESC, 			
				CASE WHEN (@SortOrder=1  AND @SortColumn='IsSerialized')  THEN IsSerialized END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='IsSerialized')  THEN IsSerialized END DESC, 
				CASE WHEN (@SortOrder=1  AND @SortColumn='IsTimeLife')  THEN IsTimeLife END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTimeLife')  THEN IsTimeLife END DESC,	
				CASE WHEN (@SortOrder=1  AND @SortColumn='ItemType')  THEN ItemType END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemType')  THEN ItemType END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='StockType')  THEN StockType END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='StockType')  THEN StockType END DESC,			
				CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC		
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
			ELSE IF (@TypeId = 4)
			BEGIN
				;WITH Result AS (
				SELECT DISTINCT IMs.ItemMasterId,
					IMs.Migrated_Id,
					IMs.PartNumber,
					IMs.PartDescription,
					(ISNULL(mf.Name,'')) 'Manufacturerdesc',
					ic.Description 'Classificationdesc',
					(ISNULL(ig.ItemGroupCode,'')) 'ItemGroup',
					'' AS NationalStockNumber,	
					CASE WHEN IMs.IsSerialized = 'T' THEN 'Yes' ELSE 'No' END AS IsSerialized,
					CASE WHEN IMs.IsTimeLife = 'T' THEN 'Yes' ELSE 'No' END AS IsTimeLife,
					CASE WHEN IMs.IsActive = 'T' THEN 1 ELSE 0 END AS IsActive,
					'Stock' AS ItemType,					   
					CASE WHEN IMs.Hazard_Material = 'T' THEN 'Yes' ELSE 'No' END AS 'IsHazardousMaterial',
					StockType = (CASE WHEN IMs.PMA_Flag = 'T' AND IMs.DER_Flag = 'T' THEN 'PMA&DER'
										WHEN IMs.PMA_Flag = 'T' AND IMs.DER_Flag = 'F' THEN 'PMA' 
										WHEN IMs.PMA_Flag = 'F' AND IMs.DER_Flag = 'T'  THEN 'DER' 
										ELSE 'OEM'
								END),                       
					IMs.Date_Created AS CreatedDate,
					'' AS CreatedBy,
					'' AS UpdatedBy,	
					0 AS IsDeleted,
					SuccessMsg,
					ErrorMsg
				FROM [Quantum_Staging].dbo.ItemMasters IMs WITH (NOLOCK)
				LEFT JOIN dbo.ItemClassification ic ON IMs.ItemClassificationId = ic.ItemClassificationId
				LEFT JOIN dbo.ItemGroup ig ON IMs.ItemGroupId = ig.ItemGroupId
				LEFT JOIN dbo.ItemMaster im ON IMs.Migrated_Id = im.ItemMasterId
				LEFT JOIN dbo.Manufacturer mf ON im.ManufacturerId = mf.ManufacturerId
		 		  WHERE IMs.Migrated_Id IS NULL AND (IMs.ErrorMsg IS NOT NULL AND IMs.ErrorMsg like '%Item Master record already exists%') AND IMs.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(ItemMasterId) AS totalItems FROM Result)
				SELECT * INTO #TempResult3 FROM  Result

				SELECT @Count = COUNT(ItemMasterId) FROM #TempResult3			

				SELECT *, @Count AS NumberOfItems FROM #TempResult3 ORDER BY  
				CASE WHEN (@SortOrder = 1 AND @SortColumn = 'PartNumber')  THEN PartNumber END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
				CASE WHEN (@SortOrder = 1 AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
				CASE WHEN (@SortOrder = -1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
				CASE WHEN (@SortOrder = 1 AND @SortColumn='Manufacturerdesc')  THEN Manufacturerdesc END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturerdesc')  THEN Manufacturerdesc END DESC,			
				CASE WHEN (@SortOrder=1  AND @SortColumn='Classificationdesc')  THEN Classificationdesc END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Classificationdesc')  THEN Classificationdesc END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='ItemGroup')  THEN ItemGroup END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemGroup')  THEN ItemGroup END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='NationalStockNumber')  THEN NationalStockNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='NationalStockNumber')  THEN NationalStockNumber END DESC, 			
				CASE WHEN (@SortOrder=1  AND @SortColumn='IsSerialized')  THEN IsSerialized END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='IsSerialized')  THEN IsSerialized END DESC, 
				CASE WHEN (@SortOrder=1  AND @SortColumn='IsTimeLife')  THEN IsTimeLife END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTimeLife')  THEN IsTimeLife END DESC,	
				CASE WHEN (@SortOrder=1  AND @SortColumn='ItemType')  THEN ItemType END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemType')  THEN ItemType END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='StockType')  THEN StockType END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='StockType')  THEN StockType END DESC,			
				CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC		
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
		END
		ELSE IF (@ModuleName = 'Stockline')
		BEGIN
			IF (@TypeId = 1)
			BEGIN
				;WITH Result AS (
				SELECT DISTINCT Stks.StockLineId,
					Stks.Migrated_Id,
					(ISNULL(im.ItemMasterId,0)) 'ItemMasterId',        
					(ISNULL(im.PartNumber,'')) 'MainPartNumber',        
					(ISNULL(im.PartDescription,'')) 'PartDescription',        
					(ISNULL(mf.Name,'')) 'Manufacturer',          
					(ISNULL(rPart.PartNumber,'')) 'RevisedPN',                  
					(ISNULL(ig.Description,'')) 'ItemGroup',         
					(ISNULL(uom.ShortName,'')) 'UnitOfMeasure',        
					CAST(Stks.Qty_OH AS varchar) 'QuantityOnHand',        
					Stks.Qty_OH  as QuantityOnHandnew,        
					CAST(Stks.Qty_Available AS varchar) 'QuantityAvailable',        
					Stks.Qty_Available  as QuantityAvailablenew,        
					CAST(Stks.Qty_Reserved AS varchar) 'QuantityReserved',        
					Stks.Qty_Reserved  as QuantityReservednew,        
					CASE WHEN Stks.SerialNumber IS NOT NULL THEN (CASE WHEN ISNULL(Stks.SerialNumber,'') = '' THEN 'Non Provided' ELSE ISNULL(Stks.SerialNumber,'') END) ELSE ISNULL(Stks.SerialNumber,'') END AS 'SerialNumber',        
					CASE WHEN ISNULL(Stks.IsCustomerOwned, 0) = 1 AND ISNULL(Stks.Qty_Available, 0) > 0 THEN 1 ELSE (CASE WHEN ISNULL(Stks.customerId,0) > 0 AND ISNULL(Stks.Qty_Available, 0) > 0 THEN 1 ELSE 0 END) END AS 'IsAllowCreateWO',     
					(ISNULL(Stks.StockLineNumber,'')) 'StocklineNumber',         
					Stks.Ctrl_Number ControlNumber,        
					Stks.Ctrl_ID IdNumber,        
					(ISNULL(cond.Description,'')) 'Condition',                 
					(ISNULL(Stks.RecDate,'')) 'ReceivedDate',        
					'' AS 'AWB',               
					Stks.ExpirationDate 'ExpirationDate',        
					Stks.TagDate 'TagDate',        
					(ISNULL(Stks.TaggedBy,'')) 'TaggedByName',        
					'' AS 'TagType',         
					'' AS 'TraceableToName',                
					'' AS 'ItemCategory',         
					im_mg.ItemTypeId,        
					1 AS IsActive,                             
					Stks.Date_Created AS CreatedDate,        
					'' AS CreatedBy,        
					Stks.PartCertNumber PartCertificationNumber,        
					'' AS CertifiedBy,        
					NULL AS CertifiedDate,        
					'' AS UpdatedBy,        
					'' AS CompanyName,        
					'' AS BuName,        
					'' AS DivName,        
					'' AS DeptName,         
					CASE WHEN Stks.IsCustomerOwned = 1 THEN 'Yes' ELSE 'No' END AS IsCustomerStock,        
					CASE WHEN ISNULL(NULL, 0) =  0 THEN 'No' ELSE 'Yes' END AS IsTimeLife,        
					'' AS obtainFrom,
					Stks.[Owner] AS ownerName,
					'' LastMSLevel,
					'' AllMSlevels,
					0 WorkOrderId,
					0 SubWorkOrderId,
					'' WorkOrderNumber,
					loc.[Name] AS [Location],      
					Stks.LocationId,    
					'' LotNumber,
					ISNULL(Stks.CustomerId,0) as CustomerId,    
					'' AS WorkOrderStage,        
					'' as WorkOrderStatus,        
					0 as rsworkOrderId,
					Stks.SuccessMsg,
					Stks.ErrorMsg
				FROM [Quantum_Staging].dbo.Stocklines Stks WITH (NOLOCK)
				LEFT JOIN [Quantum_Staging].dbo.ItemMasters im WITH (NOLOCK) ON Stks.ItemMasterId = im.ItemMasterId       
				LEFT JOIN dbo.ItemMaster im_mg WITH (NOLOCK) ON im_mg.ItemMasterId = im.Migrated_Id
				LEFT JOIN dbo.ItemGroup ig WITH (NOLOCK) ON ig.ItemGroupId = im.ItemGroupId
				LEFT JOIN dbo.UnitOfMeasure uom WITH (NOLOCK) ON uom.UnitOfMeasureId = im_mg.PurchaseUnitOfMeasureId
				LEFT JOIN dbo.Condition cond WITH (NOLOCK) ON cond.ConditionId = Stks.ConditionId
				LEFT JOIN dbo.Manufacturer mf WITH (NOLOCK) ON mf.ManufacturerId = Stks.ManufacturerId         
				LEFT JOIN dbo.[Location] loc WITH (NOLOCK) ON loc.LocationId = Stks.LocationId
				LEFT JOIN dbo.ItemMaster rPart WITH (NOLOCK) ON im_mg.RevisedPartId = rPart.ItemMasterId                  
		 		  WHERE Stks.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(ItemMasterId) AS totalItems FROM Result)
				SELECT * INTO #TempResultS1 FROM  Result

				SELECT @Count = COUNT(ItemMasterId) FROM #TempResultS1			

				SELECT *, @Count AS NumberOfItems FROM #TempResultS1 ORDER BY  
				CASE WHEN (@SortOrder=1  AND @SortColumn='MainPartNumber')  THEN MainPartNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='MainPartNumber')  THEN MainPartNumber END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturer')  THEN Manufacturer END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN Manufacturer END DESC,           
				CASE WHEN (@SortOrder=1  AND @SortColumn='RevisedPN')  THEN RevisedPN END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='RevisedPN')  THEN RevisedPN END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='ItemGroup')  THEN ItemGroup END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemGroup')  THEN ItemGroup END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END DESC,            
				CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityAvailable')  THEN QuantityAvailablenew END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityAvailable')  THEN QuantityAvailablenew END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityReserved')  THEN QuantityReservednew END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityReserved')  THEN QuantityReservednew END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNumber')  THEN SerialNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber')  THEN SerialNumber END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineNumber')  THEN StocklineNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineNumber')  THEN StocklineNumber END DESC,           
				CASE WHEN (@SortOrder=1  AND @SortColumn='ControlNumber')  THEN ControlNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNumber')  THEN ControlNumber END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='TaggedByName')  THEN TaggedByName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='TaggedByName')  THEN TaggedByName END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='TagType')  THEN TagType END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='TagType')  THEN TagType END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='TraceableToName')  THEN TraceableToName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='TraceableToName')  THEN TraceableToName END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='IdNumber')  THEN IdNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='IdNumber')  THEN IdNumber END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='ReceivedDate')  THEN ReceivedDate END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceivedDate')  THEN ReceivedDate END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='ExpirationDate')  THEN ExpirationDate END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ExpirationDate')  THEN ExpirationDate END DESC,           
				CASE WHEN (@SortOrder=1  AND @SortColumn='TagDate')  THEN TagDate END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='TagDate')  THEN TagDate END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='ItemCategory')  THEN ItemCategory END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemCategory')  THEN ItemCategory END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='CompanyName')  THEN CompanyName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CompanyName')  THEN CompanyName END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='BuName')  THEN BuName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='BuName')  THEN BuName END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='DivName')  THEN DivName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='DivName')  THEN DivName END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='DeptName')  THEN DeptName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='DeptName')  THEN DeptName END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartCertificationNumber')  THEN PartCertificationNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartCertificationNumber')  THEN PartCertificationNumber END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='CertifiedBy')  THEN CertifiedBy END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedBy')  THEN CertifiedBy END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='CertifiedDate')  THEN CertifiedDate END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedDate')  THEN CertifiedDate END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='IsCustomerStock')  THEN IsCustomerStock END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='IsCustomerStock')  THEN IsCustomerStock END DESC,             
				CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,             
				CASE WHEN (@SortOrder=1  AND @SortColumn='obtainFrom')  THEN obtainFrom END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='obtainFrom')  THEN obtainFrom END DESC,              
				CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderStage')  THEN WorkOrderStage END ASC,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderStage')  THEN WorkOrderStage END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='ownerName')  THEN ownerName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ownerName')  THEN ownerName END DESC,    
				CASE WHEN (@SortOrder=1  AND @SortColumn='Location')  THEN Location END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Location')  THEN Location END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='IsTimeLife')  THEN IsTimeLife END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTimeLife')  THEN IsTimeLife END DESC	
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
			ELSE IF (@TypeId = 2)
			BEGIN
				;WITH Result AS (
				SELECT DISTINCT Stks.Migrated_Id StockLineId,
					Stks.Migrated_Id,
					22 ModuleId,
					(ISNULL(im.ItemMasterId,0)) 'ItemMasterId',        
					(ISNULL(im.PartNumber,'')) 'MainPartNumber',        
					(ISNULL(im.PartDescription,'')) 'PartDescription',        
					(ISNULL(mf.Name,'')) 'Manufacturer',          
					(ISNULL(rPart.PartNumber,'')) 'RevisedPN',                  
					(ISNULL(ig.Description,'')) 'ItemGroup',         
					(ISNULL(uom.ShortName,'')) 'UnitOfMeasure',        
					CAST(Stks.Qty_OH AS varchar) 'QuantityOnHand',        
					Stks.Qty_OH  as QuantityOnHandnew,        
					CAST(Stks.Qty_Available AS varchar) 'QuantityAvailable',        
					Stks.Qty_Available  as QuantityAvailablenew,        
					CAST(Stks.Qty_Reserved AS varchar) 'QuantityReserved',        
					Stks.Qty_Reserved  as QuantityReservednew,        
					CASE WHEN Stks.SerialNumber IS NOT NULL THEN (CASE WHEN ISNULL(Stks.SerialNumber,'') = '' THEN 'Non Provided' ELSE ISNULL(Stks.SerialNumber,'') END) ELSE ISNULL(Stks.SerialNumber,'') END AS 'SerialNumber',        
					CASE WHEN ISNULL(Stks.IsCustomerOwned, 0) = 1 AND ISNULL(Stks.Qty_Available, 0) > 0 THEN 1 ELSE (CASE WHEN ISNULL(Stks.customerId,0) > 0 AND ISNULL(Stks.Qty_Available, 0) > 0 THEN 1 ELSE 0 END) END AS 'IsAllowCreateWO',     
					(ISNULL(Stks.StockLineNumber,'')) 'StocklineNumber',         
					Stks.Ctrl_Number ControlNumber,        
					Stks.Ctrl_ID IdNumber,        
					(ISNULL(cond.Description,'')) 'Condition',                 
					(ISNULL(Stks.RecDate,'')) 'ReceivedDate',        
					'' AS 'AWB',               
					Stks.ExpirationDate 'ExpirationDate',        
					Stks.TagDate 'TagDate',        
					(ISNULL(Stks.TaggedBy,'')) 'TaggedByName',        
					'' AS 'TagType',         
					'' AS 'TraceableToName',                
					'' AS 'ItemCategory',         
					im_mg.ItemTypeId,        
					1 AS IsActive,                             
					Stks.Date_Created AS CreatedDate,        
					'' AS CreatedBy,        
					Stks.PartCertNumber PartCertificationNumber,        
					'' AS CertifiedBy,        
					NULL AS CertifiedDate,        
					'' AS UpdatedBy,        
					'' AS CompanyName,        
					'' AS BuName,        
					'' AS DivName,        
					'' AS DeptName,         
					CASE WHEN Stks.IsCustomerOwned = 1 THEN 'Yes' ELSE 'No' END AS IsCustomerStock,        
					CASE WHEN ISNULL(NULL, 0) =  0 THEN 'No' ELSE 'Yes' END AS IsTimeLife,        
					'' AS obtainFrom,
					Stks.[Owner] AS ownerName,
					'' LastMSLevel,
					'' AllMSlevels,
					0 WorkOrderId,
					0 SubWorkOrderId,
					'' WorkOrderNumber,
					loc.[Name] AS [Location],      
					Stks.LocationId,    
					'' LotNumber,
					ISNULL(Stks.CustomerId,0) as CustomerId,    
					'' AS WorkOrderStage,        
					'' as WorkOrderStatus,        
					0 as rsworkOrderId,
					Stks.SuccessMsg,
					Stks.ErrorMsg
				FROM [Quantum_Staging].dbo.Stocklines Stks WITH (NOLOCK)
				LEFT JOIN [Quantum_Staging].dbo.ItemMasters im WITH (NOLOCK) ON Stks.ItemMasterId = im.ItemMasterId         
				LEFT JOIN dbo.ItemMaster im_mg WITH (NOLOCK) ON im_mg.ItemMasterId = im.Migrated_Id         
				LEFT JOIN dbo.ItemGroup ig WITH (NOLOCK) ON ig.ItemGroupId = im.ItemGroupId
				LEFT JOIN dbo.UnitOfMeasure uom WITH (NOLOCK) ON uom.UnitOfMeasureId = im_mg.PurchaseUnitOfMeasureId
				LEFT JOIN dbo.Condition cond WITH (NOLOCK) ON cond.ConditionId = Stks.ConditionId
				LEFT JOIN dbo.Manufacturer mf WITH (NOLOCK) ON mf.ManufacturerId = Stks.ManufacturerId         
				LEFT JOIN dbo.[Location] loc WITH (NOLOCK) ON loc.LocationId = Stks.LocationId
				LEFT JOIN dbo.ItemMaster rPart WITH (NOLOCK) ON im_mg.RevisedPartId = rPart.ItemMasterId
		 		  WHERE Stks.Migrated_Id IS NOT NULL AND Stks.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(ItemMasterId) AS totalItems FROM Result)
				SELECT * INTO #TempResultS2 FROM  Result

				SELECT @Count = COUNT(ItemMasterId) FROM #TempResultS2

				SELECT *, @Count AS NumberOfItems FROM #TempResultS2 ORDER BY  
				CASE WHEN (@SortOrder=1  AND @SortColumn='MainPartNumber')  THEN MainPartNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='MainPartNumber')  THEN MainPartNumber END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturer')  THEN Manufacturer END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN Manufacturer END DESC,           
				CASE WHEN (@SortOrder=1  AND @SortColumn='RevisedPN')  THEN RevisedPN END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='RevisedPN')  THEN RevisedPN END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='ItemGroup')  THEN ItemGroup END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemGroup')  THEN ItemGroup END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END DESC,            
				CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityAvailable')  THEN QuantityAvailablenew END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityAvailable')  THEN QuantityAvailablenew END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityReserved')  THEN QuantityReservednew END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityReserved')  THEN QuantityReservednew END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNumber')  THEN SerialNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber')  THEN SerialNumber END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineNumber')  THEN StocklineNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineNumber')  THEN StocklineNumber END DESC,           
				CASE WHEN (@SortOrder=1  AND @SortColumn='ControlNumber')  THEN ControlNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNumber')  THEN ControlNumber END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='TaggedByName')  THEN TaggedByName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='TaggedByName')  THEN TaggedByName END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='TagType')  THEN TagType END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='TagType')  THEN TagType END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='TraceableToName')  THEN TraceableToName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='TraceableToName')  THEN TraceableToName END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='IdNumber')  THEN IdNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='IdNumber')  THEN IdNumber END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='ReceivedDate')  THEN ReceivedDate END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceivedDate')  THEN ReceivedDate END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='ExpirationDate')  THEN ExpirationDate END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ExpirationDate')  THEN ExpirationDate END DESC,           
				CASE WHEN (@SortOrder=1  AND @SortColumn='TagDate')  THEN TagDate END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='TagDate')  THEN TagDate END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='ItemCategory')  THEN ItemCategory END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemCategory')  THEN ItemCategory END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='CompanyName')  THEN CompanyName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CompanyName')  THEN CompanyName END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='BuName')  THEN BuName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='BuName')  THEN BuName END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='DivName')  THEN DivName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='DivName')  THEN DivName END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='DeptName')  THEN DeptName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='DeptName')  THEN DeptName END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartCertificationNumber')  THEN PartCertificationNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartCertificationNumber')  THEN PartCertificationNumber END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='CertifiedBy')  THEN CertifiedBy END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedBy')  THEN CertifiedBy END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='CertifiedDate')  THEN CertifiedDate END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedDate')  THEN CertifiedDate END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='IsCustomerStock')  THEN IsCustomerStock END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='IsCustomerStock')  THEN IsCustomerStock END DESC,             
				CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,             
				CASE WHEN (@SortOrder=1  AND @SortColumn='obtainFrom')  THEN obtainFrom END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='obtainFrom')  THEN obtainFrom END DESC,              
				CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderStage')  THEN WorkOrderStage END ASC,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderStage')  THEN WorkOrderStage END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='ownerName')  THEN ownerName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ownerName')  THEN ownerName END DESC,    
				CASE WHEN (@SortOrder=1  AND @SortColumn='Location')  THEN Location END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Location')  THEN Location END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='IsTimeLife')  THEN IsTimeLife END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTimeLife')  THEN IsTimeLife END DESC
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
			ELSE IF (@TypeId = 3)
			BEGIN
				;WITH Result AS (
				SELECT DISTINCT Stks.StockLineId,    
					Stks.Migrated_Id,
					(ISNULL(im.ItemMasterId,0)) 'ItemMasterId',        
					(ISNULL(im.PartNumber,'')) 'MainPartNumber',        
					(ISNULL(im.PartDescription,'')) 'PartDescription',        
					(ISNULL(mf.Name,'')) 'Manufacturer',          
					(ISNULL(rPart.PartNumber,'')) 'RevisedPN',                  
					(ISNULL(ig.Description,'')) 'ItemGroup',         
					(ISNULL(uom.ShortName,'')) 'UnitOfMeasure',        
					CAST(Stks.Qty_OH AS varchar) 'QuantityOnHand',        
					Stks.Qty_OH  as QuantityOnHandnew,        
					CAST(Stks.Qty_Available AS varchar) 'QuantityAvailable',        
					Stks.Qty_Available  as QuantityAvailablenew,        
					CAST(Stks.Qty_Reserved AS varchar) 'QuantityReserved',        
					Stks.Qty_Reserved  as QuantityReservednew,        
					CASE WHEN Stks.SerialNumber IS NOT NULL THEN (CASE WHEN ISNULL(Stks.SerialNumber,'') = '' THEN 'Non Provided' ELSE ISNULL(Stks.SerialNumber,'') END) ELSE ISNULL(Stks.SerialNumber,'') END AS 'SerialNumber',        
					CASE WHEN ISNULL(Stks.IsCustomerOwned, 0) = 1 AND ISNULL(Stks.Qty_Available, 0) > 0 THEN 1 ELSE (CASE WHEN ISNULL(Stks.customerId,0) > 0 AND ISNULL(Stks.Qty_Available, 0) > 0 THEN 1 ELSE 0 END) END AS 'IsAllowCreateWO',     
					(ISNULL(Stks.StockLineNumber,'')) 'StocklineNumber',         
					Stks.Ctrl_Number ControlNumber,        
					Stks.Ctrl_ID IdNumber,        
					(ISNULL(cond.Description,'')) 'Condition',                 
					(ISNULL(Stks.RecDate,'')) 'ReceivedDate',        
					'' AS 'AWB',               
					Stks.ExpirationDate 'ExpirationDate',        
					Stks.TagDate 'TagDate',        
					(ISNULL(Stks.TaggedBy,'')) 'TaggedByName',        
					'' AS 'TagType',         
					'' AS 'TraceableToName',                
					'' AS 'ItemCategory',         
					im_mg.ItemTypeId,        
					1 AS IsActive,                             
					Stks.Date_Created AS CreatedDate,        
					'' AS CreatedBy,        
					Stks.PartCertNumber PartCertificationNumber,        
					'' AS CertifiedBy,        
					NULL AS CertifiedDate,        
					'' AS UpdatedBy,        
					'' AS CompanyName,        
					'' AS BuName,        
					'' AS DivName,        
					'' AS DeptName,         
					CASE WHEN Stks.IsCustomerOwned = 1 THEN 'Yes' ELSE 'No' END AS IsCustomerStock,        
					CASE WHEN ISNULL(NULL, 0) =  0 THEN 'No' ELSE 'Yes' END AS IsTimeLife,        
					'' AS obtainFrom,
					Stks.[Owner] AS ownerName,
					'' LastMSLevel,
					'' AllMSlevels,
					0 WorkOrderId,
					0 SubWorkOrderId,
					'' WorkOrderNumber,
					loc.[Name] AS [Location],      
					Stks.LocationId,    
					'' LotNumber,
					ISNULL(Stks.CustomerId,0) as CustomerId,    
					'' AS WorkOrderStage,        
					'' as WorkOrderStatus,        
					0 as rsworkOrderId,
					Stks.SuccessMsg,
					Stks.ErrorMsg
				FROM [Quantum_Staging].dbo.Stocklines Stks WITH (NOLOCK)
				LEFT JOIN [Quantum_Staging].dbo.ItemMasters im WITH (NOLOCK) ON Stks.ItemMasterId = im.ItemMasterId         
				LEFT JOIN dbo.ItemMaster im_mg WITH (NOLOCK) ON im_mg.ItemMasterId = im.Migrated_Id         
				LEFT JOIN dbo.ItemGroup ig WITH (NOLOCK) ON ig.ItemGroupId = im.ItemGroupId
				LEFT JOIN dbo.UnitOfMeasure uom WITH (NOLOCK) ON uom.UnitOfMeasureId = im_mg.PurchaseUnitOfMeasureId
				LEFT JOIN dbo.Condition cond WITH (NOLOCK) ON cond.ConditionId = Stks.ConditionId
				LEFT JOIN dbo.Manufacturer mf WITH (NOLOCK) ON mf.ManufacturerId = Stks.ManufacturerId         
				LEFT JOIN dbo.[Location] loc WITH (NOLOCK) ON loc.LocationId = Stks.LocationId
				LEFT JOIN dbo.ItemMaster rPart WITH (NOLOCK) ON im_mg.RevisedPartId = rPart.ItemMasterId
		 		  WHERE Stks.Migrated_Id IS NULL AND (Stks.ErrorMsg IS NOT NULL AND Stks.ErrorMsg NOT like '%Stockline record already exists%') AND Stks.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(ItemMasterId) AS totalItems FROM Result)
				SELECT * INTO #TempResultS3 FROM  Result

				SELECT @Count = COUNT(ItemMasterId) FROM #TempResultS3

				SELECT *, @Count AS NumberOfItems FROM #TempResultS3 ORDER BY  
				CASE WHEN (@SortOrder=1  AND @SortColumn='MainPartNumber')  THEN MainPartNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='MainPartNumber')  THEN MainPartNumber END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturer')  THEN Manufacturer END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN Manufacturer END DESC,           
				CASE WHEN (@SortOrder=1  AND @SortColumn='RevisedPN')  THEN RevisedPN END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='RevisedPN')  THEN RevisedPN END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='ItemGroup')  THEN ItemGroup END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemGroup')  THEN ItemGroup END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END DESC,            
				CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityAvailable')  THEN QuantityAvailablenew END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityAvailable')  THEN QuantityAvailablenew END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityReserved')  THEN QuantityReservednew END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityReserved')  THEN QuantityReservednew END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNumber')  THEN SerialNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber')  THEN SerialNumber END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineNumber')  THEN StocklineNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineNumber')  THEN StocklineNumber END DESC,           
				CASE WHEN (@SortOrder=1  AND @SortColumn='ControlNumber')  THEN ControlNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNumber')  THEN ControlNumber END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='TaggedByName')  THEN TaggedByName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='TaggedByName')  THEN TaggedByName END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='TagType')  THEN TagType END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='TagType')  THEN TagType END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='TraceableToName')  THEN TraceableToName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='TraceableToName')  THEN TraceableToName END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='IdNumber')  THEN IdNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='IdNumber')  THEN IdNumber END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='ReceivedDate')  THEN ReceivedDate END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceivedDate')  THEN ReceivedDate END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='ExpirationDate')  THEN ExpirationDate END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ExpirationDate')  THEN ExpirationDate END DESC,           
				CASE WHEN (@SortOrder=1  AND @SortColumn='TagDate')  THEN TagDate END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='TagDate')  THEN TagDate END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='ItemCategory')  THEN ItemCategory END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemCategory')  THEN ItemCategory END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='CompanyName')  THEN CompanyName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CompanyName')  THEN CompanyName END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='BuName')  THEN BuName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='BuName')  THEN BuName END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='DivName')  THEN DivName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='DivName')  THEN DivName END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='DeptName')  THEN DeptName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='DeptName')  THEN DeptName END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartCertificationNumber')  THEN PartCertificationNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartCertificationNumber')  THEN PartCertificationNumber END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='CertifiedBy')  THEN CertifiedBy END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedBy')  THEN CertifiedBy END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='CertifiedDate')  THEN CertifiedDate END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedDate')  THEN CertifiedDate END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='IsCustomerStock')  THEN IsCustomerStock END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='IsCustomerStock')  THEN IsCustomerStock END DESC,             
				CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,             
				CASE WHEN (@SortOrder=1  AND @SortColumn='obtainFrom')  THEN obtainFrom END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='obtainFrom')  THEN obtainFrom END DESC,              
				CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderStage')  THEN WorkOrderStage END ASC,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderStage')  THEN WorkOrderStage END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='ownerName')  THEN ownerName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ownerName')  THEN ownerName END DESC,    
				CASE WHEN (@SortOrder=1  AND @SortColumn='Location')  THEN Location END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Location')  THEN Location END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='IsTimeLife')  THEN IsTimeLife END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTimeLife')  THEN IsTimeLife END DESC	
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
			ELSE IF (@TypeId = 4)
			BEGIN
				;WITH Result AS (
				SELECT DISTINCT Stks.StockLineId,    
					Stks.Migrated_Id,
					(ISNULL(im.ItemMasterId,0)) 'ItemMasterId',        
					(ISNULL(im.PartNumber,'')) 'MainPartNumber',        
					(ISNULL(im.PartDescription,'')) 'PartDescription',        
					(ISNULL(mf.Name,'')) 'Manufacturer',          
					(ISNULL(rPart.PartNumber,'')) 'RevisedPN',                  
					(ISNULL(ig.Description,'')) 'ItemGroup',         
					(ISNULL(uom.ShortName,'')) 'UnitOfMeasure',        
					CAST(Stks.Qty_OH AS varchar) 'QuantityOnHand',        
					Stks.Qty_OH  as QuantityOnHandnew,        
					CAST(Stks.Qty_Available AS varchar) 'QuantityAvailable',        
					Stks.Qty_Available  as QuantityAvailablenew,        
					CAST(Stks.Qty_Reserved AS varchar) 'QuantityReserved',        
					Stks.Qty_Reserved  as QuantityReservednew,        
					CASE WHEN Stks.SerialNumber IS NOT NULL THEN (CASE WHEN ISNULL(Stks.SerialNumber,'') = '' THEN 'Non Provided' ELSE ISNULL(Stks.SerialNumber,'') END) ELSE ISNULL(Stks.SerialNumber,'') END AS 'SerialNumber',        
					CASE WHEN ISNULL(Stks.IsCustomerOwned, 0) = 1 AND ISNULL(Stks.Qty_Available, 0) > 0 THEN 1 ELSE (CASE WHEN ISNULL(Stks.customerId,0) > 0 AND ISNULL(Stks.Qty_Available, 0) > 0 THEN 1 ELSE 0 END) END AS 'IsAllowCreateWO',     
					(ISNULL(Stks.StockLineNumber,'')) 'StocklineNumber',         
					Stks.Ctrl_Number ControlNumber,        
					Stks.Ctrl_ID IdNumber,        
					(ISNULL(cond.Description,'')) 'Condition',                 
					(ISNULL(Stks.RecDate,'')) 'ReceivedDate',        
					'' AS 'AWB',               
					Stks.ExpirationDate 'ExpirationDate',        
					Stks.TagDate 'TagDate',        
					(ISNULL(Stks.TaggedBy,'')) 'TaggedByName',        
					'' AS 'TagType',         
					'' AS 'TraceableToName',                
					'' AS 'ItemCategory',         
					im_mg.ItemTypeId,        
					1 AS IsActive,                             
					Stks.Date_Created AS CreatedDate,        
					'' AS CreatedBy,        
					Stks.PartCertNumber PartCertificationNumber,        
					'' AS CertifiedBy,        
					NULL AS CertifiedDate,        
					'' AS UpdatedBy,        
					'' AS CompanyName,        
					'' AS BuName,        
					'' AS DivName,        
					'' AS DeptName,         
					CASE WHEN Stks.IsCustomerOwned = 1 THEN 'Yes' ELSE 'No' END AS IsCustomerStock,        
					CASE WHEN ISNULL(NULL, 0) =  0 THEN 'No' ELSE 'Yes' END AS IsTimeLife,        
					'' AS obtainFrom,
					Stks.[Owner] AS ownerName,
					'' LastMSLevel,
					'' AllMSlevels,
					0 WorkOrderId,
					0 SubWorkOrderId,
					'' WorkOrderNumber,
					loc.[Name] AS [Location],      
					Stks.LocationId,    
					'' LotNumber,
					ISNULL(Stks.CustomerId,0) as CustomerId,    
					'' AS WorkOrderStage,        
					'' as WorkOrderStatus,        
					0 as rsworkOrderId,
					Stks.SuccessMsg,
					Stks.ErrorMsg
				FROM [Quantum_Staging].dbo.Stocklines Stks WITH (NOLOCK)
				LEFT JOIN [Quantum_Staging].dbo.ItemMasters im WITH (NOLOCK) ON Stks.ItemMasterId = im.ItemMasterId         
				LEFT JOIN dbo.ItemMaster im_mg WITH (NOLOCK) ON im_mg.ItemMasterId = im.Migrated_Id         
				LEFT JOIN dbo.ItemGroup ig WITH (NOLOCK) ON ig.ItemGroupId = im.ItemGroupId
				LEFT JOIN dbo.UnitOfMeasure uom WITH (NOLOCK) ON uom.UnitOfMeasureId = im_mg.PurchaseUnitOfMeasureId
				LEFT JOIN dbo.Condition cond WITH (NOLOCK) ON cond.ConditionId = Stks.ConditionId
				LEFT JOIN dbo.Manufacturer mf WITH (NOLOCK) ON mf.ManufacturerId = Stks.ManufacturerId         
				LEFT JOIN dbo.[Location] loc WITH (NOLOCK) ON loc.LocationId = Stks.LocationId
				LEFT JOIN dbo.ItemMaster rPart WITH (NOLOCK) ON im_mg.RevisedPartId = rPart.ItemMasterId
		 		  WHERE Stks.Migrated_Id IS NULL AND (Stks.ErrorMsg IS NOT NULL AND Stks.ErrorMsg like '%Stockline record already exists%') AND Stks.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(ItemMasterId) AS totalItems FROM Result)
				SELECT * INTO #TempResultS4 FROM  Result

				SELECT @Count = COUNT(ItemMasterId) FROM #TempResultS4

				SELECT *, @Count AS NumberOfItems FROM #TempResultS4 ORDER BY  
				CASE WHEN (@SortOrder=1  AND @SortColumn='MainPartNumber')  THEN MainPartNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='MainPartNumber')  THEN MainPartNumber END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturer')  THEN Manufacturer END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN Manufacturer END DESC,           
				CASE WHEN (@SortOrder=1  AND @SortColumn='RevisedPN')  THEN RevisedPN END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='RevisedPN')  THEN RevisedPN END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='ItemGroup')  THEN ItemGroup END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemGroup')  THEN ItemGroup END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitOfMeasure')  THEN UnitOfMeasure END DESC,            
				CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityOnHand')  THEN QuantityOnHandnew END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityAvailable')  THEN QuantityAvailablenew END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityAvailable')  THEN QuantityAvailablenew END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='QuantityReserved')  THEN QuantityReservednew END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='QuantityReserved')  THEN QuantityReservednew END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='SerialNumber')  THEN SerialNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNumber')  THEN SerialNumber END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineNumber')  THEN StocklineNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineNumber')  THEN StocklineNumber END DESC,           
				CASE WHEN (@SortOrder=1  AND @SortColumn='ControlNumber')  THEN ControlNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ControlNumber')  THEN ControlNumber END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='TaggedByName')  THEN TaggedByName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='TaggedByName')  THEN TaggedByName END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='TagType')  THEN TagType END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='TagType')  THEN TagType END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='TraceableToName')  THEN TraceableToName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='TraceableToName')  THEN TraceableToName END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='IdNumber')  THEN IdNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='IdNumber')  THEN IdNumber END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='ReceivedDate')  THEN ReceivedDate END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ReceivedDate')  THEN ReceivedDate END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='ExpirationDate')  THEN ExpirationDate END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ExpirationDate')  THEN ExpirationDate END DESC,           
				CASE WHEN (@SortOrder=1  AND @SortColumn='TagDate')  THEN TagDate END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='TagDate')  THEN TagDate END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='ItemCategory')  THEN ItemCategory END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemCategory')  THEN ItemCategory END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='CompanyName')  THEN CompanyName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CompanyName')  THEN CompanyName END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='BuName')  THEN BuName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='BuName')  THEN BuName END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='DivName')  THEN DivName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='DivName')  THEN DivName END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='DeptName')  THEN DeptName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='DeptName')  THEN DeptName END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartCertificationNumber')  THEN PartCertificationNumber END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartCertificationNumber')  THEN PartCertificationNumber END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='CertifiedBy')  THEN CertifiedBy END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedBy')  THEN CertifiedBy END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='CertifiedDate')  THEN CertifiedDate END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CertifiedDate')  THEN CertifiedDate END DESC,         
				CASE WHEN (@SortOrder=1  AND @SortColumn='IsCustomerStock')  THEN IsCustomerStock END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='IsCustomerStock')  THEN IsCustomerStock END DESC,             
				CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,             
				CASE WHEN (@SortOrder=1  AND @SortColumn='obtainFrom')  THEN obtainFrom END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='obtainFrom')  THEN obtainFrom END DESC,              
				CASE WHEN (@SortOrder=1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END ASC,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='LASTMSLEVEL')  THEN LastMSLevel END DESC,        
				CASE WHEN (@SortOrder=1 and @SortColumn='WorkOrderStage')  THEN WorkOrderStage END ASC,        
				CASE WHEN (@SortOrder=-1 and @SortColumn='WorkOrderStage')  THEN WorkOrderStage END DESC,        
				CASE WHEN (@SortOrder=1  AND @SortColumn='ownerName')  THEN ownerName END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='ownerName')  THEN ownerName END DESC,    
				CASE WHEN (@SortOrder=1  AND @SortColumn='Location')  THEN Location END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Location')  THEN Location END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='IsTimeLife')  THEN IsTimeLife END ASC,        
				CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTimeLife')  THEN IsTimeLife END DESC	
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
		END
		ELSE IF (@ModuleName = 'Kit')
		BEGIN
			IF (@TypeId = 1)
			BEGIN
				;WITH Result AS (
				SELECT
					kitm.Migrated_Id KitId,
					kitm.Migrated_Id,
					km.KitNumber KitNumber,
					kitm.MainItemMasterId ItemMasterId,
					im.partnumber PartNumber,
					im.PartDescription PartDescription,
					km.Manufacturer,
					km.CustomerId,
					km.CustomerName AS CustomerName,
					wos.WorkScopeCode AS WorkScopeName,
					km.KitCost,
					kitm.UnitCost AS UnitCost,
					(SELECT ISNULL(COUNT(kimm.KitItemMasterMappingId),0) FROM [dbo].[KitItemMasterMapping] kimm WITH (NOLOCK) WHERE kimm.KitId = km.KitId AND kimm.IsDeleted = 0) AS Qty,
					0 AS StocklineUnitCost,
					1 AS IsActive,
					kitm.Date_Created CreatedDate,
					0 AS IsDeleted,
					SuccessMsg,
					ErrorMsg
				FROM [Quantum_Staging].dbo.[KitMasters] kitm WITH (NOLOCK)
				LEFT JOIN dbo.KitMaster km ON km.KitId = kitm.Migrated_Id
				LEFT JOIN dbo.ItemMaster im ON im.ItemMasterId = kitm.MainItemMasterId
				LEFT JOIN dbo.Manufacturer mf ON km.ManufacturerId = mf.ManufacturerId
				LEFT JOIN [dbo].[WorkScope] wos WITH (NOLOCK) ON km.WorkScopeId = wos.WorkScopeId
		 		  WHERE kitm.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(KitId) AS totalItems FROM Result)
				SELECT * INTO #TempResultKM1 FROM  Result

				SELECT @Count = COUNT(ItemMasterId) FROM #TempResultKM1			

				SELECT *, @Count AS NumberOfItems FROM #TempResultKM1 ORDER BY  
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturer')  THEN Manufacturer END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN Manufacturer END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='KitNumber')  THEN KitNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='KitNumber')  THEN KitNumber END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='WorkScopeName')  THEN WorkScopeName END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkScopeName')  THEN WorkScopeName END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerName')  THEN CustomerName END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName')  THEN CustomerName END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Qty')  THEN Qty END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Qty')  THEN Qty END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='UnitCost')  THEN UnitCost END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN UnitCost END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineUnitCost')  THEN StocklineUnitCost END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineUnitCost')  THEN StocklineUnitCost END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
			ELSE IF (@TypeId = 2)
			BEGIN
				;WITH Result AS (
				SELECT
					kitm.Migrated_Id KitId,
					kitm.Migrated_Id,
					km.KitNumber KitNumber,
					kitm.MainItemMasterId ItemMasterId,
					im.partnumber PartNumber,
					im.PartDescription PartDescription,
					km.Manufacturer,
					km.CustomerId,
					km.CustomerName AS CustomerName,
					wos.WorkScopeCode AS WorkScopeName,
					km.KitCost,
					kitm.UnitCost AS UnitCost,
					(SELECT ISNULL(COUNT(kimm.KitItemMasterMappingId),0) FROM [dbo].[KitItemMasterMapping] kimm WITH (NOLOCK) WHERE kimm.KitId = kitm.Migrated_Id AND kimm.IsDeleted = 0) AS Qty,
					0 AS StocklineUnitCost,
					1 AS IsActive,
					kitm.Date_Created CreatedDate,
					0 AS IsDeleted,
					SuccessMsg,
					ErrorMsg
				FROM [Quantum_Staging].dbo.[KitMasters] kitm WITH (NOLOCK)
				LEFT JOIN dbo.KitMaster km ON km.KitId = kitm.Migrated_Id
				LEFT JOIN dbo.ItemMaster im ON im.ItemMasterId = kitm.MainItemMasterId
				LEFT JOIN dbo.Manufacturer mf ON km.ManufacturerId = mf.ManufacturerId
				LEFT JOIN [dbo].[WorkScope] wos WITH (NOLOCK) ON km.WorkScopeId = wos.WorkScopeId
		 		  WHERE kitm.Migrated_Id IS NOT NULL AND kitm.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(ItemMasterId) AS totalItems FROM Result)
				SELECT * INTO #TempResultKM2 FROM  Result

				SELECT @Count = COUNT(ItemMasterId) FROM #TempResultKM2			

				SELECT *, @Count AS NumberOfItems FROM #TempResultKM2 ORDER BY  
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturer')  THEN Manufacturer END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN Manufacturer END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='KitNumber')  THEN KitNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='KitNumber')  THEN KitNumber END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='WorkScopeName')  THEN WorkScopeName END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkScopeName')  THEN WorkScopeName END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerName')  THEN CustomerName END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName')  THEN CustomerName END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Qty')  THEN Qty END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Qty')  THEN Qty END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='UnitCost')  THEN UnitCost END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN UnitCost END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineUnitCost')  THEN StocklineUnitCost END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineUnitCost')  THEN StocklineUnitCost END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC	
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
			ELSE IF (@TypeId = 3)
			BEGIN
				;WITH Result AS (
				SELECT
					kitm.Migrated_Id KitId,
					kitm.Migrated_Id,
					km.KitNumber KitNumber,
					kitm.MainItemMasterId ItemMasterId,
					im.partnumber PartNumber,
					im.PartDescription PartDescription,
					km.Manufacturer,
					km.CustomerId,
					km.CustomerName AS CustomerName,
					wos.WorkScopeCode AS WorkScopeName,
					km.KitCost,
					kitm.UnitCost AS UnitCost,
					(SELECT ISNULL(COUNT(kimm.KitItemMasterMappingId),0) FROM [dbo].[KitItemMasterMapping] kimm WITH (NOLOCK) WHERE kimm.KitId = kitm.Migrated_Id AND kimm.IsDeleted = 0) AS Qty,
					0 AS StocklineUnitCost,
					1 AS IsActive,
					kitm.Date_Created CreatedDate,
					0 AS IsDeleted,
					SuccessMsg,
					ErrorMsg
				FROM [Quantum_Staging].dbo.[KitMasters] kitm WITH (NOLOCK)
				LEFT JOIN dbo.KitMaster km ON km.KitId = kitm.Migrated_Id
				LEFT JOIN dbo.ItemMaster im ON im.ItemMasterId = kitm.MainItemMasterId
				LEFT JOIN dbo.Manufacturer mf ON km.ManufacturerId = mf.ManufacturerId
				LEFT JOIN [dbo].[WorkScope] wos WITH (NOLOCK) ON km.WorkScopeId = wos.WorkScopeId
		 		  WHERE kitm.Migrated_Id IS NULL AND (kitm.ErrorMsg IS NOT NULL AND kitm.ErrorMsg NOT like '%Item Master record already exists%') AND kitm.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(KitId) AS totalItems FROM Result)
				SELECT * INTO #TempResultKM3 FROM  Result

				SELECT @Count = COUNT(ItemMasterId) FROM #TempResultKM3			

				SELECT *, @Count AS NumberOfItems FROM #TempResultKM3 ORDER BY  
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturer')  THEN Manufacturer END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN Manufacturer END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='KitNumber')  THEN KitNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='KitNumber')  THEN KitNumber END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='WorkScopeName')  THEN WorkScopeName END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkScopeName')  THEN WorkScopeName END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerName')  THEN CustomerName END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName')  THEN CustomerName END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Qty')  THEN Qty END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Qty')  THEN Qty END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='UnitCost')  THEN UnitCost END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN UnitCost END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineUnitCost')  THEN StocklineUnitCost END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineUnitCost')  THEN StocklineUnitCost END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC	
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
			ELSE IF (@TypeId = 4)
			BEGIN
				;WITH Result AS (
				SELECT
					kitm.Migrated_Id KitId,
					kitm.Migrated_Id,
					km.KitNumber KitNumber,
					kitm.MainItemMasterId ItemMasterId,
					im.partnumber PartNumber,
					im.PartDescription PartDescription,
					km.Manufacturer,
					km.CustomerId,
					km.CustomerName AS CustomerName,
					wos.WorkScopeCode AS WorkScopeName,
					km.KitCost,
					kitm.UnitCost AS UnitCost,
					(SELECT ISNULL(COUNT(kimm.KitItemMasterMappingId),0) FROM [dbo].[KitItemMasterMapping] kimm WITH (NOLOCK) WHERE kimm.KitId = kitm.Migrated_Id AND kimm.IsDeleted = 0) AS Qty,
					0 AS StocklineUnitCost,
					1 AS IsActive,
					kitm.Date_Created CreatedDate,
					0 AS IsDeleted,
					SuccessMsg,
					ErrorMsg
				FROM [Quantum_Staging].dbo.[KitMasters] kitm WITH (NOLOCK)
				LEFT JOIN dbo.KitMaster km ON km.KitId = kitm.Migrated_Id
				LEFT JOIN dbo.ItemMaster im ON im.ItemMasterId = kitm.MainItemMasterId
				LEFT JOIN dbo.Manufacturer mf ON km.ManufacturerId = mf.ManufacturerId
				LEFT JOIN [dbo].[WorkScope] wos WITH (NOLOCK) ON km.WorkScopeId = wos.WorkScopeId
		 		  WHERE kitm.Migrated_Id IS NULL AND (kitm.ErrorMsg IS NOT NULL AND kitm.ErrorMsg like '%Item Master record already exists%') AND kitm.MasterCompanyId = @MasterCompanyId
				), ResultCount AS(Select COUNT(KitId) AS totalItems FROM Result)
				SELECT * INTO #TempResultKM4 FROM  Result

				SELECT @Count = COUNT(ItemMasterId) FROM #TempResultKM4			

				SELECT *, @Count AS NumberOfItems FROM #TempResultKM4 ORDER BY  
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturer')  THEN Manufacturer END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN Manufacturer END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='KitNumber')  THEN KitNumber END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='KitNumber')  THEN KitNumber END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='WorkScopeName')  THEN WorkScopeName END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='WorkScopeName')  THEN WorkScopeName END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerName')  THEN CustomerName END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName')  THEN CustomerName END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='Qty')  THEN Qty END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='Qty')  THEN Qty END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='UnitCost')  THEN UnitCost END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN UnitCost END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='StocklineUnitCost')  THEN StocklineUnitCost END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='StocklineUnitCost')  THEN StocklineUnitCost END DESC,
				CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
				CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC
				OFFSET @RecordFrom ROWS 
				FETCH NEXT @PageSize ROWS ONLY
			END
		END
		END TRY
	BEGIN CATCH	
		     DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'ItemMasterStockList'
			,@ProcedureParameters VARCHAR(3000) = 
			     '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') as Varchar(100))
				 + ' @Parameter2 = ''' +  CAST(ISNULL(@PageSize, '') as Varchar(100))
				 + ' @Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') as Varchar(100))
				 + ' @Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') as Varchar(100))
				 + ' @Parameter5 = ''' + CAST(ISNULL(@MasterCompanyId   , '') as Varchar(100))
				,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END