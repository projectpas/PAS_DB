
/*************************************************************           
 ** File:   [USP_Lot_AddUpdateLotTransInOutDetails]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to add trans In/Out Qty.
 ** Purpose:         
 ** Date:   04/07/2023      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/07/2023  Amit Ghediya    Created
     
-- EXEC USP_Lot_AddUpdateLotTransInOutDetails
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_Lot_AddUpdateLotTransInOutDetails]
	@tbl_LotTransInOutDetailsType LotTransInOutDetailsType READONLY,
	@LotTransInOutId BIGINT = NULL,
	@MasterCompanyId INT,
	@IsTransInOut INT = NULL,
	@IsInOut BIT = NULL,
	@CreatedBy VARCHAR(200),
	@UpdatedBy VARCHAR(200),
	@CreatedDate DATETIME,
	@UpdatedDate DATETIME
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @TotalCounts INT,@count INT,@LatestId BIGINT,@p1 dbo.LotCalculationDetailsType;
		DECLARE @LotId BIGINT,@isMaintainStk bit = 0; 
		SET @count = 1;

		IF OBJECT_ID(N'tempdb..#tmpLotTransInOutDetails') IS NOT NULL
		BEGIN
		DROP TABLE #tmpLotTransInOutDetails
		END
		SELECT TOP 1 @LotId = LotId from @tbl_LotTransInOutDetailsType
		SET @isMaintainStk = ISNULL((SELECT ISNULL(IsMaintainStkLine,0) FROM DBO.LotSetupMaster WHERE LotId = @LotId),0)
		CREATE TABLE #tmpLotTransInOutDetails
		(
			ID BIGINT NOT NULL IDENTITY, 
			[LotTransInOutId] BIGINT NULL,
			[StockLineId] BIGINT NULL,
			[LotId] BIGINT NULL,
			[QtyToTransIn] INT NULL,
			[QtyToTransOut] INT NULL,
			[UnitCost] DECIMAL(18,2) NULL,
			[ExtCost] DECIMAL(18,2) NULL,
			[TransInMemo] VARCHAR(256) NULL,	
			[TransOutMemo] VARCHAR(256) NULL,
			[RemainingQty] int NULL
		)
		IF(@IsInOut = 1) -- From In
		BEGIN
			INSERT INTO #tmpLotTransInOutDetails ([LotTransInOutId],[StockLineId], [LotId], [QtyToTransIn] ,QtyToTransOut,[UnitCost], [ExtCost],
												  [TransInMemo],[RemainingQty])
						SELECT [LotTransInOutId],[StockLineId], [LotId], [QtyToTransIn],0, [UnitCost], [ExtCost],
							   [TransInMemo],[QtyToTransIn]
						FROM @tbl_LotTransInOutDetailsType
		END
		ELSE -- From Out
		BEGIN
			INSERT INTO #tmpLotTransInOutDetails ([LotTransInOutId],[StockLineId], [LotId],[QtyToTransIn], [QtyToTransOut],[UnitCost], [ExtCost],
												  [TransOutMemo],[RemainingQty])
						SELECT [LotTransInOutId],[StockLineId], [LotId], [QtyToTransIn],[QtyToTransOut], [UnitCost], [ExtCost],
							   [TransOutMemo], (ISNULL([QtyToTransIn],0)-ISNULL([QtyToTransOut],0))
						FROM @tbl_LotTransInOutDetailsType
		END
		
		SELECT @TotalCounts = COUNT(ID) FROM #tmpLotTransInOutDetails;

		WHILE @count<= @TotalCounts
		BEGIN
			IF(@IsInOut = 1)
			BEGIN
				INSERT INTO [DBO].[LotTransInOutDetails](StockLineId,LotId,QtyToTransIn,TransInMemo,UnitCost,ExtCost,
					MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted,RemainingQty,IsStockLineUnitCost)
				SELECT lot.StockLineId,lot.LotId,lot.QtyToTransIn,lot.TransInMemo,lot.UnitCost,lot.ExtCost,
					@MasterCompanyId,@CreatedBy,@CreatedDate,@UpdatedBy,@UpdatedDate,1,0,RemainingQty,@isMaintainStk
				FROM #tmpLotTransInOutDetails lot 
				WHERE lot.ID = @count;

				SELECT @LatestId = SCOPE_IDENTITY();

				INSERT INTO @p1
					SELECT 0,lotadd.LotId,@LatestId,'Trans In (Lot)',0,0,lotadd.ExtCost,0,0,0,lotadd.QtyToTransIn,(ISNULL(lotadd.UnitCost,0) * ISNULL(lotadd.QtyToTransIn,0)),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
				FROM #tmpLotTransInOutDetails lotadd
				WHERE lotadd.ID = @count;
			
				EXEC [dbo].[USP_Lot_AddUpdateLotCalculationDetails] @p1,0,@LotId,'Trans In (Lot)',@MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate;
			END
			ELSE
			BEGIN
				INSERT INTO [DBO].[LotTransInOutDetails](StockLineId,LotId,QtyToTransIn,QtyToTransOut,UnitCost,ExtCost,TransOutMemo,
					MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,UpdatedDate,IsActive,IsDeleted,RemainingQty,IsStockLineUnitCost)
				SELECT lot.StockLineId,lot.LotId,lot.QtyToTransIn,lot.QtyToTransOut,lot.UnitCost,lot.ExtCost,TransOutMemo,
					@MasterCompanyId,@CreatedBy,@CreatedDate,@UpdatedBy,@UpdatedDate,1,0,RemainingQty,@isMaintainStk
				FROM #tmpLotTransInOutDetails lot 
				WHERE lot.ID = @count;

				SELECT @LatestId = SCOPE_IDENTITY();

				INSERT INTO @p1
					SELECT 0,lotadd.LotId,@LatestId,'Trans Out (Lot)',0,0,lotadd.ExtCost,0,0,0,lotadd.QtyToTransOut,0,(ISNULL(lotadd.UnitCost,0) * ISNULL(lotadd.QtyToTransOut,0)),0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
				FROM #tmpLotTransInOutDetails lotadd
				WHERE lotadd.ID = @count;
			
				EXEC [dbo].[USP_Lot_AddUpdateLotCalculationDetails] @p1,0,@LotId,'Trans Out (Lot)',@MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate;
			END
			
			DELETE FROM @p1;

			SET @count = @count + 1;
		END

		SELECT LotTransInOutId FROM [DBO].[LotTransInOutDetails] WITH (NOLOCK) WHERE LotTransInOutId = @LatestId;

    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_Lot_AddUpdateLotTransInOutDetails' 
            , @ProcedureParameters VARCHAR(3000) = '@LotTransInOutId = ''' + CAST(ISNULL(@LotTransInOutId, '') as varchar(100))
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