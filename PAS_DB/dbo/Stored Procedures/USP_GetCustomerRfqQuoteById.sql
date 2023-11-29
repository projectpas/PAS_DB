/*************************************************************           
 ** File:   [USP_GetCustomerRfqQuoteById]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used USP_GetCustomerRfqQuoteById
 ** Purpose:         
 ** Date:   28/02/2023      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    28/02/2023  Amit Ghediya    Created
     
-- EXEC USP_GetCustomerRfqQuoteById '35633261',1,1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCustomerRfqQuoteById] 
@RfqId BIGINT,
@LegalEntityId BIGINT,
@MasterCompanyId INT
AS  
BEGIN  
  SET NOCOUNT ON;  
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  
  BEGIN TRY  
    BEGIN TRANSACTION  
			DECLARE @CustomerRFQId BIGINT, @CustomerRfqQuoteId BIGINT,@ModuleId BIGINT;

			SELECT @CustomerRFQId = CustomerRfqId FROM CustomerRFq WITH (NOLOCK)  WHERE RfqId = @RfqId AND MasterCompanyId = @MasterCompanyId;
			SELECT @CustomerRfqQuoteId = CustomerRfqQuoteId FROM CustomerRfqQuote CRFQQ WITH (NOLOCK) WHERE CRFQQ.CustomerRfqId = @CustomerRFQId;

			SELECT @ModuleId = AttachmentModuleId FROM dbo.AttachmentModule WITH(NOLOCK) WHERE UPPER(Name) = UPPER('LEGALENTITYLOGO')

		  ---------------- Customer RFQ Data -------------
		  SELECT CRFQ.[CustomerRfqId],
				 CRFQ.[RfqId],
				 CRFQ.[Type],
				 CRFQ.[BuyerName],
				 CRFQ.[BuyerCompanyName],
				 CRFQ.[BuyerAddress],
				 CRFQ.[BuyerCity],
				 CRFQ.[BuyerCountry],
				 CRFQ.[BuyerState],
				 CRFQ.[BuyerZip],
				 CRFQ.[LinePartNumber],
				 CRFQ.[LineDescription],
				 CRFQ.[RfqCreatedDate]
		  FROM CustomerRFq CRFQ WITH (NOLOCK)
		  WHERE RfqId = @RfqId AND MasterCompanyId = @MasterCompanyId;

		  ---------------- Customer RFQ Quote Data -------------
		  SELECT CRFQQ.[CustomerRfqQuoteId],
				 CRFQQ.[AddComment],
				 CRFQQ.[IsAddCommentQuote],
				 CRFQQ.[FaaEasaRelease],
				 CRFQQ.[IsFaaEasaReleaseQuote],
				 CRFQQ.[RpOh],
				 CRFQQ.[IsRpOhQuote],
				 CRFQQ.[Note]
		  FROM CustomerRfqQuote CRFQQ WITH (NOLOCK)
		  WHERE CRFQQ.CustomerRfqId = @CustomerRFQId;

		  ---------------- Customer RFQ Quote Details Data -------------
		  SELECT CRFQQD.[CustomerRfqQuoteDetailsId],
				 CRFQQD.[ServiceType],
				 CRFQQD.[QuotePrice],
				 CRFQQD.[QuoteTat],
				 CRFQQD.[Low],
				 CRFQQD.[Mid],
				 CRFQQD.[High],
				 CRFQQD.[AvgTat],
				 CRFQQD.[QuoteTatQty],
				 CRFQQD.[QuoteCond],
				 CRFQQD.[QuoteTrace]
		  FROM CustomerRfqQuoteDetails CRFQQD WITH (NOLOCK)
		  WHERE CRFQQD.CustomerRfqQuoteId = @CustomerRfqQuoteId;

		  ---------------- LEgal Entity Data --------------
		  SELECT LE.[Name],
				(ISNULL(Ad.Line1,'')+' '+ISNULL(Ad.Line2,'') +' '+ISNULL(Ad.Line3,'')) As RAddress,
				Ad.[City],
				Co.[countries_name],
				LE.[PhoneNumber], 
				LE.[FaxNumber],
				LE.[FAALicense],
				LE.[EASALicense],
				C.[Email],
				MS.[companylogo],
				ATD.[Link]
		 FROM LegalEntity LE WITH (NOLOCK)
		 INNER JOIN MasterCompany MS WITH(NOLOCK) ON MS.MasterCompanyId = LE.MasterCompanyId
		 LEFT JOIN Address Ad WITH (NOLOCK) ON LE.AddressId = Ad.AddressId
		 LEFT JOIN Countries Co WITH (NOLOCK) ON Ad.CountryId = Co.countries_id
		 LEFT JOIN dbo.LegalEntityContact LEC WITH(NOLOCK) ON LE.LegalEntityId = LEC.LegalEntityId AND LEC.IsDefaultContact = 1
		 LEFT JOIN dbo.Contact C WITH(NOLOCK) ON C.ContactId = LEC.ContactId 
		 LEFT JOIN dbo.Attachment ATT WITH(NOLOCK) ON LE.LegalEntityId = ATT.ReferenceId AND ATT.ModuleId = @ModuleId
		 LEFT JOIN dbo.AttachmentDetails ATD WITH(NOLOCK) ON ATT.AttachmentId = ATD.AttachmentId AND ATD.IsActive = 1 AND ATD.IsDeleted = 0
		 WHERE LE.LegalEntityId = @LegalEntityId;

    COMMIT TRANSACTION  
  END TRY  
  
  BEGIN CATCH  
    ROLLBACK TRANSACTION   
   
  
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,  
            @AdhocComments varchar(150) = '[USP_GetCustomerRfqQuoteById]',  
            @ProcedureParameters varchar(3000) = '@RfqId = ''' + CAST(ISNULL(@RfqId, '') AS varchar(100)) ,  
            @ApplicationName varchar(100) = 'PAS'  
  
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)  
  
    RETURN (1);  
  END CATCH  
  
END