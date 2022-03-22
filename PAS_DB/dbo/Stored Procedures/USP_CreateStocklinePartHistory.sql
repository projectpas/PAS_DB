
CREATE PROCEDURE [dbo].[USP_CreateStocklinePartHistory] 
(
	@StocklineId BIGINT = NULL,
	@IsPO bit=0,
	@IsRO bit=0,
	@extstocklineId BIGINT = NULL
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
				FROM DBO.Stockline STL 
				LEFT JOIN PurchaseOrder po WITH (NOLOCK) on STL.PurchaseOrderId = po.PurchaseOrderId
				LEFT JOIN PurchaseOrderPart pop WITH (NOLOCK) on STL.PurchaseOrderPartRecordId = pop.PurchaseOrderPartRecordId
				--LEFT JOIN WorkOrder wo WITH (NOLOCK) on STL.WorkOrderId = wo.WorkOrderId
				LEFT JOIN WorkOrder wo WITH (NOLOCK) on pop.WorkOrderId = wo.WorkOrderId
				LEFT JOIN WorkOrderPartNumber wop WITH (NOLOCK) on STL.WorkOrderPartNoId = wop.ID
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
				FROM DBO.Stockline STL 
				LEFT JOIN RepairOrder ro WITH (NOLOCK) on STL.RepairOrderId = ro.RepairOrderId
				LEFT JOIN RepairOrderPart rop WITH (NOLOCK) on STL.RepairOrderPartRecordId = rop.RepairOrderPartRecordId
				LEFT JOIN WorkOrder wo WITH (NOLOCK) on rop.WorkOrderId = wo.WorkOrderId
				LEFT JOIN WorkOrderPartNumber wop WITH (NOLOCK) on STL.WorkOrderPartNoId = wop.ID
				LEFT JOIN WorkScope wos WITH (NOLOCK) on wop.WorkOrderScopeId = wos.WorkScopeId
				WHERE STL.StockLineId = @extstocklineId

				INSERT INTO [dbo].[StockLineHistoryDetails] ([StocklineId], [ItemMasterId_o], [ItemMasterId_m], [StocklineNum],
					[PurchaseOrderId], [PONum], [POCost], [ConditionId], [ConditionName], [RepairOrderId], [RONum], [WorkscoprId],[WorkscopeName],
					[RepairCost],[VendorId],[VendorName],[RecdDate],[Cost],[LotNum],[WONum],[PreviousStockLine],[extstocklineId],[InventoryCost],[AltEquiPartNumber])
				SELECT @StocklineId, rop.ItemMasterId, rop.RevisedPartId, STL.StockLineNumber,
					rop.RevisedPartId, NULL, NULL, STL.ConditionId,STL.Condition,ro.RepairOrderId,ro.RepairOrderNumber,wop.WorkOrderScopeId,wos.[Description],
					rop.UnitCost,ro.VendorId,ro.VendorName,STL.ReceivedDate,rop.ExtendedCost,STL.LotNumber,wo.WorkOrderNum,rop.StockLineNumber,@StocklineId,STL.UnitCost,rop.AltEquiPartNumber
				FROM DBO.Stockline STL 
				LEFT JOIN RepairOrder ro WITH (NOLOCK) on STL.RepairOrderId = ro.RepairOrderId
				LEFT JOIN RepairOrderPart rop WITH (NOLOCK) on STL.RepairOrderPartRecordId = rop.RepairOrderPartRecordId
				LEFT JOIN WorkOrder wo WITH (NOLOCK) on rop.WorkOrderId = wo.WorkOrderId
				LEFT JOIN WorkOrderPartNumber wop WITH (NOLOCK) on STL.WorkOrderPartNoId = wop.ID
				LEFT JOIN WorkScope wos WITH (NOLOCK) on wop.WorkOrderScopeId = wos.WorkScopeId
				WHERE STL.StockLineId = @StocklineId

				declare @stlnum varchar(100);
				SET @stlnum = (select StocklineNum from StockLineHistoryDetails where StocklineId = @StocklineId and extstocklineId = @StocklineId)
				declare @opn bigint;
				SET @opn = (select ItemMasterId_o from StockLineHistoryDetails where StocklineId = @extstocklineId and extstocklineId = @StocklineId)
				declare @mpn bigint;
				SET @mpn = (select ItemMasterId_o from StockLineHistoryDetails where StocklineId = @StocklineId and extstocklineId = @StocklineId)
				declare @modpn bigint=0;
				if(@opn != @mpn)
				begin
					set @modpn = @mpn;
				end

				UPDATE StockLineHistoryDetails SET
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