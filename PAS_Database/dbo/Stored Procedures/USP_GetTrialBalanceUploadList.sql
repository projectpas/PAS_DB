/*************************************************************           
 ** File:		 [USP_GetTrialBalanceUploadList]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Trial Balance Upload List Data.
 ** Purpose:         
 ** Date:   23-JUNE-2026
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    23-JUNE-2026		Divyesh Kathiriya	Created
    
 -- EXEC [USP_GetTrialBalanceUploadList] @MasterCompanyId=1,@EmployeeId=236
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetTrialBalanceUploadList]
@MasterCompanyId INT,
@EmployeeId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
				
		SELECT 
			@CurrntEmpTimeZoneDesc = COALESCE(
				ETZ.[Description],  -- Prefer Employee's TimeZone description if available
				LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
			)
		FROM 
			[DBO].[Employee] E WITH (NOLOCK) 
		LEFT JOIN 
			[DBO].[TimeZone] ETZ WITH (NOLOCK) 
			ON E.[TimeZoneId] = ETZ.[TimeZoneId]
		LEFT JOIN 
			[dbo].[LegalEntity] LE WITH (NOLOCK) 
			ON E.[LegalEntityId] = LE.LegalEntityId
		LEFT JOIN 
			[dbo].[TimeZone] LTZ WITH (NOLOCK) 
			ON LE.[TimeZoneId] = LTZ.[TimeZoneId]
		WHERE 
			E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee
		
		SELECT 
		   [TrialBalanceUploadId],
		   [Status],
		   [TotalRecords],
		   [ErrorDetails],
		   [FilePath],
		   [CreatedBy],
		   [UpdatedBy],
		   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				 CASE WHEN CAST([CreatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal([CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
		   ELSE (CAST([CreatedDate] AS DATETIME)) END CreatedDate,
		   CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				 CASE WHEN CAST(UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(UpdatedDate AS DATETIME)) END UpdatedDate,
		   [MasterCompanyId],
		   ISNULL([IsActive], 0) AS IsActive,
		   ISNULL([IsDeleted], 0) AS IsDeleted
		FROM [dbo].[TrialBalanceUpload] WITH(NOLOCK)		
		WHERE [MasterCompanyId] = @MasterCompanyId 
		ORDER BY [CreatedDate] DESC;	   	  
	
	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetTrialBalanceUploadList'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END