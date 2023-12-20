------------------------------------------------------------------------------------------------------------------

/*************************************************************           
 ** File:   [USP_UpdateChildStockline]
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to update child stocklines
 ** Purpose:
 ** Date:   04/20/2022        
          
 ** PARAMETERS:
         
 ** RETURN VALUE:
**************************************************************           
 ** Change History           
**************************************************************           
 ** PR   Date         Author    Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/20/2022   Vishal Suthar		Created

EXEC [dbo].[USP_UpdateChildStockline]  3954, 1, 22, 3954, NULL, NULL
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateChildStockline] 
(
	@StocklineId BIGINT = NULL,
	@MasterCompanyId BIGINT,
	@ModuleId INT,
	@ReferenceId INT,
	@SubModuleId INT = NULL,
	@SubReferenceId BIGINT = NULL
)
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON

    BEGIN TRY
    BEGIN TRANSACTION
      BEGIN
        DECLARE @Qty BIGINT;
		DECLARE @LoopID AS int;
		DECLARE @CurrentIdNumber AS BIGINT;
		DECLARE @IdNumber AS VARCHAR(50);
		DECLARE @IdCodeTypeId BIGINT;
		DECLARE @StocklineNumber VARCHAR(50);
		DECLARE @CurrentIndex BIGINT;
		DECLARE @NewStocklineId BIGINT;
		DECLARE @RemainingAvailableQty INT = 0;
		DECLARE @RemainingOHQty INT = 0;
		DECLARE @RemainingReservedQty INT = 0;
		DECLARE @RemainingIssuedQty INT = 0;
		DECLARE @MasterLoopID INT;
		DECLARE @StocklineToUpdate INT;
		DECLARE @IdNumberUpdated VARCHAR(50);
		DECLARE @PrevOHQty INT = 0;
		DECLARE @PrevAvailableQty INT = 0;
		DECLARE @ActionMsg VARCHAR(50) = '';
		DECLARE @AllIdNumbers VARCHAR(500) = '';

		SELECT @IdCodeTypeId = CodeTypeId FROM DBO.CodeTypes WITH (NOLOCK) Where CodeType = 'Id Number';
		
		DECLARE @StkLineNumber VARCHAR(100);
		SELECT @StkLineNumber = StockLineNumber FROM DBO.Stockline WITH (NOLOCK) WHERE StockLineId = @StockLineId

		IF(@SubReferenceId = 0)
		BEGIN
			 SET @SubReferenceId = NULL;
		END

		SELECT @RemainingAvailableQty = QuantityAvailable,
		@RemainingOHQty = QuantityOnHand,
		@StocklineNumber = StockLineNumber FROM DBO.Stockline WITH (NOLOCK) WHERE StockLineId = @StocklineId

		IF OBJECT_ID(N'tempdb..#childTableTOHtmp') IS NOT NULL
		BEGIN
			DROP TABLE #childTableTOHtmp
		END

		CREATE TABLE #childTableTOHtmp (
			ID bigint NOT NULL IDENTITY,
			StockLineId bigint NULL
		)

		INSERT INTO #childTableTOHtmp SELECT STLN.StockLineId FROM DBO.Stockline STL
		LEFT JOIN DBO.Stockline STLN WITH (NOLOCK) ON STL.StockLineId = STLN.ParentId
		WHERE STL.StockLineId = @StockLineId
		ORDER BY STLN.StockLineId DESC

		SELECT @MasterLoopID = MAX(ID) FROM #childTableTOHtmp;

		WHILE (@MasterLoopID > 0)
		BEGIN
			SELECT @StocklineToUpdate = StocklineId FROM #childTableTOHtmp WHERE ID = @MasterLoopID;
			SELECT @IdNumberUpdated = IdNumber FROM DBO.Stockline WITH (NOLOCK) WHERE StockLineId = @StocklineToUpdate
					
			DECLARE @CalculatedIssuedQtyOH INT = CASE WHEN @RemainingIssuedQty > 0 THEN 1 ELSE 0 END;
			DECLARE @CalculatedReservedQtyOH INT = CASE WHEN (@CalculatedIssuedQtyOH) > 0 THEN 0 ELSE CASE WHEN @RemainingReservedQty > 0 THEN 1 ELSE 0 END END;
			DECLARE @CalculatedOHQtyOH INT = CASE WHEN (@CalculatedIssuedQtyOH) > 0 THEN 0 ELSE CASE WHEN @RemainingOHQty > 0 THEN 1 ELSE 0 END END;
			DECLARE @CalculatedAvailableQtyOH INT = CASE WHEN @RemainingAvailableQty > 0 THEN CASE WHEN (@CalculatedReservedQtyOH + @CalculatedIssuedQtyOH) > 0 THEN 0 ELSE 1 END ELSE 0 END;

			SELECT @PrevOHQty = QuantityOnHand, @PrevAvailableQty = QuantityAvailable FROM DBO.Stockline WHERE StocklineId = @StocklineToUpdate;

			Update DBO.Stockline
			SET QuantityOnHand = @CalculatedOHQtyOH,
			QuantityAvailable = @CalculatedAvailableQtyOH
			WHERE StocklineId = @StocklineToUpdate;

			IF (@CalculatedOHQtyOH > 0)
				SET @RemainingOHQty = @RemainingOHQty - 1;
			IF (@CalculatedAvailableQtyOH > 0)
				SET @RemainingAvailableQty = @RemainingAvailableQty - 1;

			IF ((@CalculatedOHQtyOH <> @PrevOHQty) OR (@CalculatedAvailableQtyOH <> @PrevAvailableQty))
			BEGIN
				IF (@CalculatedOHQtyOH > @PrevOHQty)
				BEGIN
					SET @ActionMsg = 'Added into OH'
				END
				ELSE IF (@CalculatedOHQtyOH < @PrevOHQty)
				BEGIN
					SET @ActionMsg = 'Removed from OH'
				END

				IF (@CalculatedAvailableQtyOH > @PrevAvailableQty)
				BEGIN
					SET @ActionMsg = 'Added into Avail Qty'
				END
				ELSE IF (@CalculatedAvailableQtyOH < @PrevAvailableQty)
				BEGIN
					SET @ActionMsg = 'Removed from Avail Qty'
				END

				IF @AllIdNumbers != ''
				BEGIN
					SET @AllIdNumbers = @AllIdNumbers + ', ' + @IdNumberUpdated
				END
				ELSE
				BEGIN
					SET @AllIdNumbers = @IdNumberUpdated
				END
			END

			SET @MasterLoopID = @MasterLoopID - 1;
		END
	END

	IF (@AllIdNumbers <> '')
	BEGIN
		INSERT INTO [dbo].[StocklineHistory] ([ModuleId], [RefferenceId], [SubModuleId], [SubReferenceId], [StocklineId], [QuantityAvailable], [QuantityOnHand], [QuantityReserved], [QuantityIssued], [TextMessage], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate],[MasterCompanyId])
		SELECT @ModuleId, @ReferenceId, @SubModuleId, @SubReferenceId, @StockLineId, STL.QuantityAvailable, STL.QuantityOnHand, STL.QuantityReserved, STL.QuantityIssued, 'Stockline ('+ @AllIdNumbers +') ' + @ActionMsg, 'AUTO SCRIPT', GETDATE(), 'AUTO SCRIPT', GETDATE(), @MasterCompanyId 
		FROM DBO.Stockline STL WITH (NOLOCK) WHERE StockLineId = @StocklineId
	END

    COMMIT TRANSACTION

  END TRY
  BEGIN CATCH
    IF @@trancount > 0
		ROLLBACK TRAN;
		DECLARE @ErrorLogID int
		,@DatabaseName varchar(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
		,@AdhocComments varchar(150) = 'USP_UpdateChildStockline'
		,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(@StocklineId, '') + ''
		,@ApplicationName varchar(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END