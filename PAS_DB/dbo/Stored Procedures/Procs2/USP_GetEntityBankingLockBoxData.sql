/*************************************************************           
 ** File:		 [USP_GetEntityBankingLockBoxData]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Legal Entity Banking LockBox Data.
 ** Purpose:         
 ** Date:   26-MAY-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    26-MAY-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_GetEntityBankingLockBoxData] @LegalEntityId=1,@EmployeeId=226
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetEntityBankingLockBoxData]
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
			[dbo].[LegalEntity] LE WITH (NOLOCK) 
			ON E.[LegalEntityId] = LE.LegalEntityId
		LEFT JOIN 
			[dbo].[TimeZone] LTZ WITH (NOLOCK) 
			ON LE.[TimeZoneId] = LTZ.[TimeZoneId]
		WHERE 
			E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee
		
		SELECT 
			CASE WHEN leb.[LegalEntityBankingLockBoxId] IS NOT NULL THEN 1 ELSE 0 END AS LocboxData,
			leb.[LegalEntityId],
			leb.[LegalEntityBankingLockBoxId],
			leb.[MasterCompanyId],
			ISNULL(leb.[IsActive], 0) AS IsActive,
			ISNULL(leb.[IsDeleted], 0) AS IsDeleted,
			leb.[CreatedBy],		
			CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				 CASE WHEN CAST(leb.[CreatedDate] AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(leb.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(leb.[CreatedDate] AS DATETIME)) END CreatedDate,
			leb.[UpdatedBy],
			CASE WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' THEN 
				 CASE WHEN CAST(leb.UpdatedDate AS DATE) = CAST('0001-01-01 00:00:00' AS DATE) THEN NULL ELSE (CAST(DBO.ConvertUTCtoLocal(leb.UpdatedDate, @CurrntEmpTimeZoneDesc) AS DATETIME)) END 
			ELSE (CAST(leb.UpdatedDate AS DATETIME)) END UpdatedDate,
			ISNULL(leb.[IsPrimay], 0) AS IsPrimay,
			leb.[AddressId],
			addr.[Line1] AS Address1,
			ISNULL(addr.[Line2], '') AS Address2,
			addr.[City],
			addr.[StateOrProvince],
			addr.[PostalCode],
			ISNULL(addr.[PoBox], '') AS PoBox,
			ct.[countries_name] AS Country,
			ct.[countries_id] AS CountryId,
			CASE WHEN leb.[LegalEntityBankingLockBoxId] IS NOT NULL THEN 1 ELSE 0 END AS Domesticdata,
			ISNULL(leb.[PayeeName],'') AS PayeeName,
			ISNULL(leb.[GLAccountId],'') AS GLAccountId,
			CONCAT(gla.[AccountCode], ' - ', gla.[AccountName]) AS GlAccount,			
			ISNULL(leb.[BankName], '') AS BankName,
			ISNULL(leb.[AttachmentId], 0) AS AttachmentId,
			ISNULL(leb.[BankAccountNumber], '') AS BankAccountNumber,
			ISNULL(att.[FileName], '') AS FileName,
			ISNULL(att.[Link], '') AS Link,
			ISNULL(leb.[AccountTypeId], 0) AS AccountTypeId,
            CASE leb.AccountTypeId
                WHEN 1 THEN 'Deposit'
                WHEN 2 THEN 'Disbursement'
                WHEN 3 THEN 'Both'
                ELSE ''
            END AS AccountType
		FROM [DBO].[LegalEntityBankingLockBox] leb WITH(NOLOCK)
		LEFT JOIN [DBO].[Address] addr WITH(NOLOCK) ON leb.[AddressId] = addr.[AddressId]
		LEFT JOIN [DBO].[Countries] ct WITH(NOLOCK) ON addr.[CountryId] = ct.[countries_id]
		LEFT JOIN [DBO].[GLAccount] gla WITH(NOLOCK) ON leb.[GLAccountId] = gla.[GLAccountId]
		LEFT JOIN [DBO].[AttachmentDetails] att WITH(NOLOCK) ON leb.[AttachmentId] = att.[AttachmentId]
		WHERE leb.[LegalEntityId] = @LegalEntityId 
		ORDER BY leb.[CreatedDate] DESC;				  		 	   			   	  
	
	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetEntityBankingLockBoxData'
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