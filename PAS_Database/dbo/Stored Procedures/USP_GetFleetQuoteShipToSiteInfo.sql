/*************************************************************
** Author:  Kishor Makwana
** Create date: 09/10/2026
** Description: Get Ship-To Site data for the Aircraft / Fleet Quote
**              header's Ship-To Site popup. Same convention as
**              dbo.USP_GetCurrentShipToSiteInfo (see PN-17698), minus
**              the Work Order Quote branch - a Fleet Quote has no
**              FleetQuoteId to key off, and its OWN current
**              Ship-To Site is already loaded directly off
**              dbo.FleetQuote (ShipToSiteId/Line1/Line2/...), so this
**              procedure only needs to resolve either a specific site
**              (the popup's "New Ship-To Site" pick) or, when none is
**              given, the customer's primary domestic shipping site.

EXEC [USP_GetFleetQuoteShipToSiteInfo]
**************************************************************
** Change History
**************************************************************
** PR   Date        Author				Change Description
** --   --------    -------				--------------------------------
** 1    09/10/2026  Kishor Makwana		Created [PN-17698]

EXEC [USP_GetFleetQuoteShipToSiteInfo]  14,10102,0

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetFleetQuoteShipToSiteInfo]
	@MasterCompanyId BIGINT,
	@FleetQuoteId BIGINT,
	@ShipToSiteId BIGINT = 0
AS
BEGIN              
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED              
 SET NOCOUNT ON;           
	DECLARE @CustomerId BIGINT = (SELECT CustomerId FROM dbo.FleetQuote WITH(NOLOCK) WHERE FleetQuoteId = @FleetQuoteId AND MasterCompanyId = @MasterCompanyId);
	DECLARE @woqSiteId BIGINT = (SELECT ShipToSiteId FROM dbo.FleetQuote WITH(NOLOCK) WHERE FleetQuoteId = @FleetQuoteId AND MasterCompanyId = @MasterCompanyId);
  BEGIN TRY  
		IF(@ShipToSiteId > 0)
		BEGIN
			SELECT 
				cd.SiteName
				,cd.CustomerDomensticShippingId
				,a.Line1 as AddressLine1
				,a.Line2 as AddressLine2
				,a.City as City
				,a.StateOrProvince as [State]
				,a.PostalCode as PostalCode
				,c.countries_name as Country
				,c.countries_id
			FROM dbo.CustomerDomensticShipping cd WITH(NOLOCK)
			LEFT JOIN Dbo.[Address] a WITH(NOLOCK) on CD.AddressId = a.AddressId    
			LEFT JOIN Dbo.Countries c WITH(NOLOCK) on a.CountryId = c.countries_id    
			WHERE cd.CustomerDomensticShippingId =  @ShipToSiteId and cd.MasterCompanyId = @MasterCompanyId and ISNULL(cd.IsActive,1) = 1 and ISNULL(cd.IsDeleted,0) = 0
		END
		ELSE
		BEGIN
			IF(ISNULL(@woqSiteId,0) > 0)
			BEGIN
				SELECT 
					FQ.ShipToSiteName AS SiteName
					,FQ.ShipToSiteId AS CustomerDomensticShippingId
					,FQ.Line1 as AddressLine1
					,FQ.Line2 as AddressLine2
					,FQ.City as City
					,FQ.StateOrProvince as [State]
					,FQ.PostalCode as PostalCode
					,c.countries_name as Country
					,FQ.CountryId AS countries_id
				FROM dbo.FleetQuote FQ WITH(NOLOCK)
				LEFT JOIN Dbo.Countries c WITH(NOLOCK) on FQ.CountryId = c.countries_id    
				WHERE FQ.FleetQuoteId =  @FleetQuoteId and FQ.MasterCompanyId = @MasterCompanyId and ISNULL(FQ.IsActive,1) = 1 and ISNULL(FQ.IsDeleted,0) = 0
			END
			ELSE
			BEGIN
				SELECT 
					cd.SiteName
					,cd.CustomerDomensticShippingId
					,a.Line1 as AddressLine1
					,a.Line2 as AddressLine2
					,a.City as City
					,a.StateOrProvince as [State]
					,a.PostalCode as PostalCode
					,c.countries_name as Country
					,c.countries_id
				FROM dbo.CustomerDomensticShipping cd WITH(NOLOCK)
				LEFT JOIN Dbo.[Address] a WITH(NOLOCK) on CD.AddressId = a.AddressId    
				LEFT JOIN Dbo.Countries c WITH(NOLOCK) on a.CountryId = c.countries_id    
				WHERE cd.CustomerId =  @CustomerId and ISNULL(cd.IsPrimary,0) = 1 and cd.MasterCompanyId = @MasterCompanyId and ISNULL(cd.IsActive,1) = 1 and ISNULL(cd.IsDeleted,0) = 0
			END
		END
  END TRY                  
  BEGIN CATCH                    
   IF @@trancount > 0              
    PRINT 'ROLLBACK'              
    --ROLLBACK TRAN;              
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()              
             
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------              
              , @AdhocComments     VARCHAR(150)    = 'USP_GetFleetQuoteShipToSiteInfo'              
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CustomerId, '') + '''              
                @Parameter2 = ' + ISNULL(@MasterCompanyId ,'') +''              
              , @ApplicationName VARCHAR(100) = 'PAS'              
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------              
             
              exec spLogException              
                       @DatabaseName           = @DatabaseName              
                     , @AdhocComments          = @AdhocComments              
                     , @ProcedureParameters    = @ProcedureParameters              
                     , @ApplicationName        = @ApplicationName              
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;              
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)              
              RETURN(1);              
  END CATCH              
END