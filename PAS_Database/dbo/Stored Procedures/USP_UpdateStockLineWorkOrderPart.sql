/*************************************************************             
 ** File:   [USP_UpdateStockLineWorkOrderPart]            
 ** Author:    Priyansh Patel  
 ** Description: This stored procedure is used to add/update stockline history 
 ** Purpose:           
 ** Date:   04/11/2025 

 **************************************************************
  ** Change History             
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-----------------------
    1    04/11/2025   Priyansh Patel	Created
	2    25/11/2025   Moin Bloch		Format SP
	
 EXEC [dbo].[USP_UpdateStockLineWorkOrderPart] 1052,'ADMIN',2,4,6,5,6,1,1
**************************************************************/
CREATE PROCEDURE [dbo].[USP_UpdateStockLineWorkOrderPart]
(
    @WorkOrderPartNoId BIGINT,
    @UpdatedBy NVARCHAR(100),
    @NPMStockQTY INT,
	@ModuleId BIGINT = NULL,
	@SubModuleId BIGINT = NULL,
	@SubRefferenceId BIGINT = NULL,
	@ActionId INT = NULL,
	@Qty INT = NULL,
	@MasterCompanyId INT
)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
  
    BEGIN TRY  
    BEGIN TRANSACTION  
    BEGIN

    DECLARE @StockLineId BIGINT;
    DECLARE @WorkOrderId BIGINT;

    -- Get WorkOrderPartNumber info
     SELECT @StockLineId = ISNULL(WOP.StockLineId, 0),
	        @WorkOrderId = ISNULL(WOP.WorkOrderId, 0) 
	   FROM [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) 
	   INNER JOIN [dbo].[MasterCompany] MC WITH(NOLOCK) ON MC.[MasterCompanyId] = WOP.[MasterCompanyId]
       WHERE WOP.[ID] = @WorkOrderPartNoId AND WOP.[MasterCompanyId] = @MasterCompanyId;

    -- Update StockLine
		UPDATE SL
		SET SL.[WorkOrderId] = @WorkOrderId,
			SL.[WorkOrderPartNoId] = @WorkOrderPartNoId,
			SL.[UpdatedDate] = GETUTCDATE(),
			SL.[UpdatedBy] = @UpdatedBy,
			SL.[QuantityAvailable] = CASE WHEN ISNULL(SL.[QuantityAvailable], 0) > 0 THEN ISNULL(SL.[QuantityAvailable], 0) - ISNULL(@NPMStockQTY, 0) ELSE ISNULL(SL.[QuantityAvailable], 0) END,
			SL.[QuantityOnHand] = CASE WHEN ISNULL(SL.[QuantityOnHand], 0) > 0 THEN ISNULL(SL.[QuantityOnHand], 0) - ISNULL(@NPMStockQTY, 0) ELSE ISNULL(SL.[QuantityOnHand], 0) END
		 FROM [dbo].[StockLine] SL
		 INNER JOIN [dbo].[MasterCompany] MC WITH(NOLOCK) ON MC.[MasterCompanyId] = SL.[MasterCompanyId]
		 WHERE SL.[StockLineId] = @StockLineId AND SL.[MasterCompanyId] = @MasterCompanyId;

		 EXEC [dbo].[USP_AddUpdateStocklineHistory]	@StocklineId=@StockLineId,@ModuleId=@ModuleId,@ReferenceId=@WorkOrderPartNoId,@SubModuleId=@SubModuleId,@ActionId=@ActionId,@Qty=@Qty,@UpdatedBy=@UpdatedBy;

	END
  COMMIT TRANSACTION
  END TRY
  BEGIN CATCH
	IF @@trancount > 0
	  ROLLBACK TRAN;
	  DECLARE @ErrorLogID int
	  ,@DatabaseName varchar(100) = DB_NAME()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
	  ,@AdhocComments varchar(150) = 'USP_UpdateStockLineWorkOrderPart'  
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