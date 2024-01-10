/*************************************************************           
 ** File:  [GetViewSpeedQuoteById]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to get SpeedQuoteData
 ** Purpose:         
 ** Date:   03/04/2023     
          
 ** PARAMETERS: @SpeedQuoteId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    03/04/2023  Amit Ghediya    Created
	2    05/01/2024  Moin Bloch      Added dbo in Table With No(LOCK)
     
-- EXEC GetViewSpeedQuoteById 78
************************************************************************/
CREATE     PROCEDURE [dbo].[GetViewSpeedQuoteById]  
  @SpeedQuoteId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
		BEGIN

			SELECT 
				ISNULL(leg.Name,'') AS CompanyName,
				ISNULL(adds.Line1,'') AS ComAddress1,
				ISNULL(adds.Line2,'') AS ComAddress2,
				ISNULL(adds.City,'') AS ComCity,
				ISNULL(adds.StateOrProvince,'') AS ComState,
				ISNULL(adds.PostalCode,'') AS ComPostalCode,
				ISNULL(ccon.countries_name,'') AS ComCountry,
				ISNULL(leg.PhoneNumber,'') AS ComPhoneNo,
				soq.SpeedQuoteId AS SpeedQuoteId,
				soq.SpeedQuoteNumber AS SpeedQuoteNumber,
				soq.QuoteTypeName AS QuoteTypeName,
				soq.OpenDate AS OpenDate,
				soq.ValidForDays AS ValidForDays,
				soq.QuoteExpireDate AS QuoteExpireDate,
				soq.AccountTypeName AS AccountTypeName,
				soq.CustomerId AS CustomerId,
				soq.CustomerName AS CustomerName,
				soq.CustomerCode AS CustomerCode,
				soq.CustomerContactId AS CustomerContactId,
				soq.CustomerContactName AS CustomerContactName,
				soq.CustomerContactEmail AS CustomerContactEmail,
				soq.CustomerReference AS CustomerReference,
				soq.ContractReference AS ContractReference,
				soq.SalesPersonName AS SalesPersonName,
				soq.AgentName AS AgentName,
				soq.CustomerServiceRepName AS CustomerSeviceRepName,
				soq.ProbabilityName AS ProbabilityName,
				soq.LeadSourceName AS LeadSource,
				soq.LeadSourceReference AS LeadSourceReference,
				soq.CreditLimit AS CreditLimit,
				soq.CreditLimitName AS CreditLimitName,
				soq.CreditTermName AS CreditTerms,
				soq.EmployeeName AS EmployeeName,
				soq.RestrictPMA AS RestrictPMA,
				soq.RestrictDER AS RestrictDER,
				soq.ApprovedDate AS ApprovedDate,
				soq.CurrencyId AS CurrencyId,
				soq.CurrencyName AS CurrencyName,
				soq.CustomerWarningName AS CustomerWarningMessage,
				soq.Memo AS Memo,
				soq.Notes AS Notes,
				soq.CreatedBy AS CreatedBy,
				soq.CreatedDate AS CreatedDate,
				soq.UpdatedBy AS UpdatedBy,
				soq.UpdatedDate AS UpdatedDate,
				soq.IsDeleted AS IsDeleted,
				soq.IsActive AS IsActive,
				soq.StatusName AS Status,
				soq.StatusChangeDate AS StatusChangeDate,
				soq.ManagementStructureId AS ManagementStructureId,
				soq.MasterCompanyId AS MasterCompanyId,
				soq.Version AS Version,
				soq.VersionNumber AS VersionNumber,
				soq.QtyRequested AS QtyRequested,
				soq.QtyToBeQuoted AS QtyToBeQuoted,
				soq.QuoteSentDate AS QuoteSentDate,
				(SELECT SUM(ta.TaxRate) FROM CustomerTaxTypeRateMapping cta 
					JOIN TaxRate ta ON cta.TaxRateId = ta.TaxRateId
					WHERE cta.CustomerId = soq.CustomerId
					GROUP BY cta.CustomerId
				) AS TaxRate,
				soq.IsNewVersionCreated AS IsNewVersionCreated,
				soq.Level1 AS ManagementStructureName1,
				soq.Level2 AS ManagementStructureName2,
				soq.Level3 AS ManagementStructureName3,
				soq.Level4 AS ManagementStructureName4,
				addre.Line1 AS Line1,
				addre.Line2 AS Line2,
				addre.Line3 AS Line3,
				addre.City AS City,
				addre.StateOrProvince AS StateOrProvince,
				addre.PostalCode AS PostalCode,
				ISNULL(soconty.countries_name,'') AS Country,
				con.FirstName AS FirstName,
				con.LastName AS LastName,
				cusshipping.SiteName AS CustshippingSite,
				ad.Line1 AS CustAddress1,
				ad.Line2 AS CustAddress2,
				ad.Line3 AS CustAddress3,
				ad.City AS CustCity,
				ad.StateOrProvince AS CustState,
				ad.PostalCode AS CustPostalCode,
				ISNULL(conty.countries_name,'') AS CustCountryName,
				soq.SpeedQuoteNumber,
				ISNULL(msd.EntityMSID,0) AS EntityStructureId,
				ISNULL(msd.LastMSLevel,'') AS LastMSLevel,
				ISNULL(msd.AllMSlevels,'') AS AllMSlevels

			FROM [dbo].[SpeedQuote] soq WITH(NOLOCK)
				LEFT JOIN [dbo].[Customer] cus WITH(NOLOCK) ON soq.CustomerId = cus.CustomerId
				LEFT JOIN [dbo].[CustomerDomensticShipping] cusshipping WITH(NOLOCK) ON cus.CustomerId = cusshipping.CustomerId AND cusshipping.IsPrimary = 1
				LEFT JOIN [dbo].[Address] addre WITH(NOLOCK) ON cusshipping.AddressId = addre.AddressId
				LEFT JOIN [dbo].[Countries] soconty  WITH(NOLOCK) ON addre.CountryId = soconty.countries_id
				LEFT JOIN [dbo].[CustomerContact] cuscon WITH(NOLOCK) ON cus.CustomerId = cuscon.CustomerId AND cuscon.IsDefaultContact = 1
				LEFT JOIN [dbo].[Contact] con WITH(NOLOCK) ON cuscon.ContactId = con.ContactId
				LEFT JOIN [dbo].[Address] ad WITH(NOLOCK) ON cus.AddressId = ad.AddressId
				LEFT JOIN [dbo].[Countries] conty WITH(NOLOCK) ON ad.CountryId = conty.countries_id
				     JOIN [dbo].[WorkOrderManagementStructureDetails] msd WITH(NOLOCK) ON soq.SpeedQuoteId = msd.ReferenceID AND msd.ModuleID = 27
				     JOIN [dbo].[ManagementStructureLevel] msl WITH(NOLOCK) ON msd.Level1Id = msl.ID
				     JOIN [dbo].[LegalEntity] leg WITH(NOLOCK) ON msl.LegalEntityId = leg.LegalEntityId
				LEFT JOIN [dbo].[Address] adds WITH(NOLOCK) ON leg.AddressId = adds.AddressId
				LEFT JOIN [dbo].[Countries] ccon WITH(NOLOCK) ON adds.CountryId = ccon.countries_id
			WHERE soq.SpeedQuoteId = @SpeedQuoteId;
		END

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetViewSpeedQuoteById' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SpeedQuoteId, '') + ''''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH    
END