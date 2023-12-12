/*************************************************************   
** Author:  <Vishal Suthar>  
** Create date: <04/06/2023>  
** Description: <Save Work Order Materials KIT Stockline Details>  
  
EXEC [usp_CreateWorkOrderMaterialsKitStockline] 
************************************************************** 
** Change History 
**************************************************************   
** PR   Date        Author          Change Description  
** --   --------    -------         --------------------------------
** 1    04/06/2023  Vishal Suthar    CREATED

exec dbo.usp_ReserveWorkOrderMaterialsStockline @tbl_MaterialsStocklineType=@p1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_CreateWorkOrderMaterialsKitStockline]
	@tbl_MaterialsStocklineType ReserveWOMaterialsStocklineType READONLY
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					--CASE 1 UPDATE WORK ORDER MATERILS
					DECLARE @ModuleId INT;
					DECLARE @ProvisionId BIGINT;
					DECLARE @TotalCounts INT;

					SELECT @ProvisionId = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE StatusCode = 'REPAIR' AND IsActive = 1 AND IsDeleted = 0;
					SELECT @ModuleId = ModuleId FROM dbo.Module WITH(NOLOCK) WHERE ModuleId = 15; -- For WORK ORDER Module

					IF OBJECT_ID(N'tempdb..#tmpCreateWOMaterialsKitStockline') IS NOT NULL
					BEGIN
					DROP TABLE #tmpCreateWOMaterialsKitStockline
					END
			
					CREATE TABLE #tmpCreateWOMaterialsKitStockline
					(
						ID BIGINT NOT NULL IDENTITY, 
						[WorkOrderId] BIGINT NULL,
						[WorkFlowWorkOrderId] BIGINT NULL,
						[WorkOrderMaterialsId] BIGINT NULL,
						[StockLineId] BIGINT NULL,
						[ItemMasterId] BIGINT NULL,
						[ConditionId] BIGINT NULL,
						[ProvisionId] BIGINT NULL,
						[TaskId] BIGINT NULL,
						[ReservedById] BIGINT NULL,
						[Condition] VARCHAR(500) NULL,
						[PartNumber] VARCHAR(500) NULL,
						[PartDescription] VARCHAR(max) NULL,
						[Quantity] INT NULL,
						[QtyToBeReserved] INT NULL,
						[QuantityActReserved] INT NULL,
						[ControlNo] VARCHAR(500) NULL,
						[ControlId] VARCHAR(500) NULL,
						[StockLineNumber] VARCHAR(500) NULL,
						[SerialNumber] VARCHAR(500) NULL,
						[ReservedBy] VARCHAR(500) NULL,						 
						[IsStocklineAdded] BIT NULL,
						[MasterCompanyId] BIGINT NULL,
						[UpdatedBy] VARCHAR(500) NULL,
						[UnitCost] DECIMAL(18,2),
						[IsSerialized] BIT,
						[KitId] BIGINT NULL,
						[IsAltPart] [BIT] NULL,
						[IsEquPart] [BIT] NULL,
						[AltPartMasterPartId] [bigint] NULL,
						[EquPartMasterPartId] [bigint] NULL
					)

					INSERT INTO #tmpCreateWOMaterialsKitStockline ([WorkOrderId],[WorkFlowWorkOrderId], [WorkOrderMaterialsId], [StockLineId],[ItemMasterId],[ConditionId], [ProvisionId], 
						[TaskId], [ReservedById], [Condition], [PartNumber], [PartDescription], [Quantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
							[StockLineNumber], [SerialNumber], [ReservedBy], [IsStocklineAdded], [MasterCompanyId], [UpdatedBy], [UnitCost], [IsSerialized], [KitId], [IsAltPart], [IsEquPart], [AltPartMasterPartId], [EquPartMasterPartId])
					SELECT tblMS.[WorkOrderId],[WorkFlowWorkOrderId], tblMS.[WorkOrderMaterialsId], tblMS.[StockLineId], tblMS.[ItemMasterId], tblMS.[ConditionId], @ProvisionId, 
						[TaskId], [ReservedById], tblMS.[Condition], tblMS.[PartNumber], [PartDescription], tblMS.[Quantity], [QtyToBeReserved], [QuantityActReserved], [ControlNo], [ControlId],
						tblMS.[StockLineNumber], tblMS.[SerialNumber], [ReservedBy], [IsStocklineAdded], SL.MasterCompanyId, [ReservedBy], SL.UnitCost, SL.isSerialized, tblMS.[KitId], tblMS.[IsAltPart], tblMS.[IsEquPart], tblMS.[AltPartMasterPartId], tblMS.[EquPartMasterPartId]
					FROM @tbl_MaterialsStocklineType tblMS  JOIN dbo.Stockline SL ON SL.StockLineId = tblMS.StockLineId 
					WHERE SL.QuantityAvailable > 0 AND SL.QuantityAvailable >= tblMS.QuantityActReserved

					INSERT INTO dbo.WorkOrderMaterialStockLineKit
					(StocklineId, WorkOrderMaterialskitId, ItemMasterId, ConditionId, ProvisionId, Quantity, QtyReserved, QtyIssued, UnitCost, ExtendedCost, UnitPrice, ExtendedPrice, CreatedDate, CreatedBy, UpdatedDate, UpdatedBy, MasterCompanyId, IsActive, IsDeleted, AltPartMasterPartId, EquPartMasterPartId, IsAltPart, IsEquPart)
					SELECT tmpWOMS.StocklineId, tmpWOMS.WorkOrderMaterialsId, tmpWOMS.ItemMasterId, tmpWOMS.ConditionId, tmpWOMS.ProvisionId, tmpWOMS.QuantityActReserved, 0, 0, tmpWOMS.UnitCost, (ISNULL(tmpWOMS.QuantityActReserved, 0) * ISNULL(tmpWOMS.UnitCost, 0)), tmpWOMS.UnitCost, (ISNULL(tmpWOMS.QuantityActReserved, 0) * ISNULL(tmpWOMS.UnitCost, 0)), GETDATE(), tmpWOMS.ReservedBy, GETDATE(), tmpWOMS.ReservedBy, tmpWOMS.MasterCompanyId, 1, 0, tmpWOMS.AltPartMasterPartId, tmpWOMS.EquPartMasterPartId, tmpWOMS.IsAltPart, tmpWOMS.IsEquPart
					FROM #tmpCreateWOMaterialsKitStockline AS tmpWOMS;
			END

			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_CreateWorkOrderMaterialsKitStockline' 
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