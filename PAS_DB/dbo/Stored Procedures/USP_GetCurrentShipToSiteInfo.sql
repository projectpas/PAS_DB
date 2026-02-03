/*************************************************************  
** Author:  <BHARGAV SALIYA>  
** Create date: <02/02/2026>  
** Description: <Get Ship To Site Data>  
 
EXEC [USP_GetCurrentShipToSiteInfo]
**************************************************************
** Change History
**************************************************************  
** PR   Date        Author				Change Description  
** --   --------    -------				--------------------------------
** 1    02/02/2026  BHARGAV SALIYA		Created

EXEC [USP_GetCurrentShipToSiteInfo]  14,10102,0

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCurrentShipToSiteInfo]              
	@MasterCompanyId BIGINT,              
	@WorkOrderQuoteId BIGINT,              
	@ShipToSiteId BIGINT = 0              
AS              
BEGIN              
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED              
 SET NOCOUNT ON;           
	DECLARE @CustomerId BIGINT = (SELECT CustomerId FROM dbo.WorkOrderQuote WITH(NOLOCK) WHERE WorkOrderQuoteId = @WorkOrderQuoteId AND MasterCompanyId = @MasterCompanyId);
	DECLARE @woqSiteId BIGINT = (SELECT ShipToSiteId FROM dbo.WorkOrderQuote WITH(NOLOCK) WHERE WorkOrderQuoteId = @WorkOrderQuoteId AND MasterCompanyId = @MasterCompanyId);
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
					WOQ.ShipToSiteName AS SiteName
					,WOQ.ShipToSiteId AS CustomerDomensticShippingId
					,WOQ.Line1 as AddressLine1
					,WOQ.Line2 as AddressLine2
					,WOQ.City as City
					,WOQ.StateOrProvince as [State]
					,WOQ.PostalCode as PostalCode
					,c.countries_name as Country
					,WOQ.CountryId AS countries_id
				FROM dbo.WorkOrderQuote WOQ WITH(NOLOCK)
				LEFT JOIN Dbo.Countries c WITH(NOLOCK) on WOQ.CountryId = c.countries_id    
				WHERE WOQ.WorkOrderQuoteId =  @WorkOrderQuoteId and WOQ.MasterCompanyId = @MasterCompanyId and ISNULL(WOQ.IsActive,1) = 1 and ISNULL(WOQ.IsDeleted,0) = 0
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
              , @AdhocComments     VARCHAR(150)    = 'USP_GetCurrentShipToSiteInfo'              
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