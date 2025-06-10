/*************************************************************           
 ** File:		 [USP_GetEntityInternationalWireById]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Legal Entity International Wire By Id.
 ** Purpose:         
 ** Date:   29-MAY-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    29-MAY-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_GetEntityInternationalWireById] @LegalEntityId=1,@EmployeeId=226
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetEntityInternationalWireById]
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
			CASE WHEN t.[InternationalWirePaymentId] IS NOT NULL THEN 1 ELSE 0 END AS Internationaldata,
			t.[SwiftCode],
			t.[BeneficiaryBankAccount],
			t.[BeneficiaryBank],
			ISNULL(t.[BeneficiaryCustomer], '') AS BeneficiaryCustomer,
			t.[BankName],
			t.[BankAddressId],
			t.[IntermediaryBank],
			ISNULL(ad.[IsActive], 1) AS IsActive,
			ISNULL(ad.[IsDeleted], 0) AS IsDeleted,
			ISNULL(ad.[IsPrimay], 0) AS IsPrimay,
			CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				 CASE WHEN CAST(ad.[CreatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(ad.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(ad.[CreatedDate] AS DATETIME)) END AS CreatedDate,
			ad.CreatedBy,
			ad.UpdatedBy,
			CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				 CASE WHEN CAST(ad.[UpdatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(ad.[UpdatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(ad.[UpdatedDate] AS DATETIME)) END AS UpdatedDate,
			ad.[LegalEntityInternationalWireBankingId],
			t.[ABA],
			t.[InternationalWirePaymentId],
			t.[BankLocation1],
			t.[BankLocation2],
			t.[GLAccountId],			
			CASE WHEN glac.[GLAccountId] IS NOT NULL THEN CONCAT(glac.[AccountCode], ' - ', glac.[AccountName]) ELSE '' END AS GLAccount
		FROM [DBO].[InternationalWirePayment] t WITH(NOLOCK)
		INNER JOIN [DBO].[LegalEntityInternationalWireBanking] ad WITH(NOLOCK) ON t.[InternationalWirePaymentId] = ad.[InternationalWirePaymentId]
		LEFT JOIN [DBO].[GLAccount] glac WITH(NOLOCK) ON t.[GLAccountId] = glac.[GLAccountId]
		WHERE ad.[LegalEntityId] = @LegalEntityId
		ORDER BY ad.[CreatedDate] DESC;		

	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetEntityInternationalWireById'
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