/*************************************************************           
 ** File:   [DeleteSOQPartStocklineById]           
 ** Author:  Vishal Suthar
 ** Description: This stored procedure is used to delete Sales Order Part Stockline
 ** Purpose:         
 ** Date:   11/13/2024      
          
 ** PARAMETERS: @SalesOrderStocklineId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    11/14/2024   Vishal Suthar     Created
	2    15-09-2025	  Amit Ghediya		Update for Reset Approval Process
     
-- EXEC DeleteSOPartStocklineById 425
************************************************************************/
CREATE     PROCEDURE [dbo].[DeleteSOPartStocklineById]
	@SalesOrderStocklineId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @SalesOrderId BIGINT = NULL;
		DECLARE @SalesOrderPartId BIGINT = NULL;
		DECLARE @MasterCompanyId BIGINT = NULL;
		DECLARE @CreatedBy VARCHAR(100) = NULL;

		SELECT @SalesOrderPartId = SalesOrderPartId, @CreatedBy = CreatedBy, @MasterCompanyId = MasterCompanyId FROM DBO.[SalesOrderStocklineV1] WITH (NOLOCK) WHERE SalesOrderStocklineId = @SalesOrderStocklineId;
		SELECT @SalesOrderId = SalesOrderId FROM DBO.[SalesOrderPartV1] WITH (NOLOCK) WHERE SalesOrderPartId = @SalesOrderPartId;

		DELETE FROM [dbo].[SalesOrderStocklineV1] WHERE SalesOrderStocklineId = @SalesOrderStocklineId;
		DELETE FROM [dbo].[SalesOrderStocklineCost]  WHERE SalesOrderStocklineId = @SalesOrderStocklineId;

		EXEC [dbo].[USP_UpdateSOPartCostDetails] @SalesOrderId, @SalesOrderPartId, @CreatedBy, @MasterCompanyId;

		--Update Reset Approve Process
		EXEC [dbo].[USP_SOResetApprovalProcess] @SalesOrderId, @SalesOrderPartId,@MasterCompanyId
    END TRY    

	BEGIN CATCH      
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'DeleteSOPartStocklineById' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderStocklineId, '') + ''
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