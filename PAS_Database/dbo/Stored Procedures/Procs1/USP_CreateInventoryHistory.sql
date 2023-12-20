CREATE PROCEDURE [dbo].[USP_CreateInventoryHistory] 
(
	@InventoryId BIGINT = NULL,
	@IsPO	bit=0,
	@IsRO	bit=0,
	@IsWO	char(1)='',
	@Note	NVARCHAR(MAX),
	@PREVInv	VARCHAR(30),
	@MPN		VARCHAR(30)
)
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON

    BEGIN TRY
    BEGIN TRANSACTION
      BEGIN

		DECLARE @PoId bigint;
		DECLARE @RoId bigint;
		DECLARE @WoId bigint;
		DECLARE @ItemTypeId bigint;
		SET @ItemTypeId =(select ItemTypeId from ItemType where Name='Asset')		
		SET @PoId = (SELECT PurchaseOrderId FROM AssetInventory WHERE AssetInventoryId = @InventoryId)
		SET @RoId = (SELECT RepairOrderId FROM AssetInventory WHERE AssetInventoryId = @InventoryId)
		IF(@PoId > 0)
		BEGIN				

					INSERT INTO 
					[dbo].[AssetInventoryHistory] 
					(InventoryId,AssetRecordId_o,AssetRecordId_m,InventoryNumber,StkLineNumber,PurchaseOrderId,PONum,POCost,ConditionId,ConditionName
					,RepairOrderId,RONum,WorkscoprId,WorkscopeName,RepairCost,VendorId,VendorName,RecdDate,Cost,LotNum,WONum,PreviousInventory,Note)
					SELECT @InventoryId,AST.AssetRecordId,0,AST.InventoryNumber,AST.StklineNumber,AST.PurchaseOrderId,po.PurchaseOrderNumber,
					pop.UnitCost,pop.ConditionId,pop.Condition,NULL,NULL,NULL,NULL,NULL,po.VendorId,po.VendorName,AST.CreatedDate,pop.ExtendedCost,NULL,NULL,@PREVInv,@Note
					FROM DBO.AssetInventory AST WITH (NOLOCK)
					LEFT JOIN PurchaseOrder po WITH (NOLOCK) on AST.PurchaseOrderId = po.PurchaseOrderId
					LEFT JOIN PurchaseOrderPart pop WITH (NOLOCK) on AST.PurchaseOrderPartRecordId = pop.PurchaseOrderPartRecordId AND pop.ItemTypeId=@ItemTypeId						
					WHERE AST.AssetInventoryId = @InventoryId					

		END		
		ELSE IF(@RoId > 0)
		BEGIN
				--declare @previnv nvarchar(50);
				--set @previnv=select InventoryNumber from AssetInventory where AssetInventoryId=@INVENTORYID and InventoryStatusId=11
				INSERT INTO 
					[dbo].[AssetInventoryHistory] 
					(InventoryId,AssetRecordId_o,AssetRecordId_m,InventoryNumber,StkLineNumber,PurchaseOrderId,PONum,POCost,ConditionId,ConditionName
					,RepairOrderId,RONum,WorkscoprId,WorkscopeName,RepairCost,VendorId,VendorName,RecdDate,Cost,LotNum,WONum,PreviousInventory,Note)
					
					SELECT @InventoryId,ROP.ItemMasterId,ROP.RevisedPartId,AST.InventoryNumber,AST.StklineNumber,NULL,NULL,
					NULL,NULL,NULL,RO.RepairOrderId,RO.RepairOrderNumber,NULL,NULL,ROP.UnitCost,RO.VendorId,RO.VendorName,AST.CreatedDate,ROP.ExtendedCost,NULL,NULL,@PREVInv,@Note
					
					FROM DBO.ASSETINVENTORY AST WITH (NOLOCK)
					LEFT JOIN REPAIRORDER RO WITH (NOLOCK) ON AST.REPAIRORDERID = RO.REPAIRORDERID
					LEFT JOIN REPAIRORDERPART ROP WITH (NOLOCK) ON AST.REPAIRORDERPARTRECORDID = ROP.REPAIRORDERPARTRECORDID AND ROP.ITEMTYPEID=@ITEMTYPEID
					--LEFT JOIN WORKORDER WO WITH (NOLOCK) ON AST.WORKORDER = WO.WORKORDERID
					WHERE AST.ASSETINVENTORYID = @INVENTORYID

		END
		ELSE IF(@IsWO='W')
		BEGIN
				INSERT INTO 
					[dbo].[AssetInventoryHistory] 
					(InventoryId,AssetRecordId_o,AssetRecordId_m,InventoryNumber,StkLineNumber,PurchaseOrderId,PONum,POCost,ConditionId,ConditionName
					,RepairOrderId,RONum,WorkscoprId,WorkscopeName,RepairCost,VendorId,VendorName,RecdDate,Cost,LotNum,WONum,PreviousInventory,Note,WorkOrderId,WorkOrderType)
					
					SELECT @InventoryId,AST.AssetRecordId,0,AST.InventoryNumber,AST.StklineNumber,AST.PurchaseOrderId,NULL,
					NULL,NULL,NULL,AST.RepairOrderId,null,NULL,NULL,AST.UnitCost,null,null,AST.CreatedDate,NULL,NULL,wo.WorkOrderNum,NULL,@Note,wo.WorkOrderId,'W'
					
					FROM DBO.ASSETINVENTORY AST WITH (NOLOCK)
					LEFT JOIN CheckInCheckOutWorkOrderAsset woa WITH (NOLOCK) ON AST.AssetInventoryId = woa.AssetInventoryId
					LEFT JOIN WorkOrder wo WITH (NOLOCK) ON wo.WorkOrderId=woa.WorkOrderId
					WHERE AST.ASSETINVENTORYID = @INVENTORYID
		END
		ELSE IF(@IsWO='S')
		BEGIN
				INSERT INTO 
					[dbo].[AssetInventoryHistory] 
					(InventoryId,AssetRecordId_o,AssetRecordId_m,InventoryNumber,StkLineNumber,PurchaseOrderId,PONum,POCost,ConditionId,ConditionName
					,RepairOrderId,RONum,WorkscoprId,WorkscopeName,RepairCost,VendorId,VendorName,RecdDate,Cost,LotNum,WONum,PreviousInventory,Note,WorkOrderId,WorkOrderType)
					
					SELECT @InventoryId,AST.AssetRecordId,0,AST.InventoryNumber,AST.StklineNumber,AST.PurchaseOrderId,NULL,
					NULL,NULL,NULL,AST.RepairOrderId,null,NULL,NULL,AST.UnitCost,null,null,AST.CreatedDate,NULL,NULL,wo.SubWorkOrderNo,NULL,@Note,wo.SubWorkOrderId,'S'
					
					FROM DBO.ASSETINVENTORY AST WITH (NOLOCK)
					LEFT JOIN SubWOCheckInCheckOutWorkOrderAsset woa WITH (NOLOCK) ON AST.AssetInventoryId = woa.AssetInventoryId
					LEFT JOIN SubWorkOrder wo WITH (NOLOCK) ON wo.SubWorkOrderId=woa.SubWorkOrderId
					WHERE AST.ASSETINVENTORYID = @INVENTORYID
		END
		ELSE
		BEGIN

					INSERT INTO 
					[dbo].[AssetInventoryHistory] 
					(InventoryId,AssetRecordId_o,AssetRecordId_m,InventoryNumber,StkLineNumber,PurchaseOrderId,PONum,POCost,ConditionId,ConditionName
					,RepairOrderId,RONum,WorkscoprId,WorkscopeName,RepairCost,VendorId,VendorName,RecdDate,Cost,LotNum,WONum,PreviousInventory,Note)
					
					SELECT @InventoryId,AST.AssetRecordId,0,AST.InventoryNumber,AST.StklineNumber,AST.PurchaseOrderId,NULL,
					AST.UnitCost,NULL,NULL,AST.RepairOrderId,NULL,NULL,NULL,NULL,NULL,NULL,AST.CreatedDate,AST.UnitCost,NULL,NULL,NULL,@Note
					
					FROM DBO.ASSETINVENTORY AST
					WHERE AST.ASSETINVENTORYID = @INVENTORYID
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
		,@AdhocComments varchar(150) = 'USP_CreateInventoryHistory'
		,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(@InventoryId, '') + ''
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