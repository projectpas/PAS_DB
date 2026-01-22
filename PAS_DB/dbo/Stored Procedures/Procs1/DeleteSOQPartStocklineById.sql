/*************************************************************           
 ** File:   [DeleteSOQPartStocklineById]           
 ** Author:  Vishal Suthar
 ** Description: This stored procedure is used to delete Sales Order Quote Part Stockline
 ** Purpose:         
 ** Date:   11/13/2024      
          
 ** PARAMETERS: @SalesOrderQuoteStocklineId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    11/13/2024   Vishal Suthar     Created
	2    15-09-2025	  Amit Ghediya		Update for Reset Approval Process
     
-- EXEC DeleteSOQPartStocklineById 425
************************************************************************/
CREATE   PROCEDURE [dbo].[DeleteSOQPartStocklineById]
	@SalesOrderQuoteStocklineId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @SalesOrderQuoteId BIGINT = NULL;
		DECLARE @SalesOrderQuotePartId BIGINT = NULL;
		DECLARE @MasterCompanyId BIGINT = NULL;
		DECLARE @CreatedBy VARCHAR(100) = NULL;

		SELECT @SalesOrderQuotePartId = SalesOrderQuotePartId, @CreatedBy = CreatedBy, @MasterCompanyId = MasterCompanyId FROM DBO.[SalesOrderQuoteStocklineV1] WITH (NOLOCK) WHERE SalesOrderQuoteStocklineId = @SalesOrderQuoteStocklineId;
		SELECT @SalesOrderQuoteId = SalesOrderQuoteId FROM DBO.[SalesOrderQuotePartV1] WITH (NOLOCK) WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId;

		DELETE FROM [dbo].[SalesOrderQuoteStocklineV1] WHERE SalesOrderQuoteStocklineId = @SalesOrderQuoteStocklineId;
		DELETE FROM [dbo].[SalesOrderQuoteStocklineCost]  WHERE SalesOrderQuoteStocklineId = @SalesOrderQuoteStocklineId;

		EXEC [dbo].[USP_UpdateSOQPartCostDetails] @SalesOrderQuoteId, @SalesOrderQuotePartId, @CreatedBy, @MasterCompanyId;

		--Update Reset Approve Process
		EXEC [dbo].[USP_SOQResetApprovalProcess] @SalesOrderQuoteId, @SalesOrderQuotePartId,@MasterCompanyId
    END TRY    

	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'DeleteSOQPartStocklineById' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderQuoteStocklineId, '') + ''
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