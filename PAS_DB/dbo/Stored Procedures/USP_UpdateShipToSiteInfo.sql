
/*************************************************************  
** Author:  <BHARGAV SALIYA>  
** Create date: <02/02/2026>  
** Description: <Update WorkOrder Quote Ship To Site Info>  
 
EXEC [USP_GetCurrentShipToSiteInfo]
**************************************************************
** Change History
**************************************************************  
** PR   Date        Author				Change Description  
** --   --------    -------				--------------------------------
** 1    02/02/2026  BHARGAV SALIYA		Created

EXEC [USP_GetCurrentShipToSiteInfo] 3571,4128

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateShipToSiteInfo]              
	@WorkOrderQuoteId BIGINT,              
	@CustomerId BIGINT,              
	@SiteName VARCHAR(50),              
	@AddressLine1 VARCHAR(50),              
	@AddressLine2 VARCHAR(50) = NULL,              
	@City VARCHAR(50),              
	@State VARCHAR(50),              
	@PostalCode VARCHAR(50),              
	@CountryId BIGINT,              
	@MasterCompanyId INT,              
	@ShipToSiteId BIGINT              
AS              
BEGIN              
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED              
 SET NOCOUNT ON;              
             
  BEGIN TRY  
		IF EXISTS (SELECT TOP 1 WorkOrderQuoteId FROM dbo.WorkOrderQuote WITH(NOLOCK) WHERE WorkOrderQuoteId = @WorkOrderQuoteId AND MasterCompanyId = @MasterCompanyId)
		BEGIN
			UPDATE WOQ
			SET 
				ShipToSiteName = @SiteName,
				Line1 = @AddressLine1,
				Line2 = @AddressLine2,
				City = @City,
				StateOrProvince = @State,
				PostalCode = @PostalCode,
				CountryId = @CountryId,
				ShipToSiteId = @ShipToSiteId
			FROM dbo.WorkOrderQuote WOQ WITH(NOLOCK)
			WHERE WOQ.WorkOrderQuoteId = @WorkOrderQuoteId AND MasterCompanyId = @MasterCompanyId AND WOQ.CustomerId = @CustomerId AND ISNULL(WOQ.IsActive,1) = 1 AND ISNULL(WOQ.IsDeleted,0) = 0
		END
  END TRY                  
  BEGIN CATCH                    
   IF @@trancount > 0              
    PRINT 'ROLLBACK'              
    --ROLLBACK TRAN;              
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()              
             
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------              
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateShipToSiteInfo'              
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderQuoteId, '') + '''              
                @Parameter2 = ' + ISNULL(@CustomerId ,'') +''              
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