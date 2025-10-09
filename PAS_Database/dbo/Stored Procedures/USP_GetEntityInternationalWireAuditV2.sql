/*************************************************************           
 ** File:		 [USP_GetEntityInternationalWireAuditV2]           
 ** Author:		 Rajesh Gami
 ** Description: This Stored Procedure Is Used To Get LegalEntity International Wire History By Id.
 ** Purpose:         
 ** Date:   08 OCT 2025
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    08 OCT 2025		Rajesh Gami	Created
    
 -- EXEC [USP_GetEntityInternationalWireAuditV2] @LegalEntityId=1, @EmployeeId=226
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_GetEntityInternationalWireAuditV2]
@LegalEntityId BIGINT,
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
            IWPA.[InternationalWirePaymentAuditId],
            IWPA.[InternationalWirePaymentId],
            IWPA.[ABA],
            IWPA.[IntermediaryBank],
            IWPA.[BankAddressId],
            IWPA.[BankName],
            IWPA.[BeneficiaryBank],
            IWPA.[BeneficiaryBankAccount],
            IWPA.[BeneficiaryCustomer],
            IWPA.[CreatedBy],
            CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				 CASE WHEN CAST(IWPA.[CreatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(IWPA.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(IWPA.[CreatedDate] AS DATETIME)) END AS CreatedDate,
            ISNULL(IWPA.[IsActive], 1) AS IsActive,
			ISNULL(IWPA.[IsDeleted], 0) AS IsDeleted,            
			CASE WHEN GL.[GLAccountId] IS NOT NULL THEN CONCAT(GL.[AccountCode], ' - ', GL.[AccountName]) ELSE '' END AS GLAccount,
            IWPA.[SwiftCode],
            IWPA.[UpdatedBy],
            CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				 CASE WHEN CAST(IWPA.[UpdatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(IWPA.[UpdatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(IWPA.[UpdatedDate] AS DATETIME)) END AS UpdatedDate
        FROM [DBO].[InternationalWirePaymentAuditV2] IWPA WITH(NOLOCK)
        LEFT JOIN [DBO].[LegalEntityInternationalWireBankingV2] LEIWB WITH(NOLOCK) ON IWPA.[InternationalWirePaymentId] = LEIWB.[InternationalWirePaymentId]
        LEFT JOIN [DBO].[GLAccount] GL WITH(NOLOCK) ON IWPA.[GLAccountId] = GL.[GLAccountId]
        WHERE LEIWB.[LegalEntityInternationalWireBankingId] = @LegalEntityId
        ORDER BY IWPA.[InternationalWirePaymentAuditId] DESC;

	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetEntityInternationalWireAuditV2'
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