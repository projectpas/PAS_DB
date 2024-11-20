/*************************************************************               
 ** File:   [USP_CycleCount_UpdateStockline_DetailsById]               
 ** Author:   Moin Bloch
 ** Description:         
 ** Purpose:             
 ** Date:   07/11/2024            
              
 ** RETURN VALUE:               
      
 **************************************************************               
  ** Change History               
 **************************************************************               
 ** PR   Date         Author       Change Description                
 ** --   --------     -------      --------------------------------              
    1    07/11/2024   Moin Bloch   Created    
	2    12/11/2024   Moin Bloch   Added Acconting Batch SP and [CycleCountDetailId] In Temp Table 
	3    14/11/2024   Moin Bloch   Added Clsoed Condition FOR UNIT COST 0 
	4    19/11/2024   Moin Bloch   Added Paramiter LedgerId,AccountingCalendarId  
         
 EXEC USP_CycleCount_UpdateStockline_DetailsById  26,'ADMIN User',1
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CycleCount_UpdateStockline_DetailsById]
@CycleCountId BIGINT,
@LedgerId BIGINT,
@AccountingCalendarId BIGINT,
@UpdatedBy VARCHAR(50),
@MasterCompanyId INT
AS 
BEGIN		
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED		
	BEGIN TRY
	BEGIN TRANSACTION  
		BEGIN   
		DECLARE @TotalRecord int = 0;   
		DECLARE @MinId BIGINT = 1;
		DECLARE @CycleCountDetailId BIGINT;
		DECLARE @StockLineId BIGINT;
		DECLARE @UnitCost DECIMAL(18,2) = 0;
		DECLARE @CurrentStockQuantity INT = 0;
		DECLARE @CountedQuantity INT = 0;
		DECLARE @DifferenceQuantity INT = 0;
		DECLARE @DifferenceAmount DECIMAL(18,2) = 0;
		DECLARE @DifferenceQty INT = 0;
		DECLARE @CCModuleId INT;	
		DECLARE	@ActionId INT;
		DECLARE @CycleCountStatusId INT;
		DECLARE @JournalBatchHeaderId BIGINT;
		DECLARE @BatchName VARCHAR(200) = '';

		SELECT @CycleCountStatusId = [CycleCountStatusId] FROM [dbo].[CycleCountStatus] WITH(NOLOCK) WHERE UPPER([Status]) = 'CLOSED';

		SELECT @CCModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE UPPER([ModuleName]) = 'CYCLECOUNT';

		IF OBJECT_ID(N'tempdb..#tmpCycleCountStocklineDetails') IS NOT NULL
		BEGIN
			DROP TABLE #tmpCycleCountStocklineDetails
		END
					  	  
		CREATE TABLE #tmpCycleCountStocklineDetails
		(
			[ID] BIGINT NOT NULL IDENTITY, 
			[CycleCountDetailId] BIGINT NULL,
			[StockLineId] BIGINT NULL,
			[UnitCost] DECIMAL(18,2) NULL,
			[CurrentStockQuantity] INT NULL,
			[CountedQuantity] INT NULL,
			[DifferenceQuantity] INT NULL,
			[DifferenceAmount] DECIMAL(18,2) NULL			
		)  

		INSERT INTO #tmpCycleCountStocklineDetails ([CycleCountDetailId],[StockLineId],[UnitCost],[CurrentStockQuantity],[CountedQuantity],[DifferenceQuantity],[DifferenceAmount])
		SELECT [CycleCountDetailId],[StockLineId],[UnitCost],[CurrentStockQuantity],[CountedQuantity],[DifferenceQuantity],[DifferenceAmount]
		  FROM [dbo].[CycleCountDetail] WITH(NOLOCK)
		 WHERE [MasterCompanyId] = @MasterCompanyId 
		   AND [CycleCountId] = @CycleCountId  
		   AND [IsActive] = 1 AND IsDeleted = 0;		

		SELECT @TotalRecord = COUNT(*), @MinId = MIN(ID) FROM #tmpCycleCountStocklineDetails    

		WHILE @MinId <= @TotalRecord
		BEGIN				
			SELECT @CycleCountDetailId = [CycleCountDetailId],
			       @StockLineId = [StockLineId],
                   @UnitCost = ISNULL([UnitCost],0),
                   @CurrentStockQuantity = ISNULL([CurrentStockQuantity],0),
                   @CountedQuantity = ISNULL([CountedQuantity],0),
                   @DifferenceQuantity = ISNULL([DifferenceQuantity],0),
                   @DifferenceAmount = ISNULL([DifferenceAmount],0)
			  FROM #tmpCycleCountStocklineDetails WHERE [ID] = @MinId
				
			IF(@CurrentStockQuantity > @CountedQuantity)	
			BEGIN 
				SET @DifferenceQty = @CurrentStockQuantity - @CountedQuantity;				
				SET @ActionId = (SELECT [ActionId] FROM DBO.[StklineHistory_Action] ITH  WITH(NOLOCK) WHERE UPPER([Type]) = 'ADJUSTMENT-DECREASE-CYCLECOUNT');
				UPDATE [dbo].[Stockline] 
				   SET [QuantityOnHand] = @CountedQuantity,
					   [QuantityAvailable] = [QuantityAvailable] - @DifferenceQty,	 
				       [UpdatedBy] = @UpdatedBy,
					   [UpdatedDate] = GETUTCDATE()
				 WHERE [StockLineId] = @StockLineId;
				
				-- StockLine History
				EXEC [dbo].[USP_AddUpdateStocklineHistory] @StockLineId,@CCModuleId,@CycleCountId,NULL,NULL,@ActionId,@DifferenceQty,@UpdatedBy;
			    
				-- Accounting Entry
				IF(ISNULL(@DifferenceAmount,0) <> 0)
				BEGIN
					EXEC [dbo].[USP_PostCycleCountBatchDetails] @CycleCountId,@CycleCountDetailId,@StockLineId,@DifferenceAmount,@LedgerId,@AccountingCalendarId,@UpdatedBy,@MasterCompanyId
				END
			END
			IF(@CurrentStockQuantity < @CountedQuantity)	
			BEGIN 
				SET @DifferenceQty = @CountedQuantity - @CurrentStockQuantity;
				SET @ActionId = (SELECT [ActionId] FROM DBO.[StklineHistory_Action] ITH  WITH(NOLOCK) WHERE UPPER([Type]) = 'ADJUSTMENT-INCREASE-CYCLECOUNT');
				UPDATE [dbo].[Stockline] 
				   SET [QuantityOnHand] = @CountedQuantity,
					   [QuantityAvailable] = [QuantityAvailable] + @DifferenceQty,	 
				       [UpdatedBy] = @UpdatedBy,
					   [UpdatedDate] = GETUTCDATE()
				 WHERE [StockLineId] = @StockLineId;
				
				-- StockLine History
				EXEC [dbo].[USP_AddUpdateStocklineHistory] @StockLineId,@CCModuleId,@CycleCountId,NULL,NULL,@ActionId,@DifferenceQty,@UpdatedBy;
				
				-- Accounting Entry
				IF(ISNULL(@DifferenceAmount,0) <> 0)
				BEGIN
					EXEC [dbo].[USP_PostCycleCountBatchDetails] @CycleCountId,@CycleCountDetailId,@StockLineId,@DifferenceAmount,@LedgerId,@AccountingCalendarId,@UpdatedBy,@MasterCompanyId		
				END
			END
			SET @MinId = @MinId + 1
		END	

		SELECT TOP 1 @JournalBatchHeaderId = [JournalBatchHeaderId]	FROM [dbo].[CycleCountBatchDetails] WITH(NOLOCK) WHERE [ReferenceId] = @CycleCountId AND [MasterCompanyId] = @MasterCompanyId;
		
		IF(ISNULL(@JournalBatchHeaderId,0) > 0)
		BEGIN
			SELECT @BatchName = [BatchName] FROM [dbo].[BatchHeader] WITH(NOLOCK) WHERE [JournalBatchHeaderId] = @JournalBatchHeaderId;

			UPDATE [dbo].[CycleCount] SET [StatusId] = @CycleCountStatusId,[BatchName] = @BatchName, [PostedDate] = GETUTCDATE() WHERE [CycleCountId] = @CycleCountId;
		END	
		ELSE
		BEGIN
			UPDATE [dbo].[CycleCount] SET [StatusId] = @CycleCountStatusId,[PostedDate] = GETUTCDATE() WHERE [CycleCountId] = @CycleCountId;
		END
		
		COMMIT  TRANSACTION 			
	END
	END TRY  
	BEGIN CATCH      
	IF @@trancount > 0
	DECLARE @ErrorNumber INT = ERROR_NUMBER();    
    -- Existing error handling
    RAISERROR('Unexpected Error Occurred in the database. Please let the support team know of the error number: %d', 16, 1, @ErrorNumber);
    ROLLBACK TRANSACTION;
    RETURN(1);
		PRINT 'ROLLBACK'
        ROLLBACK TRAN;
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_CycleCount_UpdateStockline_DetailsById' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL('', '') + ''													   
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
