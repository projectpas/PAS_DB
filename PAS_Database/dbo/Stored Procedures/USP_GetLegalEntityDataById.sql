/*************************************************************           
 ** File:		 [USP_GetLegalEntityDataById]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get Legal Entity Data By Id.
 ** Purpose:         
 ** Date:   30-April-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    30-April-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_GetLegalEntityDataById] @LegalEntityId=34
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_GetLegalEntityDataById]
@LegalEntityId BIGINT = Null
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		SELECT TOP 1	
			le.[LegalEntityId],
			le.[Name],
			le.[CompanyName],
			le.[DoingLegalAs],
			le.[AddressId],
			le.[FaxNumber],
			le.[PhoneNumber],
			le.[FunctionalCurrencyId],
			le.[ReportingCurrencyId],
			ISNULL(le.[IsBalancingEntity],0) AS IsBalancingEntity,
			le.[CageCode],
			le.[FAALicense],
			le.[EASALicense],
			le.[CAACLicense],
			le.[TCCALicense],
			le.[UKCAALicense],
			le.[TaxId],
			le.[MasterCompanyId],
			ISNULL(le.[IsActive], 0) AS IsActive,
			ISNULL(le.[IsDeleted], 0) AS IsDeleted,
			le.[CreatedBy],
			le.[CreatedDate],
			ISNULL(le.[AttachmentId], 0) AS AttachmentId,
			le.[UpdatedBy],
			le.[UpdatedDate],
			ISNULL(le.[InvoiceAddressPosition], 0) AS InvoiceAddressPosition,
			ISNULL(le.[InvoiceFaxPhonePosition], 0) AS InvoiceFaxPhonePosition,
			ISNULL(le.[LastLevel], 0) AS LastLevel,
			le.[PhoneExt],
			le.[CompanyCode],
			ad.[Line1] AS Address1,
			ISNULL(ad.[Line2], '') AS Address2,
			ad.[City],
			ad.[StateOrProvince],
			ad.[PostalCode],
			cont.[countries_name] AS Country,
			cont.[countries_id] AS CountryId,
			funcCur.[Symbol] AS FunctionalCurrency,
			cu.[Symbol] AS ReportingCurrency,
			ISNULL(le.[IsAddressForShipping], 0) AS IsAddressForShipping,
			ISNULL(le.[IsAddressForBilling], 0) AS IsAddressForBilling,
			funcCur.[Code] AS FunctionalCurrencyCode,
			cu.[Code] AS ReportingCurrencyCode,
			lg.[LedgerName],
			ISNULL(lg.[LedgerId], 0) AS ledgerId,
			ISNULL(tz.[TimeZoneId], 0) AS TimeZoneId,
			tz.[TimeZoneName],
			ISNULL(le.[IsPrintCheckNumber], 0) AS IsPrintCheckNumber,
			ISNULL(le.[IsTurnOffMgmt], 0) AS IsTurnOffMgmt,
			ISNULL(le.[CurrencyFormatId], 0) AS CurrencyFormatId,
			ISNULL(le.[DecimalPrecisionId], 0) AS DecimalPrecisionId,
			ISNULL(le.[ShortDateTimeFormatId], 0) AS ShortDateFormatId,
			ISNULL(le.[LongDateTimeFormatId], 0) AS LongDateFormatId,
			ISNULL(le.[TextTransformId], 0) AS TextTransformId,
			ISNULL(le.[EnableLockScreen], 0) AS EnableLockScreen,
			ISNULL(le.[TimeoutInMinutes], 0) AS TimeoutInMinutes,	
			(SELECT STRING_AGG(mp.[TagName], ',') FROM [LegalEntityTagNameMapping] mp WITH (NOLOCK) WHERE mp.[LegalEntityId] = le.[LegalEntityId]) AS TagNames
		FROM [DBO].[LegalEntity] le WITH (NOLOCK) 	
		LEFT JOIN [DBO].[Address] ad WITH (NOLOCK) ON le.[AddressId] = ad.[AddressId]
		LEFT JOIN [DBO].[Countries] cont WITH (NOLOCK) ON ad.[CountryId] = cont.[countries_id]
		LEFT JOIN [DBO].[Currency] cu WITH (NOLOCK) ON le.[ReportingCurrencyId] = cu.[CurrencyId]
		LEFT JOIN [DBO].[Currency] funcCur WITH (NOLOCK) ON le.[FunctionalCurrencyId] = funcCur.[CurrencyId]
		LEFT JOIN [DBO].[Ledger] lg WITH (NOLOCK) ON le.[LedgerId] = lg.[LedgerId]
		LEFT JOIN [DBO].[TimeZone] tz WITH (NOLOCK) ON le.[TimeZoneId] = tz.[TimeZoneId]
		WHERE le.[LegalEntityId] = @LegalEntityId;		  		 	   			   	  
	
	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetLegalEntityDataById'
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