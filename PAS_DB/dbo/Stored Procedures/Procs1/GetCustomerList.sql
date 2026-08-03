/*************************************************************
 ** File:   [GetCustomerList]
 ** Author:   Ameet Prajapati
 ** Description: Get Search Data for Customer List
 ** Purpose:
 ** Date:   14-Dec-2020

 ** PARAMETERS: @POId varchar(60)

 ** RETURN VALUE:

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author				Change Description
 ** --   --------     -------				--------------------------------
    1    12/14/2020   Hemant Saliya			Created
	2    12/17/2020   Updated Like for General Filter
    3    03/13/2024   Ekta Chandegra		Add master company on join
    4    10/18/2024   Devendra Shekh		Add fields related to quickBooks
	5    15/01/2025   Ayushi Patel			converted the date into utc (created , updated) , Added a case to get timeZone
	6    06-03-2025   Shrey Chandegara      Modified due to add view in Accouting Integration List's PendingSync(Add @IsUpdated parameter)
	7	 17-06-2025   Bhargav Saliya        Select Is Customer also a vendor flag and vendor Name
	8    03-03-2026   Sahdev Saliya			Added Memo (PN-15567)
	9    02-07-2026   Sahdev Saliya			Added Resale Number [PN-17018]
	10   07-07-2026   Bhargav Saliya		Added @IntegrationTypeId [PN-16810]
	11   07-07-2026   Divyesh Kathitiya		Added VAT Number [PN-17124]
	12   08-03-2026   Rajesh Gami			Performance pass: removed per-row scalar UDF call
											(DBO.ConvertUTCtoLocal), removed #TempResult /
											separate COUNT pass (now COUNT(*) OVER()), and
											switched CustomerContact/Vendor to OUTER APPLY
											TOP(1) to guard against row duplication. See
											GetCustomerList_Performance_Recommendations.sql
											for the full before/after review.

 EXECUTE [GetCustomerList] 1, 10, null, -1, 1, '', 'uday', 'CUS-00','','HYD'
**************************************************************/
CREATE PROCEDURE [dbo].[GetCustomerList]
	-- Add the parameters for the stored procedure here
	@PageNumber int,
	@PageSize int,
	@SortColumn varchar(50)=null,
	@SortOrder int,
	@StatusID int,
	@GlobalFilter varchar(50) = null,
	@Name varchar(50)=null,
	@CutomerCode varchar(50)=null,
	@Email varchar(50)=null,
	@City varchar(50)=null,
    @StateOrProvince varchar(50)=null,
    @AccountType varchar(50)=null,
    @CustomerType varchar(50)=null,
    @CustomerClassification varchar(200)=null,
    @Contact varchar(50)=null,
    @SalesPersonPrimary varchar(50)=null,
    @CreatedDate datetime=null,
    @UpdatedDate  datetime=null,
	@CreatedBy  varchar(50)=null,
	@UpdatedBy  varchar(50)=null,
    @IsDeleted bit= null,
	@QuickBooksReferenceId  varchar(200)=null,
	@isSynced  varchar(20)=null,
	@LastSyncDate datetime=null,
	@MasterCompanyId bigint = NULL,
	@EmployeeId bigint,
	@IsUpdated BIT = NULL,
	@IsCustomerAlsoVendor BIT = NULL,
	@IsCustVendor  varchar(20)=null,
	@VendorName varchar(100)=null,
	@Memo varchar(max) = NULL,
	@ResaleNumber varchar(200) = null,
	@IntegrationTypeId BIGINT = null,
	@VatNumber VARCHAR(50) = NULL
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY


		DECLARE @RecordFrom int;
		DECLARE @IsActive bit=1
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		-- PERF FIX: also resolve the numeric UTC offset here, once, alongside the description,
		-- so the CTE below can use DATEADD directly instead of calling DBO.ConvertUTCtoLocal
		-- per row (that function re-queries dbo.TimeZone on every call and forces row-by-row
		-- execution for the whole query).
		DECLARE @BaseUtcOffsetSec INT = 0;
		SELECT
				@CurrntEmpTimeZoneDesc = COALESCE(
					ETZ.[Description],  -- Prefer Employee's TimeZone description if available
					LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
				),
				@BaseUtcOffsetSec = COALESCE(ETZ.BaseUtcOffsetSec, LTZ.BaseUtcOffsetSec, 0)
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
				E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted=0
		END
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CreatedDate')
		END
		Else
		BEGIN
			SET @SortColumn=UPPER(@SortColumn)
		END
		IF @StatusID=0
		BEGIN
			SET @IsActive=0
		END
		ELSE IF @StatusID=1
		BEGIN
			SET @IsActive=1
		END
		ELSE IF @StatusID=2
		BEGIN
			SET @IsActive=NULL
		END
		DECLARE @CustomerModule INT=1;
		   ;WITH Result AS(
			SELECT
					C.CustomerId,
					C.[Name],
					C.CustomerCode,
					C.Email,
					CT.CustomerTypeName AS AccountType,
					STUFF((SELECT ', ' + CCL.Description
							FROM dbo.ClassificationMapping cm WITH (NOLOCK)
							INNER JOIN dbo.CustomerClassification CCL WITH (NOLOCK) ON CCL.CustomerClassificationId=cm.ClasificationId AND CCL.MasterCompanyId = @MasterCompanyId
							WHERE cm.ReferenceId=C.CustomerId AND cm.ModuleId=@CustomerModule
							FOR XML PATH('')), 1, 1, '') 'CustomerClassification',
					A.City,
					A.StateOrProvince,
					(ISNULL(Contact.FirstName,'')+' '+ISNULL(Contact.LastName,'')) AS 'Contact',
					(ISNULL(E.FirstName,'')+' '+ISNULL(E.LastName,'')) AS 'SalesPersonPrimary',
					C.IsActive,
					C.IsDeleted,
					-- PERF FIX: inline DATEADD using the offset resolved once above, instead of
					-- calling DBO.ConvertUTCtoLocal(...) per row (see note near @BaseUtcOffsetSec).
					CAST(DATEADD(SECOND, @BaseUtcOffsetSec, C.CreatedDate) AS datetime) AS CreatedDate,
					C.CreatedBy,
					CAST(DATEADD(SECOND, @BaseUtcOffsetSec, C.UpdatedDate) AS datetime) AS UpdatedDate,
					C.UpdatedBy,
					CA.[Description] AS CustomerType,
					C.IsTrackScoreCard,
					C.QuickBooksReferenceId,
					CASE WHEN ISNULL(C.QuickBooksReferenceId,'') != '' THEN 'YES' ELSE 'NO' END AS 'isSynced',
					C.LastSyncDate,
					CASE WHEN ISNULL(C.IsCustomerAlsoVendor,0) = 1 THEN 'YES' ELSE 'NO' END AS 'IsCustVendor',
					VApply.VendorName,
					C.Memo,
					C.ResaleNumber,
					C.VatNumber
					FROM dbo.Customer C WITH (NOLOCK)
					INNER JOIN dbo.CustomerType CT  WITH (NOLOCK) ON C.CustomerTypeId=CT.CustomerTypeId
					INNER JOIN dbo.CustomerAffiliation CA  WITH (NOLOCK) ON C.CustomerAffiliationId=CA.CustomerAffiliationId
					LEFT JOIN  dbo.CustomerSales CS  WITH (NOLOCK) ON C.CustomerId=CS.CustomerId
					LEFT JOIN  dbo.Employee E  WITH (NOLOCK) ON CS.PrimarySalesPersonId=e.EmployeeId
					LEFT JOIN  dbo.Address A  WITH (NOLOCK) ON C.AddressId=A.AddressId
					-- PERF FIX: TOP(1) APPLY instead of a plain LEFT JOIN filtered on
					-- IsDefaultContact = 1 - nothing in the schema enforces "only one default
					-- contact per customer", so a plain join could silently duplicate a
					-- customer's row. APPLY guarantees at most one match.
					OUTER APPLY (
						SELECT TOP (1) CC.ContactId
						FROM dbo.CustomerContact CC WITH (NOLOCK)
						WHERE CC.CustomerId = C.CustomerId AND CC.IsDefaultContact = 1
						ORDER BY CC.CustomerContactId
					) CCApply
					LEFT JOIN  dbo.Contact  WITH (NOLOCK) ON CCApply.ContactId=Contact.ContactId
					-- PERF FIX: same reasoning as above - Vendor.RelatedCustomerId also has no
					-- uniqueness guarantee in the schema.
					OUTER APPLY (
						SELECT TOP (1) V.VendorName
						FROM dbo.Vendor V WITH (NOLOCK)
						WHERE V.RelatedCustomerId = C.CustomerId
						ORDER BY V.VendorId
					) VApply
					Where ((C.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR C.IsActive=@IsActive))
					AND C.MasterCompanyId=@MasterCompanyId
					AND (ISNULL(@IsUpdated,0) <> 1 OR ISNULL(C.IsUpdated,0) = ISNULL(@IsUpdated,0))
					AND (@IntegrationTypeId IS NULL OR C.IntegrationTypeId = @IntegrationTypeId)
					AND (@IsCustomerAlsoVendor IS NULL OR C.IsCustomerAlsoVendor = @IsCustomerAlsoVendor)
			),
			-- PERF FIX: filters now run directly against Result (no #TempResult heap table),
			-- and COUNT(*) OVER() supplies NumberOfItems in the same pass that gets sorted/paged
			-- below - this replaces the old #TempResult + separate "SELECT @Count = COUNT(...)"
			-- scan with a single pass.
			FilteredResult AS (
			SELECT *, COUNT(*) OVER() AS NumberOfItems
			FROM Result
			WHERE (
			(@GlobalFilter <>'' AND ((Name LIKE '%' +@GlobalFilter+'%' ) OR (CustomerCode LIKE '%' +@GlobalFilter+'%') OR
					(Email LIKE '%' +@GlobalFilter+'%') OR
					(City LIKE '%' +@GlobalFilter+'%') OR
					(StateOrProvince LIKE '%' +@GlobalFilter+'%') OR
					(AccountType LIKE '%' +@GlobalFilter+'%') OR
					(CustomerType LIKE '%' +@GlobalFilter+'%') OR
					(CustomerClassification LIKE '%' +@GlobalFilter+'%') OR
					(Contact LIKE '%' +@GlobalFilter+'%') OR
					(SalesPersonPrimary LIKE '%'+@GlobalFilter+'%') OR
					(QuickBooksReferenceId LIKE '%' +@GlobalFilter+'%') OR
					(isSynced LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(IsCustVendor LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR
					(VendorName LIKE '%' +@GlobalFilter+'%') OR
					(Memo LIKE '%' +@GlobalFilter+'%') OR
					(ResaleNumber LIKE '%' +@GlobalFilter+'%') OR
					(VatNumber LIKE '%' +@GlobalFilter+'%')
					))
					OR
					(@GlobalFilter='' AND (ISNULL(@Name,'') ='' OR Name LIKE '%' + @Name+'%') AND
					(ISNULL(@CutomerCode,'') ='' OR CustomerCode LIKE '%' + @CutomerCode+'%') AND
					(ISNULL(@Email,'') ='' OR Email LIKE '%' + @Email+'%') AND
					(ISNULL(@City,'') ='' OR City LIKE '%' + @City+'%') AND
					(ISNULL(@StateOrProvince,'') ='' OR StateOrProvince LIKE '%' + @StateOrProvince+'%') AND
					(ISNULL(@AccountType,'') ='' OR AccountType LIKE '%' + @AccountType+'%') AND
					(ISNULL(@CustomerType,'') ='' OR CustomerType LIKE '%' + @CustomerType+'%') AND
					(ISNULL(@CustomerClassification,'') ='' OR CustomerClassification LIKE '%' + @CustomerClassification+'%') AND
					(ISNULL(@Contact,'') ='' OR Contact LIKE '%' + @Contact+'%') AND
					(ISNULL(@SalesPersonPrimary,'') ='' OR SalesPersonPrimary LIKE '%' + @SalesPersonPrimary+'%') and
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy+'%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy+'%') AND
					(ISNULL(@QuickBooksReferenceId,'') ='' OR QuickBooksReferenceId LIKE '%' + @QuickBooksReferenceId+'%') AND
					(ISNULL(@isSynced,'') ='' OR isSynced LIKE '%' + @isSynced+'%') AND
					(ISNULL(@LastSyncDate,'') ='' OR CAST(LastSyncDate as Date)=CAST(@LastSyncDate as date)) AND
					(ISNULL(@IsCustVendor,'') ='' OR IsCustVendor LIKE '%' + @IsCustVendor+'%') AND
					(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName+'%') AND
					(ISNULL(@Memo,'') ='' OR Memo LIKE '%' + @Memo+'%') AND
					(ISNULL(@ResaleNumber,'') ='' OR ResaleNumber LIKE '%' + @ResaleNumber+'%') AND
					(ISNULL(@VatNumber,'') ='' OR VatNumber LIKE '%' + @VatNumber+'%') AND
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate as Date)=CAST(@CreatedDate as date)) AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate as date)=CAST(@UpdatedDate as date)))
					)
			)
			SELECT *
			FROM FilteredResult
			ORDER BY
			CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='EMAIL')  THEN Email END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='City')  THEN City END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='STATEORPROVINCE')  THEN StateOrProvince END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='ACCOUNTTYPE')  THEN AccountType END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERTYPE')  THEN CustomerType END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERCLASSIFICATION')  THEN CustomerClassification END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CONTACT')  THEN Contact END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='SALESPERSONPRIMARY')  THEN SalesPersonPrimary END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='NAME')  THEN [Name] END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='CUSTOMERCODE')  THEN CustomerCode END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='QUICKBOOKSREFERENCEID')  THEN QuickBooksReferenceId END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='ISSYNCED')  THEN isSynced END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='LASTSYNCDATE')  THEN LastSyncDate END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='ISCUSTVENDOR')  THEN IsCustVendor END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='VENDORNAME')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='Memo')  THEN Memo END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='ResaleNumber')  THEN ResaleNumber END ASC,
			CASE WHEN (@SortOrder=1 AND @SortColumn='VATNUMBER')  THEN VatNumber END ASC,

			CASE WHEN (@SortOrder=-1 AND @SortColumn='EMAIL')  THEN Email END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='City')  THEN City END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='STATEORPROVINCE')  THEN StateOrProvince END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ACCOUNTTYPE')  THEN AccountType END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERTYPE')  THEN CustomerType END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERCLASSIFICATION')  THEN CustomerClassification END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CONTACT')  THEN Contact END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='SALESPERSONPRIMARY')  THEN SalesPersonPrimary END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDBY')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDBY')  THEN UpdatedBy END DESC,
            CASE WHEN (@SortOrder=-1 AND @SortColumn='CREATEDDATE')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UPDATEDDATE')  THEN UpdatedDate END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='NAME')  THEN [Name] END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CUSTOMERCODE')  THEN CustomerCode END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='QUICKBOOKSREFERENCEID')  THEN QuickBooksReferenceId END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ISSYNCED')  THEN isSynced END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LASTSYNCDATE')  THEN LastSyncDate END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ISCUSTVENDOR')  THEN IsCustVendor END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VENDORNAME')  THEN VendorName END DESC,
		    CASE WHEN (@SortOrder=-1 AND @SortColumn='Memo')  THEN Memo END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ResaleNumber')  THEN ResaleNumber END DESC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='VATNUMBER')  THEN VatNumber END DESC

			OFFSET @RecordFrom ROWS
			FETCH NEXT @PageSize ROWS ONLY
	END TRY
	BEGIN CATCH

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'GetCustomerList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100))
			   + '@Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@StatusID, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@Name, '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@CutomerCode, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@Email , '') AS varchar(100))
			   + '@Parameter10 = ''' + CAST(ISNULL(@City , '') AS varchar(100))
			   + '@Parameter11 = ''' + CAST(ISNULL(@StateOrProvince, '') AS varchar(100))
			   + '@Parameter12 = ''' + CAST(ISNULL(@AccountType, '') AS varchar(100))
			  + '@Parameter13 = ''' + CAST(ISNULL(@CustomerType, '') AS varchar(100))
			  + '@Parameter14 = ''' + CAST(ISNULL(@CustomerClassification, '') AS varchar(100))
			  + '@Parameter15 = ''' + CAST(ISNULL(@Contact , '') AS varchar(100))
			  + '@Parameter16 = ''' + CAST(ISNULL(@SalesPersonPrimary , '') AS varchar(100))
			  + '@Parameter17 = ''' + CAST(ISNULL(@CreatedDate , '') AS varchar(100))
			  + '@Parameter18 = ''' + CAST(ISNULL(@UpdatedDate , '') AS varchar(100))
			  + '@Parameter19 = ''' + CAST(ISNULL(@CreatedBy  , '') AS varchar(100))
			  + '@Parameter20 = ''' + CAST(ISNULL(@UpdatedBy  , '') AS varchar(100))
			  + '@Parameter21 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			  + '@Parameter22 = ''' + CAST(ISNULL(@masterCompanyID, '') AS varchar(100))
			  + '@Parameter23 = ''' + CAST(ISNULL(@VendorName, '') AS varchar(100))
			  + '@Parameter24 = ''' + CAST(ISNULL(@Memo, '') AS varchar(100))
			  + '@Parameter25 = ''' + CAST(ISNULL(@VatNumber, '') AS varchar(100))
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