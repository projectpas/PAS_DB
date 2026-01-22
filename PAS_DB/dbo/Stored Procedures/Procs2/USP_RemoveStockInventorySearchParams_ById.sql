/*************************************************************   
** Author:  <BHARGAV SALIYA>  
** Create date: <20/11/2024>  [mm/dd/yyyy]
** Description: <Remove Ledger Search Params For Employee Mapping Data>  
************************************************************** 
** Change History 
**************************************************************   
** PR   Date			Author					Change Description  
** --   --------		-------					--------------------------------
** 1	20/11/2024		BHARGAV SALIYA			Created
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_RemoveStockInventorySearchParams_ById]
	@StockInventoryEmployeeMappingId BIGINT = NULL,
	@StockInventorySearchParamsId BIGINT = NULL
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
		BEGIN TRY
			BEGIN
				DECLARE @EmployeeCount INT = 0;

				DELETE FROM [dbo].[StockInventoryEmployeeMapping] WHERE [StockInventoryEmployeeMappingId] = @StockInventoryEmployeeMappingId

				SELECT @EmployeeCount = COUNT(StockInventoryEmployeeMappingId) FROM [dbo].[StockInventoryEmployeeMapping] WITH(NOLOCK) WHERE [StockInventorySearchParamsId] = @StockInventorySearchParamsId;

				IF(ISNULL(@EmployeeCount, 0) = 0)
				BEGIN
					DELETE FROM [dbo].[StockInventorySearchParams] WHERE [StockInventorySearchParamsId] = @StockInventorySearchParamsId;
				END
			END
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_RemoveStockInventorySearchParams_ById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
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