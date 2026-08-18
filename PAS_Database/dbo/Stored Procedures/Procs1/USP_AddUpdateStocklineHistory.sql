/*************************************************************             
 ** File:   [USP_AddUpdateStocklineHistory]            
 ** Author:   Vishal Suthar  
 ** Description: This stored procedure is used to add/update stockline history 
 ** Purpose:           
 ** Date:   07/10/2023

 ** PARAMETERS:

 ** RETURN VALUE:

 **************************************************************
  ** Change History             
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-----------------------
    1    07/10/2023   Vishal Suthar		Created
	2    6 Nov 2023  Rajesh Gami        SalesPrice Expriry Date And UnitSalesPrice related change
	3    12/08/2024  Moin Bloch         Convert @StocklineId To varchar for Errolog
 	4	 25/11/2025		Rajesh Gami		Change the stockline Quantiy related fields datatype INT to DECIMAL 
	5    16/06/2026   Priyansh Patel 	Removed the ChildStockline Sp call [PN-16124]
	6    01/07/2026   Ayushi Patel		[PN-17083]Added @StockOldUOM/@StockNewUOM for UOM-Update history template
	7	 09/07/2026   Ayushi Patel		[PN-17083]Added new field UOM into Stkline_History table
	8	 16/07/2026   Rajesh Gami		[PN-17308]Qty handle by 2 decimal places for the notes 
 EXEC [dbo].[USP_AddUpdateStocklineHistory] 163201, 16, 259, NULL, NULL, 16, 0, 'Admin User'
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddUpdateStocklineHistory]
(
	@StocklineId BIGINT = NULL,
	@ModuleId BIGINT = NULL,
	@ReferenceId BIGINT = NULL,
	@SubModuleId BIGINT = NULL,
	@SubRefferenceId BIGINT = NULL,
	@ActionId INT = NULL,
	@Qty decimal(18,6) = NULL,
	@UpdatedBy VARCHAR(100) = NULL,
	@StockOldUOM VARCHAR(250) = NULL,
	@StockNewUOM VARCHAR(250) = NULL
)
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON
  
    BEGIN TRY  
    BEGIN TRANSACTION  
    BEGIN
		DECLARE @MasterCompanyId BIGINT;
		DECLARE @StkLineNumber VARCHAR(100);
		DECLARE @HistoryNote NVARCHAR(MAX);
		DECLARE @ModuleName VARCHAR(100) = '';
		DECLARE @SubModuleName VARCHAR(100) = '';
		DECLARE @ReferenceNumber VARCHAR(100) = '';
		DECLARE @SubReferenceNumber VARCHAR(100) = '';
		DECLARE @ActionType VARCHAR(100) = '';
		DECLARE @IsSerialized BIT = 0;

		DECLARE @CustStockActionId as BIGINT = 0;
		SELECT @CustStockActionId = ActionId FROM DBO.[StklineHistory_Action] WITH (NOLOCK) WHERE [Type] = 'Add-From-CustStock'

		SELECT @ModuleName = M.ModuleName FROM DBO.Module M WITH (NOLOCK) WHERE M.ModuleId = @ModuleId;
		SELECT @SubModuleName = M.ModuleName FROM DBO.Module M WITH (NOLOCK) WHERE M.ModuleId = @ModuleId;

		SELECT @ActionType = StkAct.[DisplayName] FROM DBO.[StklineHistory_Action] StkAct WITH (NOLOCK) WHERE StkAct.ActionId = @ActionId;

		SELECT @ReferenceNumber = [dbo].[udfGetModuleReferenceByModuleId] (@ModuleId, @ReferenceId, 1);
		SELECT @SubReferenceNumber = [dbo].[udfGetModuleReferenceByModuleId] (@SubModuleId, @SubRefferenceId, 2);

		SELECT @StkLineNumber = StockLineNumber, @MasterCompanyId = MasterCompanyId, @IsSerialized = isSerialized FROM DBO.Stockline WITH (NOLOCK) WHERE StockLineId = @StockLineId;

		SELECT @HistoryNote = StkAct.Template FROM DBO.[StklineHistory_Action] StkAct WITH (NOLOCK) WHERE StkAct.ActionId = @ActionId;

		SET @HistoryNote = REPLACE(REPLACE(@HistoryNote, '#qty#',  CONVERT(VARCHAR(50), CAST(@Qty AS DECIMAL(18,2)))), '#StkNum#', @StkLineNumber);

		SET @HistoryNote = REPLACE(@HistoryNote, '#ModuleName#', @ModuleName);
		SET @HistoryNote = REPLACE(@HistoryNote, '#RefferenceNum#', @ReferenceNumber);

		SET @HistoryNote = REPLACE(@HistoryNote, '#StockOldUOM#', ISNULL(@StockOldUOM, ''));
		SET @HistoryNote = REPLACE(@HistoryNote, '#StockNewUOM#', ISNULL(@StockNewUOM, ''));

		INSERT INTO [dbo].[Stkline_History] ([StocklineId],[ModuleId],[RefferenceId],[RefferenceNumber],[SubModuleId],[SubRefferenceId],[SubRefferenceNumber],[ActionId],[Type],
			[QtyOH],[QtyAvailable],[QtyReserved],[QtyIssued],[QtyOnAction],[Notes],[UpdatedBy],[UpdatedDate],UnitSalesPrice,SalesPriceExpiryDate,UOM)
		SELECT @StockLineId, @ModuleId, @ReferenceId, @ReferenceNumber, @SubModuleId, @SubRefferenceId, @SubReferenceNumber, @ActionId, @ActionType, 
			STL.QuantityOnHand, STL.QuantityAvailable, STL.QuantityReserved, STL.QuantityIssued, @Qty, @HistoryNote, @UpdatedBy, GETUTCDATE(),UnitSalesPrice,SalesPriceExpiryDate,CASE WHEN ISNULL(@StockNewUOM, '') <> '' THEN @StockNewUOM ELSE STL.StockUnitOfMeasure END
		FROM DBO.[Stockline] STL WITH (NOLOCK) WHERE StockLineId = @StocklineId;

		IF(@CustStockActionId=@ActionId)
		BEGIN
			UPDATE DBO.[Stockline] SET [Memo] = @HistoryNote WHERE StockLineId = @StocklineId
		END

		IF (@ActionId = 8 AND ISNULL(@IsSerialized, 0) = 0 AND @Qty > 200)
		BEGIN
			PRINT '';
		END
		--ELSE
		--BEGIN
		--	EXEC DBO.USP_AddUpdateChildStockline @StocklineId = @StocklineId, @ActionId = @ActionId, @QtyOnAction = @Qty, @ModuleName = @ModuleName, @ReferenceNumber = @ReferenceNumber, @SubModuleName = @SubModuleName, @SubReferenceNumber = @SubReferenceNumber, @UpdatedBy = @UpdatedBy;
		--END
	END
    COMMIT TRANSACTION
  END TRY
  BEGIN CATCH
    IF @@trancount > 0
  ROLLBACK TRAN;
  SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
  DECLARE @ErrorLogID int
  ,@DatabaseName varchar(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
  ,@AdhocComments varchar(150) = 'USP_AddUpdateStocklineHistory'  
  ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StocklineId, '') AS VARCHAR(100))  
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