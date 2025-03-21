/*************************************************************           
 ** File:   [dbo].[CreateStockLineHistory]
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to Add Update Stock Line History
 ** Purpose:         
 ** Date:   18/03/2025        
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    18/03/2025   Moin Bloch    Created
     
--   EXEC [dbo].[CreateStockLineHistory]
**************************************************************/
CREATE   PROCEDURE [dbo].[CreateStockLineHistory]
@tbl_WorkOrderPartNumberType WorkOrderPartNumberType READONLY,
@WorkOrderId BIGINT,
@CreatedBy VARCHAR(256),
@CreatedDate DATETIME2(7),
@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN	
		DECLARE @TotalRecord INT = 0,@MinId BIGINT = 1
		DECLARE @WorkOrderModuleEnum INT = 15, @StocklineHistoryReserveActionEnum INT = 2
					
		SELECT @WorkOrderModuleEnum = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]='WorkOrder';

		SELECT @StocklineHistoryReserveActionEnum = [ActionId] FROM [dbo].[StklineHistory_Action] WITH(NOLOCK) WHERE [Type]='Reserve';

		IF OBJECT_ID(N'tempdb..#tempCreateStockLineHistoryForCreateWO') IS NOT NULL
		BEGIN
			DROP TABLE #tempCreateStockLineHistoryForCreateWO
		END	
	
		CREATE TABLE #tempCreateStockLineHistoryForCreateWO
		(
			[PKID] [BIGINT] NOT NULL IDENTITY, 
			[ID] [BIGINT] NULL,
			[StockLineId] [BIGINT] NULL				
		)
		
		INSERT INTO #tempCreateStockLineHistoryForCreateWO([ID],[StockLineId])
		SELECT [ID],[StockLineId] FROM @tbl_WorkOrderPartNumberType

		SELECT @TotalRecord = COUNT(*), @MinId = MIN([PKID]) FROM #tempCreateStockLineHistoryForCreateWO  

		WHILE @MinId <= @TotalRecord
		BEGIN
			DECLARE @StockLineId BIGINT = NULL,@QuantityReserved INT = 0
		
			SELECT @StockLineId = [StockLineId] FROM #tempCreateStockLineHistoryForCreateWO WHERE [PKID] = @MinId
			
			IF(@StockLineId > 0)
			BEGIN		
				SELECT @QuantityReserved = ISNULL([QuantityReserved],0) FROM [dbo].[StockLine] WITH(NOLOCK) WHERE [StockLineId] = @StockLineId;

				EXEC [dbo].[USP_AddUpdateStocklineHistory] @StockLineId,@WorkOrderModuleEnum,@WorkOrderId,NULL,NULL,@StocklineHistoryReserveActionEnum,@QuantityReserved,@CreatedBy;
			END		
			
			SET @MinId = @MinId + 1
		END	
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
        ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'CreateStockLineHistory' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100)) + 
			                                         '@Parameter2 = ''' + CAST(ISNULL(@CreatedBy, '') AS VARCHAR(100))
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