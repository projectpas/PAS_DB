/*************************************************************           
 ** File:   [USP_CreateStocklinePartHistory]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used to Store Stock Line History
 ** Date:   06/28/2023
 ** PARAMETERS: @VendorRMAId BIGINT          
 ** RETURN VALUE:
 ******************************************************************************           
  ** Change History           
 ******************************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    06/28/2023   Moin Bloch     Added IsRMA Flag
*******************************************************************************
EXEC USP_CreateStocklinePartHistory 1,0,0,2,1
*******************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateStocklinePartHistory] 
(
	@StocklineId BIGINT = NULL,
	@IsPO bit=0,
	@IsRO bit=0,
	@extstocklineId BIGINT = NULL,
	@IsRMA bit=0
)
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON

    BEGIN TRY
    BEGIN TRANSACTION
      BEGIN
		--DECLARE @PoId bigint;
		--DECLARE @RoId bigint;
		--SET @PoId = (SELECT PurchaseOrderId FROM Stockline WHERE StockLineId = @StocklineId)
		--IF(@PoId > 0)
		--BEGIN
		--	INSERT INTO [dbo].[StockLineHistoryDetails] ([StocklineId], [ItemMasterId_o], [ItemMasterId_m], [StocklineNum],
		--			[PurchaseOrderId], [PONum], [POCost], [ConditionId], [ConditionName], [RepairOrderId], [RONum], [WorkscoprId],[WorkscopeName],
		--			[RepairCost],[VendorId],[VendorName],[RecdDate],[Cost],[LotNum],[WONum],[PreviousStockLine])
		--		SELECT @StocklineId, STL.ItemMasterId, 0, STL.StockLineNumber,
		--			STL.PurchaseOrderId, po.PurchaseOrderNumber, pop.UnitCost, STL.ConditionId,STL.Condition,NULL,NULL,NULL,NULL,
		--			NULL,po.VendorId,po.VendorName,STL.ReceivedDate,NULL,NULL,wo.WorkOrderNum,NULL
		--		FROM DBO.Stockline STL 
		--		LEFT JOIN PurchaseOrder po WITH (NOLOCK) on STL.PurchaseOrderId = po.PurchaseOrderId
		--		LEFT JOIN PurchaseOrderPart pop WITH (NOLOCK) on STL.PurchaseOrderPartRecordId = pop.PurchaseOrderPartRecordId
		--		LEFT JOIN WorkOrder wo WITH (NOLOCK) on STL.WorkOrderId = wo.WorkOrderId
		--		WHERE STL.StockLineId = @StocklineId
		--END
		--SET @RoId = (SELECT RepairOrderId FROM Stockline WHERE StockLineId = @StocklineId)
		--IF(@RoId > 0)
		--BEGIN
		--	INSERT INTO [dbo].[StockLineHistoryDetails] ([StocklineId], [ItemMasterId_o], [ItemMasterId_m], [StocklineNum],
		--			[PurchaseOrderId], [PONum], [POCost], [ConditionId], [ConditionName], [RepairOrderId], [RONum], [WorkscoprId],[WorkscopeName],
		--			[RepairCost],[VendorId],[VendorName],[RecdDate],[Cost],[LotNum],[WONum],[PreviousStockLine])
		--		SELECT @StocklineId, STL.ItemMasterId, 0, STL.StockLineNumber,
		--			NULL, NULL, NULL, STL.ConditionId,STL.Condition,ro.RepairOrderId,ro.RepairOrderNumber,NULL,NULL,
		--			rop.UnitCost,ro.VendorId,ro.VendorName,STL.ReceivedDate,NULL,NULL,wo.WorkOrderNum,NULL
		--		FROM DBO.Stockline STL 
		--		LEFT JOIN RepairOrder ro WITH (NOLOCK) on STL.RepairOrderId = ro.RepairOrderId
		--		LEFT JOIN RepairOrderPart rop WITH (NOLOCK) on STL.RepairOrderPartRecordId = rop.RepairOrderPartRecordId
		--		LEFT JOIN WorkOrder wo WITH (NOLOCK) on STL.WorkOrderId = wo.WorkOrderId
		--		WHERE STL.StockLineId = @StocklineId
		--END
		IF(@IsPO = 1)
		BEGIN
			INSERT INTO [dbo].[StockLineHistoryDetails] ([StocklineId], [ItemMasterId_o], [ItemMasterId_m], [StocklineNum],
					[PurchaseOrderId], [PONum], [POCost], [ConditionId], [ConditionName], [RepairOrderId], [RONum], [WorkscoprId],[WorkscopeName],
					[RepairCost],[VendorId],[VendorName],[RecdDate],[Cost],[LotNum],[WONum],[PreviousStockLine],[extstocklineId],[InventoryCost],[AltEquiPartNumber])
				SELECT @StocklineId, STL.ItemMasterId, 0, STL.StockLineNumber,
					STL.PurchaseOrderId, po.PurchaseOrderNumber, pop.UnitCost, STL.ConditionId,STL.Condition,NULL,NULL,NULL,NULL,
					NULL,po.VendorId,po.VendorName,STL.ReceivedDate,pop.ExtendedCost,STL.LotNumber,wo.WorkOrderNum,NULL,0,STL.UnitCost,pop.AltEquiPartNumber
				FROM [dbo].[Stockline] STL WITH (NOLOCK)
				LEFT JOIN [dbo].[PurchaseOrder] po WITH (NOLOCK) ON STL.PurchaseOrderId = po.PurchaseOrderId
				LEFT JOIN [dbo].[PurchaseOrderPart] pop WITH (NOLOCK) ON STL.PurchaseOrderPartRecordId = pop.PurchaseOrderPartRecordId
				LEFT JOIN [dbo].[WorkOrder] wo WITH (NOLOCK) ON pop.WorkOrderId = wo.WorkOrderId
				LEFT JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON STL.WorkOrderPartNoId = wop.ID
				WHERE STL.StockLineId = @StocklineId
		END
		IF(@IsRO = 1)
		BEGIN
				--declare @revpn bigint;
				--set @revpn = (select rop.RevisedPartId from DBO.Stockline STL 
				--LEFT JOIN RepairOrder ro WITH (NOLOCK) on STL.RepairOrderId = ro.RepairOrderId
				--LEFT JOIN RepairOrderPart rop WITH (NOLOCK) on STL.RepairOrderPartRecordId = rop.RepairOrderPartRecordId
				--where STL.StockLineId = @StocklineId)

				INSERT INTO [dbo].[StockLineHistoryDetails] ([StocklineId], [ItemMasterId_o], [ItemMasterId_m], [StocklineNum],
					[PurchaseOrderId], [PONum], [POCost], [ConditionId], [ConditionName], [RepairOrderId], [RONum], [WorkscoprId],[WorkscopeName],
					[RepairCost],[VendorId],[VendorName],[RecdDate],[Cost],[LotNum],[WONum],[PreviousStockLine],[extstocklineId],[InventoryCost],[AltEquiPartNumber])
				SELECT @extstocklineId, STL.ItemMasterId, 0, STL.StockLineNumber,
					NULL, NULL, NULL, STL.ConditionId,STL.Condition,ro.RepairOrderId,ro.RepairOrderNumber,wop.WorkOrderScopeId,wos.[Description],
					rop.UnitCost,ro.VendorId,ro.VendorName,STL.ReceivedDate,rop.ExtendedCost,STL.LotNumber,wo.WorkOrderNum,rop.StockLineNumber,@StocklineId,STL.UnitCost,rop.AltEquiPartNumber
				FROM [dbo].[Stockline] STL WITH (NOLOCK)
				LEFT JOIN [dbo].[RepairOrder] ro WITH (NOLOCK) ON STL.RepairOrderId = ro.RepairOrderId
				LEFT JOIN [dbo].[RepairOrderPart] rop WITH (NOLOCK) ON STL.RepairOrderPartRecordId = rop.RepairOrderPartRecordId
				LEFT JOIN [dbo].[WorkOrder] wo WITH (NOLOCK) ON rop.WorkOrderId = wo.WorkOrderId
				LEFT JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON STL.WorkOrderPartNoId = wop.ID
				LEFT JOIN [dbo].[WorkScope] wos WITH (NOLOCK) ON wop.WorkOrderScopeId = wos.WorkScopeId
				WHERE STL.StockLineId = @extstocklineId;

				INSERT INTO [dbo].[StockLineHistoryDetails] ([StocklineId], [ItemMasterId_o], [ItemMasterId_m], [StocklineNum],
					[PurchaseOrderId], [PONum], [POCost], [ConditionId], [ConditionName], [RepairOrderId], [RONum], [WorkscoprId],[WorkscopeName],
					[RepairCost],[VendorId],[VendorName],[RecdDate],[Cost],[LotNum],[WONum],[PreviousStockLine],[extstocklineId],[InventoryCost],[AltEquiPartNumber])
				SELECT @StocklineId, rop.ItemMasterId, rop.RevisedPartId, STL.StockLineNumber,
					rop.RevisedPartId, NULL, NULL, STL.ConditionId,STL.Condition,ro.RepairOrderId,ro.RepairOrderNumber,wop.WorkOrderScopeId,wos.[Description],
					rop.UnitCost,ro.VendorId,ro.VendorName,STL.ReceivedDate,rop.ExtendedCost,STL.LotNumber,wo.WorkOrderNum,rop.StockLineNumber,@StocklineId,STL.UnitCost,rop.AltEquiPartNumber
				FROM [dbo].[Stockline] STL WITH (NOLOCK)
				LEFT JOIN [dbo].[RepairOrder] ro WITH (NOLOCK) ON STL.RepairOrderId = ro.RepairOrderId
				LEFT JOIN [dbo].[RepairOrderPart] rop WITH (NOLOCK) ON STL.RepairOrderPartRecordId = rop.RepairOrderPartRecordId
				LEFT JOIN [dbo].[WorkOrder] wo WITH (NOLOCK) ON rop.WorkOrderId = wo.WorkOrderId
				LEFT JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK) ON STL.WorkOrderPartNoId = wop.ID
				LEFT JOIN [dbo].[WorkScope] wos WITH (NOLOCK) ON wop.WorkOrderScopeId = wos.WorkScopeId
				WHERE STL.StockLineId = @StocklineId;

				DECLARE @stlnum VARCHAR(100);
				SET @stlnum = (SELECT StocklineNum FROM dbo.StockLineHistoryDetails WITH (NOLOCK) WHERE StocklineId = @StocklineId AND extstocklineId = @StocklineId)
				DECLARE @opn BIGINT;
				SET @opn = (SELECT ItemMasterId_o FROM dbo.StockLineHistoryDetails WITH (NOLOCK) WHERE StocklineId = @extstocklineId AND extstocklineId = @StocklineId)
				DECLARE @mpn bigint;
				SET @mpn = (SELECT ItemMasterId_o FROM dbo.StockLineHistoryDetails WITH (NOLOCK) WHERE StocklineId = @StocklineId AND extstocklineId = @StocklineId)
				DECLARE @modpn BIGINT=0;
				IF(@opn != @mpn)
				BEGIN
					SET @modpn = @mpn;
				END

				UPDATE [dbo].[StockLineHistoryDetails] SET
					  StockLineHistoryDetails.RepairOrderId = q.RepairOrderId,
					  StockLineHistoryDetails.RONum = q.RONum,
					  StockLineHistoryDetails.ItemMasterId_m = q.ItemMasterId_m,
					  --StockLineHistoryDetails.ItemMasterId_m = @modpn,
					  StockLineHistoryDetails.VendorId = q.VendorId,
					  StockLineHistoryDetails.VendorName = q.VendorName,
					  StockLineHistoryDetails.RepairCost = q.RepairCost,
					  StockLineHistoryDetails.RecdDate = q.RecdDate,
					  StockLineHistoryDetails.WONum = q.WONum,
					  --StockLineHistoryDetails.PreviousStockLine = @stlnum,
					  StockLineHistoryDetails.PreviousStockLine = q.PreviousStockLine,
					  StockLineHistoryDetails.StocklineNum = q.StocklineNum,
					  StockLineHistoryDetails.WorkscoprId = q.WorkscoprId,
					  StockLineHistoryDetails.WorkscopeName = q.WorkscopeName,
					  StockLineHistoryDetails.InventoryCost = q.InventoryCost,
					  StockLineHistoryDetails.AltEquiPartNumber = q.AltEquiPartNumber,
					  StockLineHistoryDetails.Cost = q.Cost
					FROM (
					  SELECT RepairOrderId, RONum,ItemMasterId_m,VendorId,VendorName,RepairCost,RecdDate,Cost,WONum,StocklineNum,WorkscoprId,WorkscopeName,InventoryCost,PreviousStockLine,AltEquiPartNumber
					  FROM StockLineHistoryDetails
					  WHERE StocklineId = @StocklineId AND extstocklineId = @StocklineId
					) q
					WHERE StocklineId = @extstocklineId AND extstocklineId = @StocklineId
		END
		IF(@IsRMA = 1)
		BEGIN
			INSERT INTO [dbo].[StockLineHistoryDetails] ([StocklineId], [ItemMasterId_o], [ItemMasterId_m], [StocklineNum],
					[PurchaseOrderId], [PONum], [POCost], [ConditionId], [ConditionName], [RepairOrderId], [RONum], [WorkscoprId],[WorkscopeName],
					[RepairCost],[VendorId],[VendorName],[RecdDate],[Cost],[LotNum],[WONum],[PreviousStockLine],[extstocklineId],[InventoryCost],[AltEquiPartNumber],[VendorRMAId],[RMANumber])
				SELECT @StocklineId, STL.ItemMasterId, 0, STL.StockLineNumber,
					NULL, NULL, pop.UnitCost, STL.ConditionId,STL.Condition,NULL,NULL,NULL,NULL,
					NULL,po.VendorId,v.VendorName,STL.ReceivedDate,pop.ExtendedCost,STL.LotNumber,NULL,NULL,0,STL.UnitCost,NULL,po.VendorRMAId,po.RMANumber
				FROM [dbo].[Stockline] STL WITH (NOLOCK)
				LEFT JOIN [dbo].[VendorRMA] po WITH (NOLOCK) ON STL.VendorRMAId = po.VendorRMAId
				LEFT JOIN [dbo].[VendorRMADetail] pop WITH (NOLOCK) ON STL.VendorRMADetailId = pop.VendorRMADetailId
				LEFT JOIN [dbo].[Vendor] V WITH (NOLOCK) ON V.VendorId = po.VendorId
				WHERE STL.StockLineId = @StocklineId;
		END
	END
    COMMIT TRANSACTION

  END TRY
  BEGIN CATCH
    IF @@trancount > 0
		ROLLBACK TRAN;
		DECLARE @ErrorLogID int
		,@DatabaseName varchar(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
		,@AdhocComments varchar(150) = 'USP_CreateStocklinePartHistory'
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