/***************************************************************  
 ** File:   [USP_GetShipViaAcctInfo]             
 ** Author:   Shrey Chandegara
 ** Description: Get Shipvia Acct Info
 ** Date:  10-04-2025
            
  ** Change   
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    10-04-2025		Shrey Chandegara		Created  	
		
	exec dbo.USP_GetShipViaAcctInfo 5837
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetShipViaAcctInfo]
@ShipViaId BIGINT,
@CustomerId BIGINT,
@MasterCompanyId INT

AS BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
		DECLARE @IsPrimary BIT ;
		SET @IsPrimary = 1;

		SELECT TOP 1
			CDS.ShippingAccountInfo
		FROM [dbo].[CustomerDomensticShippingShipVia] CDS WITH(NOLOCK)
		WHERE CDS.CustomerId = @CustomerId AND CDS.MasterCompanyId = @MasterCompanyId AND CDS.ShipViaId = @ShipViaId  
		ORDER BY CDS.IsPrimary

	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetShipViaAcctInfo' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ShipViaId, '')
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END