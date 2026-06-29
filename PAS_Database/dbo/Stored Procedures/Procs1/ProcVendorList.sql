/*************************************************************           
 ** File:   [ProcVendorList]           
 ** Author:    
 ** Description: Get Search Data for Vendor List    
 ** Purpose:         
 ** Date:    
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------			--------------------------------          
    1					Unknown				Created
    2    10/18/2024		Devendra Shekh		Add fields related to quickBooks
	3    02/06/2025     Sahdev Saliya       Added a case to get timeZone 
	4    06-03-2025     Shrey Chandegara     Modified due to add view in Accouting Integration List's PendingSync(Add @IsUpdated parameter)
	5    12/03/2025     Sahdev Saliya       Change the Date format to Datetime
	6    31/03/2025     AMIT GHEDIYA        Added IsTrackScoreCard flag & TrackScoreCard param for scorecard display in list.
	7	 09-06-2025     Bhargav Saliya      Added @IsVendorAlsoCustomer Condition
	8	 17-06-2025     Bhargav Saliya      select Is Vendor also a customer Flag and Customer Name
	9	 30-07-2025     AMIT GHEDIYA		VendorId for select vendor data by id.
	10   24-06-2026     Sahdev Saliya       Added Notes [PN-16968]
	11   29-06-2026     Sahdev Saliya       Added Physical Resale [PN-17018]

**************************************************************/ 
CREATE       PROCEDURE [dbo].[ProcVendorList]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@StatusId int = NULL,
@VendorId bigint = 0,
@VendorName varchar(50) = NULL,
@VendorCode varchar(50) = NULL,
@VendorEmail varchar(50) = NULL,
@City varchar(50) = NULL,
@StateOrProvince varchar(50) = NULL,
@ClassificationName varchar(50) = NULL,
@VendorPhoneContact varchar(50) = NULL,
@Description varchar(50) = NULL,
@CreatedBy  varchar(50) = NULL,
@CreatedDate datetime = NULL,
@UpdatedBy  varchar(50) = NULL,
@UpdatedDate  datetime = NULL,
@IsDeleted bit = NULL,
@QuickBooksReferenceId  varchar(200)=null,
@isSynced  varchar(20)=null,
@TrackScoreCard  varchar(20)=null,
@LastSyncDate datetime=null,
@MasterCompanyId bigint=NULL,
@EmployeeId bigint,
@IsUpdated BIT = NULL,
@IsVendorAlsoCustomer BIT = NULL,
@CustomerName varchar(100)= NULL,
@IsVendorCust  varchar(20)=null,
@Notes NVARCHAR(MAX) = NULL,
@PhysicalResale VARCHAR(100) = NULL
AS
BEGIN	
	    SET NOCOUNT ON;
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		BEGIN TRY

		DECLARE @RecordFrom int;		
		DECLARE @Count Int;
		DECLARE @IsActive bit;
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

	     SELECT 
			@CurrntEmpTimeZoneDesc = COALESCE(
				ETZ.[Description],  -- Prefer Employee's TimeZone description if available
				LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
			)
		FROM 
			dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN 
			dbo.TimeZone ETZ WITH (NOLOCK) 
			ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN 
			dbo.LegalEntity LE WITH (NOLOCK) 
			ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN 
			dbo.TimeZone LTZ WITH (NOLOCK) 
			ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE 
			E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee
		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted=0
		END
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CreatedDate')
		END 
		ELSE
		BEGIN 
			Set @SortColumn=UPPER(@SortColumn)
		END
		IF(@StatusId=0)
		BEGIN
			SET @IsActive=0;
		END
		ELSE IF(@StatusId=1)
		BEGIN
			SET @IsActive=1;
		END
		ELSE
		BEGIN
			SET @IsActive=NULL;
		END

		IF(ISNULL(@VendorId,0) = 0)
		BEGIN
			 SET @VendorId = NULL;
		END

		--BEGIN TRY
		--BEGIN TRANSACTION
		--BEGIN
		
		;WITH Result AS(									
		   	 SELECT DISTINCT V.VendorId,
                    V.VendorName,
                    V.VendorCode,                   
					VT.[Description],  
                    V.VendorEmail,               
					(ISNULL(AD.City,'')) 'City',
                    (ISNULL(AD.StateOrProvince, '')) 'StateOrProvince',
					(ISNULL(CON.FirstName, '') + ' ' + ISNULL(CON.LastName, '')) 'VendorPhoneContact',                   
					case when CAST(V.CreatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(V.CreatedDate, @CurrntEmpTimeZoneDesc) as datetime))end CreatedDate,
                    V.CreatedBy,
					case when CAST(V.UpdatedDate as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(V.UpdatedDate, @CurrntEmpTimeZoneDesc) as datetime))end UpdatedDate,
                    V.UpdatedBy,                   			                  
				    V.IsDeleted,
					V.IsActive,
					ISNULL(A.ClassificationName, '') 'ClassificationName',
					V.QuickBooksReferenceId,
					CASE WHEN ISNULL(V.QuickBooksReferenceId,'') != '' THEN 'YES' ELSE 'NO' END AS 'isSynced',
					V.LastSyncDate,
					ISNULL(V.IsTrackScoreCard,0) AS IsTrackScoreCard,
					CASE WHEN ISNULL(V.IsTrackScoreCard,'') != '' THEN 'YES' ELSE 'NO' END AS 'TrackScoreCard',
					C.[Name] AS CustomerName,
					CASE WHEN ISNULL(V.IsVendorAlsoCustomer,'') != '' THEN 'YES' ELSE 'NO' END AS 'IsVendorCust',
					V.Notes,
					V.PhysicalResale
			   FROM dbo.Vendor V  WITH (NOLOCK) INNER JOIN  dbo.[Address] AD WITH (NOLOCK) ON V.AddressId=AD.AddressId
			                 LEFT JOIN   dbo.VendorType VT WITH (NOLOCK) ON V.VendorTypeId = VT.VendorTypeId
							 LEFT JOIN   dbo.VendorContact CC WITH (NOLOCK) ON V.VendorId = CC.VendorId AND CC.IsDefaultContact = 1
							 LEFT JOIN   dbo.Contact CON WITH (NOLOCK) ON CC.ContactId = CON.ContactId 
							 LEFT JOIN	 dbo.Customer C WITH(NOLOCK) ON V.RelatedCustomerId = C.CustomerId
							 OUTER APPLY(SELECT STUFF((SELECT ', ' + VC.ClassificationName
						     FROM dbo.ClassificationMapping CM  WITH (NOLOCK)
							 INNER JOIN dbo.VendorClassification VC WITH (NOLOCK) ON VC.VendorClassificationId = CM.ClasificationId
							 Where CM.ReferenceId = V.VendorId AND CM.ModuleId = 3
						     FOR XML PATH('')), 1, 1, '') ClassificationName) A
			                
		 	  WHERE ((V.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR V.IsActive = @IsActive))
					 AND (@VendorId IS NULL OR V.VendorId = @VendorId)
			         AND V.MasterCompanyId=@MasterCompanyId	AND (ISNULL(@IsUpdated,0) <> 1 OR ISNULL(V.isUpdated,0) = ISNULL(@IsUpdated,0))	 AND (@IsVendorAlsoCustomer IS NULL OR V.IsVendorAlsoCustomer = @IsVendorAlsoCustomer)
			), ResultCount AS(SELECT COUNT(VendorId) AS totalItems FROM Result)
			SELECT * INTO #TempResult FROM  Result
			 WHERE ((@GlobalFilter <>'' AND ((VendorCode LIKE '%' +@GlobalFilter+'%') OR
			        (VendorName LIKE '%' +@GlobalFilter+'%') OR	
					(VendorEmail LIKE '%' +@GlobalFilter+'%') OR					
					([Description] LIKE '%' +@GlobalFilter+'%') OR						
					(City LIKE '%' +@GlobalFilter+'%') OR						
					(StateOrProvince LIKE '%' +@GlobalFilter+'%') OR
					(VendorPhoneContact LIKE '%' +@GlobalFilter+'%') OR						
					(ClassificationName LIKE '%' +@GlobalFilter+'%') OR
					(QuickBooksReferenceId LIKE '%' +@GlobalFilter+'%') OR
					(isSynced LIKE '%' +@GlobalFilter+'%') OR
					(TrackScoreCard LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR
					([CustomerName] LIKE '%' +@GlobalFilter+'%') OR
					(IsVendorCust LIKE '%' +@GlobalFilter+'%') OR
					(Notes LIKE '%' +@GlobalFilter+'%') OR
					(PhysicalResale LIKE '%' +@GlobalFilter+'%')))
					OR   
					(@GlobalFilter='' AND (ISNULL(@VendorCode,'') ='' OR VendorCode LIKE '%' + @VendorCode+'%') AND
					(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND
					(ISNULL(@VendorEmail,'') ='' OR VendorEmail LIKE '%' + @VendorEmail + '%') AND
					(ISNULL(@Description,'') ='' OR [Description] LIKE '%' + @Description + '%') AND
					(ISNULL(@City,'') ='' OR City LIKE '%' + @City + '%') AND
					(ISNULL(@StateOrProvince,'') ='' OR StateOrProvince LIKE '%' + @StateOrProvince + '%') AND
					(ISNULL(@VendorPhoneContact,'') ='' OR VendorPhoneContact LIKE '%' + @VendorPhoneContact + '%') AND
					(ISNULL(@ClassificationName,'') ='' OR ClassificationName LIKE '%' + @ClassificationName + '%') AND
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND	
					(ISNULL(@QuickBooksReferenceId,'') ='' OR QuickBooksReferenceId LIKE '%' + @QuickBooksReferenceId+'%') AND
					(ISNULL(@isSynced,'') ='' OR isSynced LIKE '%' + @isSynced+'%') AND
					(ISNULL(@TrackScoreCard,'') ='' OR TrackScoreCard LIKE '%' + @TrackScoreCard+'%') AND
					(ISNULL(@LastSyncDate,'') ='' OR CAST(LastSyncDate as Date)=CAST(@LastSyncDate as date)) AND
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS Date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date)) AND 
					(ISNULL(@CustomerName,'') ='' OR CustomerName LIKE '%' + @CustomerName+'%') AND
					(ISNULL(@IsVendorCust,'') ='' OR IsVendorCust LIKE '%' + @IsVendorCust+'%') AND
					(ISNULL(@PhysicalResale,'') ='' OR PhysicalResale LIKE '%' + @PhysicalResale+'%') AND
					(ISNULL(@PhysicalResale,'') ='' OR PhysicalResale LIKE '%' + @PhysicalResale+'%'))
				   )

		SELECT @Count = COUNT(VendorId) FROM #TempResult			

		SELECT *, @Count AS NumberOfItems FROM #TempResult
			ORDER BY  
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
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='QuickBooksReferenceId')  THEN QuickBooksReferenceId END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='QuickBooksReferenceId')  THEN QuickBooksReferenceId END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='isSynced')  THEN isSynced END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='isSynced')  THEN isSynced END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='TrackScoreCard')  THEN TrackScoreCard END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='TrackScoreCard')  THEN TrackScoreCard END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LastSyncDate')  THEN LastSyncDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LastSyncDate')  THEN LastSyncDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CustomerName')  THEN CustomerName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CustomerName')  THEN CustomerName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='IsVendorCust')  THEN IsVendorCust END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IsVendorCust')  THEN IsVendorCust END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Notes')  THEN Notes END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Notes')  THEN Notes END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PhysicalResale')  THEN PhysicalResale END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PhysicalResale')  THEN PhysicalResale END DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY

		--END
		--COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
		--IF @@trancount > 0
			--PRINT 'ROLLBACK'
            --ROLLBACK TRANSACTION;

			DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'ProcVendorList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))			   
			   + '@Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@VendorName, '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@VendorCode, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@VendorEmail , '') AS varchar(100))
			   + '@Parameter10 = ''' + CAST(ISNULL(@City , '') AS varchar(100))
			   + '@Parameter11 = ''' + CAST(ISNULL(@StateOrProvince, '') AS varchar(100))
			   + '@Parameter12 = ''' + CAST(ISNULL(@ClassificationName, '') AS varchar(100))
			  + '@Parameter13 = ''' + CAST(ISNULL(@VendorPhoneContact, '') AS varchar(100))
			  + '@Parameter14 = ''' + CAST(ISNULL(@Description, '') AS varchar(100))
			  + '@Parameter15 = ''' + CAST(ISNULL(@CreatedBy , '') AS varchar(100))
			  + '@Parameter16 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			  + '@Parameter17 = ''' + CAST(ISNULL(@UpdatedBy , '') AS varchar(100))
			  + '@Parameter18 = ''' + CAST(ISNULL(@UpdatedDate , '') AS varchar(100))			
			  + '@Parameter19 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			  + '@Parameter20 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))
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