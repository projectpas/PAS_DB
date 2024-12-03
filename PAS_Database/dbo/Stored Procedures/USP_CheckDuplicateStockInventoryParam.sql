/*************************************************************             
** File:   [USP_CheckDuplicateStockInventoryParam]             
** Author:   Devendra Shekh
** Description: This stored procedure is USED TO Check Duplicate Stock Inventory Search Params
** Date:   
         
**************************************************************             
** Change History             
**************************************************************             
** PR   Date				Author					Change Description  
** --   --------			-------					--------------------------------
** 1	3rd-DEC-2024		Devendra Shekh			Created

declare @p6 bigint
set @p6=10
exec sp_executesql N'EXEC dbo.[USP_CheckDuplicateStockInventoryParam] @StockInventorySearchParamsId, @EmployeeId, @MasterCompanyId, @StockInventoryEmployeeMappingId OUTPUT',N'@StockInventorySearchParamsId bigint,@EmployeeId bigint,@MasterCompanyId int,@StockInventoryEmployeeMappingId bigint output',@StockInventorySearchParamsId=11,@EmployeeId=186,@MasterCompanyId=1,@StockInventoryEmployeeMappingId=@p6 output
select @p6
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CheckDuplicateStockInventoryParam]
@StockInventorySearchParamsId BIGINT = NULL,
@EmployeeId BIGINT = NULL,
@MasterCompanyId INT = NULL,
@StockInventoryEmployeeMappingId BIGINT OUTPUT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN
		
		DECLARE @MappingId BIGINT = 0;
		SELECT @MappingId = StockInventoryEmployeeMappingId FROM [StockInventoryEmployeeMapping] WITH(NOLOCK) WHERE [StockInventorySearchParamsId] = @StockInventorySearchParamsId AND [EmployeeId] = @EmployeeId AND [MasterCompanyId] = @MasterCompanyId;
			
		SET @StockInventoryEmployeeMappingId = ISNULL(@MappingId, 0);	
		
    END
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_CheckDuplicateStockInventoryParam' 
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