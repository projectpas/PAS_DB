/*************************************************************           
 ** File:		 [USP_GetLegalEntityACHAuditById]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Legal Entity ACH History By Id.
 ** Purpose:         
 ** Date:   03-June-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    03-June-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_GetLegalEntityACHAuditById] @ACHId=1,@EmployeeId=226
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetLegalEntityACHAuditById]
@ACHId BIGINT,
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
			[DBO].[LegalEntity] LE WITH (NOLOCK) 
			ON E.[LegalEntityId] = LE.LegalEntityId
		LEFT JOIN 
			[DBO].[TimeZone] LTZ WITH (NOLOCK) 
			ON LE.[TimeZoneId] = LTZ.[TimeZoneId]
		WHERE 
			E.[EmployeeId] = @EmployeeId; -- Use appropriate filter for the specific employee	 
			
		
		SELECT
            A.[LegalEntityId],
            A.[ACHAuditId],
            A.[ACHId],
            A.[BankAddressId],
            A.[ABA],
            A.[AccountNumber],
            A.[BankName],
            A.[BeneficiaryBankName],
            A.[CreatedBy],
			CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				 CASE WHEN CAST(A.[CreatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(A.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(A.[CreatedDate] AS DATETIME)) END AS CreatedDate,
            A.[IntermediateBankName],
            ISNULL(A.[IsActive], 1) AS IsActive,
			ISNULL(A.[IsDeleted], 0) AS IsDeleted,
            A.[UpdatedBy],
            A.[SwiftCode],
			CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				 CASE WHEN CAST(A.[UpdatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(A.[UpdatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(A.[UpdatedDate] AS DATETIME)) END AS UpdatedDate,            
			CASE WHEN GL.[GLAccountId] IS NOT NULL THEN CONCAT(GL.[AccountCode], ' - ', GL.[AccountName]) ELSE '' END AS GlAccount
        FROM [DBO].[ACHAudit] A WITH(NOLOCK)
        LEFT JOIN [DBO].[GLAccount] gl WITH(NOLOCK) ON A.[GLAccountId] = GL.[GLAccountId]
        WHERE A.[ACHId] = @ACHId
        ORDER BY A.[ACHAuditId] DESC;

	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetLegalEntityACHAuditById'
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