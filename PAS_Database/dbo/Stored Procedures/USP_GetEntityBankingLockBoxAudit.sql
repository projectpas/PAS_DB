/*************************************************************           
 ** File:		 [USP_GetEntityBankingLockBoxAudit]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Legal Entity Banking LockBox Audit Data.
 ** Purpose:         
 ** Date:   26-MAY-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    26-MAY-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_GetEntityBankingLockBoxAudit] @LegalEntityBankingLockBoxId=24,@EmployeeId=226
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetEntityBankingLockBoxAudit]
@LegalEntityBankingLockBoxId BIGINT,
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
			
		SELECT DISTINCT
			LBA.[LegalEntityId],           
			ISNULL(LBA.[PayeeName],'') AS PayeeName,
			CASE WHEN GL.[GLAccountId] IS NOT NULL THEN CONCAT(GL.[AccountCode], ' - ', GL.[AccountName]) ELSE '' END AS GLAccount,
            ADA.[AddressAuditId],
            ADA.[AddressId],
            ISNULL(ADA.[POBox], '') AS POBox,
            ADA.[City],
            ADA.[PostalCode],
            ADA.[CountryId],
            CT.[countries_name],
            ADA.[StateOrProvince],			
            CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				 CASE WHEN CAST(ADA.[CreatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(ADA.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(ADA.[CreatedDate] AS DATETIME)) END AS CreatedDate,
            ADA.[UpdatedBy],
			ADA.[CreatedBy],
            CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				 CASE WHEN CAST(ADA.[UpdatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(ADA.[UpdatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(ADA.[UpdatedDate] AS DATETIME)) END AS UpdatedDate,
            ISNULL(ADA.[IsActive], 0) AS IsActive,
			ISNULL(ADA.[IsDeleted], 0) AS IsDeleted,
            ADA.[Line1],            
			ISNULL(ADA.[Line2], '') AS Line2,
			ISNULL(LBA.[BankName], '') AS BankName,
            ISNULL(LBA.[BankAccountNumber], '') AS BankAccountNumber
        FROM [DBO].[LegalEntityBankingLockBoxAudit] LBA WITH (NOLOCK)
        LEFT JOIN [DBO].[AddressAudit] ADA WITH (NOLOCK) ON LBA.[AddressId] = ADA.[AddressId]
        LEFT JOIN [DBO].[Countries] CT WITH (NOLOCK) ON ADA.[CountryId] = CT.[countries_id]
        LEFT JOIN [DBO].[GLAccount] GL WITH (NOLOCK) ON LBA.[GLAccountId] = GL.[GLAccountId]
        WHERE LBA.[LegalEntityBankingLockBoxId] = @LegalEntityBankingLockBoxId
        ORDER BY UpdatedDate DESC;
	
	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetEntityBankingLockBoxAudit'
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