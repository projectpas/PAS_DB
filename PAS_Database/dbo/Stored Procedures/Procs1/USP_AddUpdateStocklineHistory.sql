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
  
 EXEC [dbo].[USP_AddUpdateStocklineHistory] 39974, 15, 6, NULL, NULL, 2, 2
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddUpdateStocklineHistory]
(
	@StocklineId BIGINT = NULL,
	@ModuleId BIGINT = NULL,
	@ReferenceId BIGINT = NULL,
	@SubModuleId BIGINT = NULL,
	@SubRefferenceId BIGINT = NULL,
	@ActionId INT = NULL,
	@Qty INT = NULL,
	@UpdatedBy VARCHAR(100) = NULL
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

		DECLARE @CustStockActionId as BIGINT = 0;
		SELECT @CustStockActionId = ActionId FROM DBO.[StklineHistory_Action] WITH (NOLOCK) WHERE [Type] = 'Add-From-CustStock'

		SELECT @ModuleName = M.ModuleName FROM DBO.Module M WITH (NOLOCK) WHERE M.ModuleId = @ModuleId;
		SELECT @SubModuleName = M.ModuleName FROM DBO.Module M WITH (NOLOCK) WHERE M.ModuleId = @ModuleId;

		SELECT @ActionType = StkAct.[DisplayName] FROM DBO.[StklineHistory_Action] StkAct WITH (NOLOCK) WHERE StkAct.ActionId = @ActionId;

		SELECT @ReferenceNumber = [dbo].[udfGetModuleReferenceByModuleId] (@ModuleId, @ReferenceId, 1);
		SELECT @SubReferenceNumber = [dbo].[udfGetModuleReferenceByModuleId] (@SubModuleId, @SubRefferenceId, 2);

		SELECT @StkLineNumber = StockLineNumber, @MasterCompanyId = MasterCompanyId FROM DBO.Stockline WITH (NOLOCK) WHERE StockLineId = @StockLineId;

		SELECT @HistoryNote = StkAct.Template FROM DBO.[StklineHistory_Action] StkAct WITH (NOLOCK) WHERE StkAct.ActionId = @ActionId;

		SET @HistoryNote = REPLACE(REPLACE(@HistoryNote, '#qty#', @Qty), '#StkNum#', @StkLineNumber);

		SET @HistoryNote = REPLACE(@HistoryNote, '#ModuleName#', @ModuleName);
		SET @HistoryNote = REPLACE(@HistoryNote, '#RefferenceNum#', @ReferenceNumber);

		INSERT INTO [dbo].[Stkline_History] ([StocklineId],[ModuleId],[RefferenceId],[RefferenceNumber],[SubModuleId],[SubRefferenceId],[SubRefferenceNumber],[ActionId],[Type],
			[QtyOH],[QtyAvailable],[QtyReserved],[QtyIssued],[QtyOnAction],[Notes],[UpdatedBy],[UpdatedDate],UnitSalesPrice,SalesPriceExpiryDate)
		SELECT @StockLineId, @ModuleId, @ReferenceId, @ReferenceNumber, @SubModuleId, @SubRefferenceId, @SubReferenceNumber, @ActionId, @ActionType, 
			STL.QuantityOnHand, STL.QuantityAvailable, STL.QuantityReserved, STL.QuantityIssued, @Qty, @HistoryNote, @UpdatedBy, GETUTCDATE(),UnitSalesPrice,SalesPriceExpiryDate
		FROM DBO.[Stockline] STL WITH (NOLOCK) WHERE StockLineId = @StocklineId;

		IF(@CustStockActionId=@ActionId)
		BEGIN
			UPDATE DBO.[Stockline] SET [Memo] = @HistoryNote WHERE StockLineId = @StocklineId
		END

		EXEC DBO.USP_AddUpdateChildStockline @StocklineId = @StocklineId, @ActionId = @ActionId, @QtyOnAction = @Qty, @ModuleName = @ModuleName, @ReferenceNumber = @ReferenceNumber, @SubModuleName = @SubModuleName, @SubReferenceNumber = @SubReferenceNumber, @UpdatedBy = @UpdatedBy;
	END
    COMMIT TRANSACTION
  END TRY
  BEGIN CATCH
    IF @@trancount > 0
  ROLLBACK TRAN;
  DECLARE @ErrorLogID int
  ,@DatabaseName varchar(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
  ,@AdhocComments varchar(150) = 'USP_AddUpdateStocklineHistory'
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