/************************************************************************************           
 ** File:   [BindHeaderDataNew]           
 ** Author: 
 ** Description: This stored procedure is used to get BindHeaderDataNew.
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************************************           
  ** Change History           
 **************************************************************************************           
 ** PR    Date					Author				Change Description            
 ** --    --------			-----------				--------------------------------          
	 1    4-09-2025			Amit Ghediya			Created

	 EXEC [dbo].[BindHeaderDataNew] 6616
****************************************************************************************/
CREATE    PROCEDURE [dbo].[BindHeaderDataNew]
	@WorkOrderQuoteId BIGINT
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY

			DECLARE @LegalEntityLogoModuleId BIGINT = 41;

			--Get Quote ManagementStructureId.
			SELECT TOP 1
				WOQ.QuoteNumber,
				WOQ.VersionNo,
				WOP.ManagementStructureId
			INTO #QuoteData
			FROM [DBO].[WorkOrderQuote] WOQ WITH(NOLOCK)
			INNER JOIN [DBO].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WOQ.WorkOrderId = WOP.WorkOrderId
			WHERE WOQ.IsDeleted = 0
			  AND WOQ.WorkOrderQuoteId = @WorkOrderQuoteId;

			--Use QuoteData to get full data
			SELECT TOP 1
				LE.CompanyName,
				LE.CompanyCode,
				ISNULL(AD.Line1,'') AS Address1,
				ISNULL(AD.Line2,'') AS Address2,
				ISNULL(AD.City,'') AS City,
				AD.StateOrProvince,
				AD.PostalCode,
				CO.countries_name AS Country,
				LE.PhoneNumber,
				LE.PhoneExt,
				QuoteNumber = (SELECT QuoteNumber FROM [DBO].[#QuoteData] WITH(NOLOCK)),
				(
					SELECT TOP 1 ATD.Link
					FROM [DBO].[Attachment] ATT WITH(NOLOCK)
					INNER JOIN [DBO].[AttachmentDetails] ATD WITH(NOLOCK) ON ATT.AttachmentId = ATD.AttachmentId
					WHERE ATT.ReferenceId = LE.LegalEntityId
					  AND ATT.ModuleId = @LegalEntityLogoModuleId
					  AND ATD.IsActive = 1
					  AND ATD.IsDeleted = 0
				) AS AttachmentDetails
			FROM [DBO].[ManagementStructure] MS WITH(NOLOCK)
			INNER JOIN [DBO].[LegalEntity] LE WITH(NOLOCK) ON MS.LegalEntityId = LE.LegalEntityId
			INNER JOIN [DBO].[Address] AD WITH(NOLOCK) ON LE.AddressId = AD.AddressId
			INNER JOIN [DBO].[Countries] CO WITH(NOLOCK) ON AD.CountryId = CO.countries_id
			WHERE MS.ManagementStructureId = (SELECT ManagementStructureId FROM [DBO].[#QuoteData] WITH(NOLOCK));

			--Retm & Conditon Response.
			SELECT TOP 1 
				LEC.TermsandConditions
			FROM [DBO].[LegalEntityConfiguration] LEC WITH(NOLOCK)
			INNER JOIN [DBO].[LegalEntity] LE WITH(NOLOCK) ON LEC.LegalEntityId = LE.LegalEntityId
			INNER JOIN [DBO].[ManagementStructure] MS WITH(NOLOCK) ON LE.LegalEntityId = MS.LegalEntityId
			WHERE MS.ManagementStructureId = (SELECT TOP 1 ManagementStructureId FROM [DBO].[#QuoteData] WITH(NOLOCK));

			-- Drop 
			DROP TABLE #QuoteData;

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'BindHeaderDataNew' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderQuoteId, '')
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN
		END CATCH
END