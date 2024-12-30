/*************************************************************             
 ** File:   [GetSalesOrderMSDetails]            
 ** Author:  EKTA CHANDEGRA
 ** Description: This stored procedure is used GetSalesOrderMSDetails by SalesOrderId
 ** Purpose:           
 ** Date:  30/12/2024        
            
 ** PARAMETERS: @SalesOrderId bigint 
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    30/12/2024		EKTA CHANDEGRA	 Created  

 EXEC GetSalesOrderMSDetails 1656 
************************************************************************/ 
CREATE   PROCEDURE [dbo].[GetSalesOrderMSDetails]
    @SalesOrderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
	BEGIN TRY	
		DECLARE @ManagementStructureSOModuleId INT = 17

		SELECT 
			ISNULL(msd.EntityMSID, 0) AS MSDetailsId,
			ISNULL(msd.LastMSLevel, '') AS LastMSLevel,
			ISNULL(msd.AllMSlevels, '') AS AllMSlevels

		FROM [dbo].[SalesOrder] soq WITH(NOLOCK)
		LEFT JOIN [dbo].[SalesOrderManagementStructureDetails] msd WITH(NOLOCK) ON soq.SalesOrderId = msd.ReferenceID AND msd.ModuleID = @ManagementStructureSOModuleId 
		WHERE soq.SalesOrderId = @SalesOrderId
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
				, @AdhocComments     VARCHAR(150)    = 'GetSalesOrderMSDetails'     
				, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''
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