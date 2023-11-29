
CREATE    PROCEDURE [dbo].[GetBulkPOProcessingList]
	@PageNumber int = 1,
	@PageSize int = 10,
	@SortColumn varchar(50)=NULL,
	@SortOrder int = NULL,
	@StatusId int = 1,
	@Status varchar(50) = 'Pending',
	@GlobalFilter varchar(50) = '',	
	@PoRfqNo varchar(50) = NULL,
	@PN varchar(100) = NULL,
	@PNDescription varchar(200) = NULL,
	@Manufacturer varchar(200) = NULL,
	@Condition varchar(100) = NULL,
	@Quantity int = NULL,
	@UnitCost decimal(18,2) = NULL,
	@ExtendedCost decimal(18,2) = NULL,
	@LastPurchasePrice decimal(18,2) = NULL,
	@LastPONumber varchar(50) = NULL,
	@lastPODate datetime = NULL,
	@VendorId bigint = NULL,
	@VendorName varchar(50) = NULL,
	@NeedBy datetime = NULL,
	@EstReceivedDate datetime = NULL,
	@WONum varchar(50) = NULL,
	@SONum varchar(50) = NULL,
	@MPN varchar(50) = NULL,
	@MPNDescription varchar(50) = NULL,
	@SerialNum varchar(50) = NULL,
	@Customer varchar(50) = NULL,
	@CreatedBy  varchar(50) = NULL,
	@CreatedDate datetime = NULL,
	@UpdatedBy  varchar(50) = NULL,
	@UpdatedDate  datetime = NULL,
	@EmployeeId bigint = NULL,
	@MasterCompanyId bigint = NULL,
	@IsPOGenerated bit =NULL,
	@ReturnIds varchar(MAX) = NULL
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		DECLARE @RecordFrom int;
		DECLARE @IsActive bit = 1;
		DECLARE @Count Int;
		DECLARE @StageId BIGINT = 0;
		SET @RecordFrom = (@PageNumber - 1) * @PageSize;
		SELECT @StageId = WorkOrderStageId FROM dbo.PurchaseOrderSettingMaster WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId

		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn = Upper('CreatedDate')
		END 
		ELSE
		BEGIN 
			Set @SortColumn = Upper(@SortColumn)
		END
		IF (@StatusID = 6 AND @Status = 'All')
		BEGIN			
			SET @Status = ''
		END
		IF (@StatusID = 6 OR @StatusID = 0)
		BEGIN
			SET @StatusID = NULL
		END
		IF(@ReturnIds IS NOT NULL AND @ReturnIds != '')
		BEGIN
			SET @SortColumn = Upper('OrderNo')
			SET @SortOrder = 1
		END
		
		BEGIN TRY
		BEGIN TRANSACTION
		BEGIN
			;WITH Result AS (									
		   	 SELECT DISTINCT
				2 AS OrderNo,
			 	CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN 'PO Created' ELSE'Pending' END AS [Status],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN PO.StatusId ELSE (SELECT TOP 1 POStatusId FROM dbo.PoStatus WITH (NOLOCK)  WHERE Status = 'Open') END As StatusId,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN (SELECT TOP 1 [Status] FROM dbo.PoStatus WITH (NOLOCK)  WHERE POStatusId = PO.StatusId) ELSE (SELECT TOP 1 [Status] FROM dbo.PoStatus WITH (NOLOCK)  WHERE Status = 'Open') END As StatusName,
				ISNULL(PO.PurchaseOrderNumber,'') poRfqNo,
				ISNULL(PO.PurchaseOrderId,0) PurchaseOrderId,
				WOM.WorkOrderId,
				IM_Mat.partnumber AS PN,
				IM_Mat.PartDescription AS PNDescription,
				Cond.Description AS Condition,
				WOM.ConditionCodeId AS ConditionId,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END AS Quantity,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END UnitCost,
				((CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END) * (CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END))AS ExtendedCost,
				WOM.WorkOrderMaterialsId WorkOrderMaterialsId,
				0 WorkOrderMaterialsKitId,
				WOM.ItemMasterId WOM_itemId,
				WOM.ConditionCodeId  WOM_condD,
				CASE WHEN ISNULL((SELECT TOP 1 PO.PurchaseOrderNumber FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC),'') != '' THEN  (SELECT TOP 1 ISNULL(Stk.PurchaseOrderUnitCost,0) FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC) ELSE 0 END AS [LastPurchasePrice],
				(SELECT TOP 1 PO.PurchaseOrderNumber FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC) AS [LastPONumber],
				CASE WHEN ISNULL((SELECT TOP 1 PO.PurchaseOrderNumber FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC),'') != '' THEN (SELECT TOP 1 Stk.EntryDate FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC) ELSE NULL END AS [LastPODate],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN (SELECT TOP 1 Vend.VendorName FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC) ELSE PO.VendorName END AS [VendorName],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN (SELECT TOP 1 Vend.VendorId FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC)ELSE PO.VendorId END AS [VendorId],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN (SELECT TOP 1 Vend.VendorCode FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC)ELSE (SELECT TOP 1 VendorCode FROM dbo.Vendor VN WITH (NOLOCK)  WHERE VN.VendorId = PO.VendorId) END AS [VendorCode],
				WO.WorkOrderNum AS WONum,
				IM_WOP.partnumber AS MPN,
				IM_WOP.PartDescription AS MPNDescription,
				(SELECT TOP 1 Stk.SerialNumber FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC) AS [SerialNum],
				WO.CustomerName AS Customer,
				IM_ITM.ManufacturerId,
				IM_ITM.ManufacturerName Manufacturer,
				WOM.ItemMasterId ItemMasterId,
				IM_WOP.MinimumOrderQuantity,
				ISNULL(PO.IsFromBulkPO,0) IsFromBulkPO,
				CASE WHEN ISNULL(PO.PurchaseOrderId,0) > 0 THEN POP.NeedByDate ELSE NULL END NeedBy,
				CASE WHEN ISNULL(PO.PurchaseOrderId,0) > 0 THEN  POP.EstDeliveryDate ELSE NULL END  EstReceivedDate,
				PO.CreatedDate CreatedDate,
				0 VendorRFQPOPartRecordId
				FROM DBO.WorkOrderPartNumber WOP WITH (NOLOCK)
				INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOP.ID
				
				INNER JOIN DBO.WorkOrderMaterials WOM WITH (NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId
				LEFT JOIN DBO.ItemMaster IM_ITM WITH (NOLOCK) ON IM_ITM.ItemMasterId = WOM.ItemMasterId
				
				INNER JOIN DBO.WorkOrder WO WITH (NOLOCK) ON WOM.WorkOrderId = WO.WorkOrderId
				INNER JOIN DBO.ItemMaster IM_WOP WITH (NOLOCK) ON IM_WOP.ItemMasterId = WOP.ItemMasterId
				INNER JOIN DBO.ItemMaster IM_Mat WITH (NOLOCK) ON IM_Mat.ItemMasterId = WOM.ItemMasterId
				INNER JOIN DBO.Condition Cond WITH (NOLOCK) ON Cond.ConditionId = WOM.ConditionCodeId
				
				LEFT JOIN DBO.WorkOrderStage WOStage WITH (NOLOCK) ON WOStage.WorkOrderStageId = WOP.WorkOrderStageId
				INNER JOIN DBO.PurchaseOrderPart POP WITH(NOLOCK) on WOM.ItemMasterId = POP.ItemMasterId AND WO.WorkOrderId = POP.WorkOrderId AND POP.ConditionId = COND.ConditionId
				INNER JOIN dbo.PurchaseOrder PO WITH(NOLOCK) on POP.PurchaseOrderId = PO.PurchaseOrderId AND PO.IsFromBulkPO = 1
			  WHERE
			  WOP.MasterCompanyId = @MasterCompanyId AND WOStage.WorkOrderStageId = @StageId AND PO.IsFromBulkPO  = 1		  

			  UNION 

			 SELECT DISTINCT
			 	1 AS OrderNo,
			 	'Pending' AS [Status],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN PO.StatusId ELSE (SELECT TOP 1 POStatusId FROM dbo.PoStatus  WITH (NOLOCK)  WHERE Status = 'Open') END As StatusId,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN (SELECT TOP 1 [Status] FROM dbo.PoStatus WITH (NOLOCK)  WHERE POStatusId = PO.StatusId) ELSE (SELECT TOP 1 [Status] FROM dbo.PoStatus WITH (NOLOCK)  WHERE Status = 'Open') END As StatusName,
				'' poRfqNo,
				0 PurchaseOrderId,
				WOM.WorkOrderId,
				IM_Mat.partnumber AS PN,
				IM_Mat.PartDescription AS PNDescription,
				Cond.Description AS Condition,
				WOM.ConditionCodeId AS ConditionId,
				((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) AS Quantity,
				ISNULL(WOM.UnitCost,0) UnitCost,
				((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) * ISNULL(WOM.UnitCost,0) AS ExtendedCost,
				WOM.WorkOrderMaterialsId WorkOrderMaterialsId,
				0 WorkOrderMaterialsKitId,
				WOM.ItemMasterId WOM_itemId,
				WOM.ConditionCodeId  WOM_condD,
				CASE WHEN ISNULL((SELECT TOP 1 PO.PurchaseOrderNumber FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC),'') != '' THEN  (SELECT TOP 1 ISNULL(Stk.PurchaseOrderUnitCost,0) FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC) ELSE 0 END AS [LastPurchasePrice],
				(SELECT TOP 1 PO.PurchaseOrderNumber FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC) AS [LastPONumber],
				CASE WHEN ISNULL((SELECT TOP 1 PO.PurchaseOrderNumber FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC),'') != '' THEN (SELECT TOP 1 Stk.EntryDate FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC) ELSE NULL END AS [LastPODate],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN (SELECT TOP 1 Vend.VendorName FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC) ELSE PO.VendorName END AS [VendorName],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN (SELECT TOP 1 Vend.VendorId FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC)ELSE PO.VendorId END AS [VendorId],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN (SELECT TOP 1 Vend.VendorCode FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC)ELSE (SELECT TOP 1 VendorCode FROM dbo.Vendor VN WITH (NOLOCK)  WHERE VN.VendorId = PO.VendorId) END AS [VendorCode],

				WO.WorkOrderNum AS WONum,
				IM_WOP.partnumber AS MPN,
				IM_WOP.PartDescription AS MPNDescription,
				(SELECT TOP 1 Stk.SerialNumber FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC) AS [SerialNum],
				WO.CustomerName AS Customer,
				IM_ITM.ManufacturerId,
				IM_ITM.ManufacturerName Manufacturer,
				WOM.ItemMasterId ItemMasterId,
				IM_WOP.MinimumOrderQuantity,
				0 IsFromBulkPO,
				NULL NeedBy,
				NULL EstReceivedDate,
				--PO.CreatedDate CreatedDate,
				DATEADD(day, 1, GETDATE()) CreatedDate,
				0 VendorRFQPOPartRecordId
				FROM DBO.WorkOrderPartNumber WOP WITH (NOLOCK)
				INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOP.ID
				
				INNER JOIN DBO.WorkOrderMaterials WOM WITH (NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId
				LEFT JOIN DBO.ItemMaster IM_ITM WITH (NOLOCK) ON IM_ITM.ItemMasterId = WOM.ItemMasterId
				
				INNER JOIN DBO.WorkOrder WO WITH (NOLOCK) ON WOM.WorkOrderId = WO.WorkOrderId
				INNER JOIN DBO.ItemMaster IM_WOP WITH (NOLOCK) ON IM_WOP.ItemMasterId = WOP.ItemMasterId
				INNER JOIN DBO.ItemMaster IM_Mat WITH (NOLOCK) ON IM_Mat.ItemMasterId = WOM.ItemMasterId
				INNER JOIN DBO.Condition Cond WITH (NOLOCK) ON Cond.ConditionId = WOM.ConditionCodeId
				
				LEFT JOIN DBO.WorkOrderStage WOStage WITH (NOLOCK) ON WOStage.WorkOrderStageId = WOP.WorkOrderStageId
				LEFT JOIN DBO.PurchaseOrderPart POP WITH(NOLOCK) on WOM.ItemMasterId = POP.ItemMasterId AND WO.WorkOrderId = POP.WorkOrderId
				LEFT JOIN dbo.PurchaseOrder PO WITH(NOLOCK) on POP.PurchaseOrderId = PO.PurchaseOrderId AND PO.IsFromBulkPO = 1
				LEFT JOIN DBO.VendorRFQPurchaseOrderPart POPRFQ WITH(NOLOCK) on WOM.ItemMasterId = POPRFQ.ItemMasterId AND WO.WorkOrderId = POPRFQ.WorkOrderId
				LEFT JOIN dbo.VendorRFQPurchaseOrder PORFQ WITH(NOLOCK) on POPRFQ.VendorRFQPurchaseOrderId = PORFQ.VendorRFQPurchaseOrderId AND PORFQ.IsFromBulkPO = 1
			  WHERE
			  WOP.MasterCompanyId = @MasterCompanyId AND WOStage.WorkOrderStageId = @StageId
			  AND (CASE WHEN  ISNULL(PO.IsFromBulkPO,0) = 1 OR  ISNULL(PORFQ.IsFromBulkPO,0) = 1 THEN 1 ELSE ISNULL(PO.IsFromBulkPO,0)END) != 1 
			  AND (CASE WHEN  ISNULL(PORFQ.IsFromBulkPO,0) = 1 OR ISNULL(PO.IsFromBulkPO,0) = 1  THEN 1 ELSE ISNULL(PORFQ.IsFromBulkPO,0)END) != 1 

			 UNION 

			  SELECT DISTINCT
			  	2 AS OrderNo,
			 	CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN 'PORFQ Created' ELSE'Pending' END AS [Status],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN PO.StatusId ELSE (SELECT TOP 1 VendorRFQStatusId  FROM dbo.VendorRFQStatus  WITH (NOLOCK) WHERE Status = 'Open') END As StatusId,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN (SELECT TOP 1 [Status] FROM dbo.VendorRFQStatus  WITH (NOLOCK)  WHERE VendorRFQStatusId = PO.StatusId) ELSE (SELECT TOP 1 [Status] FROM dbo.VendorRFQStatus WITH (NOLOCK)  WHERE Status = 'Open') END As StatusName,
				ISNULL(PO.VendorRFQPurchaseOrderNumber,'') poRfqNo,
				ISNULL(PO.VendorRFQPurchaseOrderId,0) PurchaseOrderId,
				WOM.WorkOrderId,
				IM_Mat.partnumber AS PN,
				IM_Mat.PartDescription AS PNDescription,
				Cond.Description AS Condition,
				WOM.ConditionCodeId AS ConditionId,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END AS Quantity,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END UnitCost,
				((CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END) * (CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END))AS ExtendedCost,
				WOM.WorkOrderMaterialsId WorkOrderMaterialsId,
				0 WorkOrderMaterialsKitId,
				WOM.ItemMasterId WOM_itemId,
				WOM.ConditionCodeId  WOM_condD,
				CASE WHEN ISNULL((SELECT TOP 1 PO.PurchaseOrderNumber FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC),'') != '' THEN  (SELECT TOP 1 ISNULL(Stk.PurchaseOrderUnitCost,0) FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC) ELSE 0 END AS [LastPurchasePrice],
				(SELECT TOP 1 PO.PurchaseOrderNumber FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC) AS [LastPONumber],
				CASE WHEN ISNULL((SELECT TOP 1 PO.PurchaseOrderNumber FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC),'') != '' THEN (SELECT TOP 1 Stk.EntryDate FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC) ELSE NULL END AS [LastPODate],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN (SELECT TOP 1 Vend.VendorName FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC) ELSE PO.VendorName END AS [VendorName],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN (SELECT TOP 1 Vend.VendorId FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC)ELSE PO.VendorId END AS [VendorId],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN (SELECT TOP 1 Vend.VendorCode FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC)ELSE (SELECT TOP 1 VendorCode FROM dbo.Vendor VN WHERE VN.VendorId = PO.VendorId) END AS [VendorCode],

				WO.WorkOrderNum AS WONum,
				IM_WOP.partnumber AS MPN,
				IM_WOP.PartDescription AS MPNDescription,
				(SELECT TOP 1 Stk.SerialNumber FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC) AS [SerialNum],
				WO.CustomerName AS Customer,
				IM_ITM.ManufacturerId,
				IM_ITM.ManufacturerName Manufacturer,
				WOM.ItemMasterId ItemMasterId,
				IM_WOP.MinimumOrderQuantity,
				ISNULL(PO.IsFromBulkPO,0) IsFromBulkPO,
				CASE WHEN ISNULL(PO.VendorRFQPurchaseOrderId,0) > 0 THEN POP.NeedByDate ELSE NULL END NeedBy,
				CASE WHEN ISNULL(PO.VendorRFQPurchaseOrderId,0) > 0 THEN  POP.PromisedDate ELSE NULL END  EstReceivedDate
				,PO.CreatedDate CreatedDate
				,POP.VendorRFQPOPartRecordId 
				FROM DBO.WorkOrderPartNumber WOP WITH (NOLOCK)
				INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOP.ID
				
				INNER JOIN DBO.WorkOrderMaterials WOM WITH (NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId
				LEFT JOIN DBO.ItemMaster IM_ITM WITH (NOLOCK) ON IM_ITM.ItemMasterId = WOM.ItemMasterId
				
				INNER JOIN DBO.WorkOrder WO WITH (NOLOCK) ON WOM.WorkOrderId = WO.WorkOrderId
				INNER JOIN DBO.ItemMaster IM_WOP WITH (NOLOCK) ON IM_WOP.ItemMasterId = WOP.ItemMasterId
				INNER JOIN DBO.ItemMaster IM_Mat WITH (NOLOCK) ON IM_Mat.ItemMasterId = WOM.ItemMasterId
				INNER JOIN DBO.Condition Cond WITH (NOLOCK) ON Cond.ConditionId = WOM.ConditionCodeId
				
				LEFT JOIN DBO.WorkOrderStage WOStage WITH (NOLOCK) ON WOStage.WorkOrderStageId = WOP.WorkOrderStageId
				INNER JOIN DBO.VendorRFQPurchaseOrderPart POP WITH(NOLOCK) on WOM.ItemMasterId = POP.ItemMasterId AND WO.WorkOrderId = POP.WorkOrderId AND POP.ConditionId = COND.ConditionId
				INNER JOIN dbo.VendorRFQPurchaseOrder PO WITH(NOLOCK) on POP.VendorRFQPurchaseOrderId = PO.VendorRFQPurchaseOrderId AND PO.IsFromBulkPO = 1
			  WHERE
			  WOP.MasterCompanyId = @MasterCompanyId AND WOStage.WorkOrderStageId = @StageId AND PO.IsFromBulkPO  = 1	


			  UNION  -- ************************************* KIT Bulk PO ***************************************
			   SELECT DISTINCT
			   	2 AS OrderNo,
			 	CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN 'PO Created' ELSE'Pending' END AS [Status],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN PO.StatusId ELSE (SELECT TOP 1 POStatusId FROM dbo.PoStatus WITH (NOLOCK)  WHERE Status = 'Open') END As StatusId,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN (SELECT TOP 1 [Status] FROM dbo.PoStatus WITH (NOLOCK)  WHERE POStatusId = PO.StatusId) ELSE (SELECT TOP 1 [Status] FROM dbo.PoStatus WITH (NOLOCK)  WHERE Status = 'Open') END As StatusName,
				ISNULL(PO.PurchaseOrderNumber,'') poRfqNo,
				ISNULL(PO.PurchaseOrderId,0) PurchaseOrderId,
				WOM.WorkOrderId,
				IM_Mat.partnumber AS PN,
				IM_Mat.PartDescription AS PNDescription,
				Cond.Description AS Condition,
				WOM.ConditionCodeId AS ConditionId,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END AS Quantity,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END UnitCost,
				((CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END) * (CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END))AS ExtendedCost,
				0 WorkOrderMaterialsId,
				WOM.WorkOrderMaterialsKitId WorkOrderMaterialsKitId,
				WOM.ItemMasterId WOM_itemId,
				WOM.ConditionCodeId  WOM_condD,
				CASE WHEN ISNULL((SELECT TOP 1 PO.PurchaseOrderNumber FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC),'') != '' THEN  (SELECT TOP 1 ISNULL(Stk.PurchaseOrderUnitCost,0) FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC) ELSE 0 END AS [LastPurchasePrice],
				(SELECT TOP 1 PO.PurchaseOrderNumber FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC) AS [LastPONumber],
				CASE WHEN ISNULL((SELECT TOP 1 PO.PurchaseOrderNumber FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC),'') != '' THEN (SELECT TOP 1 Stk.EntryDate FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC) ELSE NULL END AS [LastPODate],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN (SELECT TOP 1 Vend.VendorName FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC) ELSE PO.VendorName END AS [VendorName],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN (SELECT TOP 1 Vend.VendorId FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC)ELSE PO.VendorId END AS [VendorId],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN (SELECT TOP 1 Vend.VendorCode FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC)ELSE (SELECT TOP 1 VendorCode FROM dbo.Vendor VN WITH (NOLOCK)  WHERE VN.VendorId = PO.VendorId) END AS [VendorCode],
				WO.WorkOrderNum AS WONum,
				IM_WOP.partnumber AS MPN,
				IM_WOP.PartDescription AS MPNDescription,
				(SELECT TOP 1 Stk.SerialNumber FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC) AS [SerialNum],
				WO.CustomerName AS Customer,
				IM_ITM.ManufacturerId,
				IM_ITM.ManufacturerName Manufacturer,
				WOM.ItemMasterId ItemMasterId,
				IM_WOP.MinimumOrderQuantity,
				ISNULL(PO.IsFromBulkPO,0) IsFromBulkPO,
				CASE WHEN ISNULL(PO.PurchaseOrderId,0) > 0 THEN POP.NeedByDate ELSE NULL END NeedBy,
				CASE WHEN ISNULL(PO.PurchaseOrderId,0) > 0 THEN  POP.EstDeliveryDate ELSE NULL END  EstReceivedDate,
				PO.CreatedDate CreatedDate,
				0 VendorRFQPOPartRecordId
				FROM DBO.WorkOrderPartNumber WOP WITH (NOLOCK)
				INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOP.ID
				
				INNER JOIN DBO.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId
				LEFT JOIN DBO.ItemMaster IM_ITM WITH (NOLOCK) ON IM_ITM.ItemMasterId = WOM.ItemMasterId
				
				INNER JOIN DBO.WorkOrder WO WITH (NOLOCK) ON WOM.WorkOrderId = WO.WorkOrderId
				INNER JOIN DBO.ItemMaster IM_WOP WITH (NOLOCK) ON IM_WOP.ItemMasterId = WOP.ItemMasterId
				INNER JOIN DBO.ItemMaster IM_Mat WITH (NOLOCK) ON IM_Mat.ItemMasterId = WOM.ItemMasterId
				INNER JOIN DBO.Condition Cond WITH (NOLOCK) ON Cond.ConditionId = WOM.ConditionCodeId
				
				LEFT JOIN DBO.WorkOrderStage WOStage WITH (NOLOCK) ON WOStage.WorkOrderStageId = WOP.WorkOrderStageId
				INNER JOIN DBO.PurchaseOrderPart POP WITH(NOLOCK) on WOM.ItemMasterId = POP.ItemMasterId AND WO.WorkOrderId = POP.WorkOrderId AND POP.ConditionId = COND.ConditionId
				INNER JOIN dbo.PurchaseOrder PO WITH(NOLOCK) on POP.PurchaseOrderId = PO.PurchaseOrderId AND PO.IsFromBulkPO = 1
			  WHERE
			  WOP.MasterCompanyId = @MasterCompanyId AND WOStage.WorkOrderStageId = @StageId AND PO.IsFromBulkPO  = 1		  

			  UNION 

			 SELECT DISTINCT
			 	1 AS OrderNo,
			 	'Pending' AS [Status],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN PO.StatusId ELSE (SELECT TOP 1 POStatusId FROM dbo.PoStatus  WITH (NOLOCK)  WHERE Status = 'Open') END As StatusId,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN (SELECT TOP 1 [Status] FROM dbo.PoStatus WITH (NOLOCK)  WHERE POStatusId = PO.StatusId) ELSE (SELECT TOP 1 [Status] FROM dbo.PoStatus WITH (NOLOCK)  WHERE Status = 'Open') END As StatusName,
				'' poRfqNo,
				0 PurchaseOrderId,
				WOM.WorkOrderId,
				IM_Mat.partnumber AS PN,
				IM_Mat.PartDescription AS PNDescription,
				Cond.Description AS Condition,
				WOM.ConditionCodeId AS ConditionId,
				((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) AS Quantity,
				ISNULL(WOM.UnitCost,0) UnitCost,
				((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) * ISNULL(WOM.UnitCost,0) AS ExtendedCost,
				0 WorkOrderMaterialsId,
				WOM.WorkOrderMaterialsKitId WorkOrderMaterialsKitId,
				WOM.ItemMasterId WOM_itemId,
				WOM.ConditionCodeId  WOM_condD,
				CASE WHEN ISNULL((SELECT TOP 1 PO.PurchaseOrderNumber FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC),'') != '' THEN  (SELECT TOP 1 ISNULL(Stk.PurchaseOrderUnitCost,0) FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC) ELSE 0 END AS [LastPurchasePrice],
				(SELECT TOP 1 PO.PurchaseOrderNumber FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC) AS [LastPONumber],
				CASE WHEN ISNULL((SELECT TOP 1 PO.PurchaseOrderNumber FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC),'') != '' THEN (SELECT TOP 1 Stk.EntryDate FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC) ELSE NULL END AS [LastPODate],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN (SELECT TOP 1 Vend.VendorName FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC) ELSE PO.VendorName END AS [VendorName],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN (SELECT TOP 1 Vend.VendorId FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC)ELSE PO.VendorId END AS [VendorId],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN (SELECT TOP 1 Vend.VendorCode FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC)ELSE (SELECT TOP 1 VendorCode FROM dbo.Vendor VN WITH (NOLOCK)  WHERE VN.VendorId = PO.VendorId) END AS [VendorCode],

				WO.WorkOrderNum AS WONum,
				IM_WOP.partnumber AS MPN,
				IM_WOP.PartDescription AS MPNDescription,
				(SELECT TOP 1 Stk.SerialNumber FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC) AS [SerialNum],
				WO.CustomerName AS Customer,
				IM_ITM.ManufacturerId,
				IM_ITM.ManufacturerName Manufacturer,
				WOM.ItemMasterId ItemMasterId,
				IM_WOP.MinimumOrderQuantity,
				0 IsFromBulkPO,
				NULL NeedBy,
				NULL EstReceivedDate,
				DATEADD(day, 1, GETDATE()) CreatedDate,
				0 VendorRFQPOPartRecordId
				FROM DBO.WorkOrderPartNumber WOP WITH (NOLOCK)
				INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOP.ID
				
				INNER JOIN DBO.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId
				LEFT JOIN DBO.ItemMaster IM_ITM WITH (NOLOCK) ON IM_ITM.ItemMasterId = WOM.ItemMasterId
				
				INNER JOIN DBO.WorkOrder WO WITH (NOLOCK) ON WOM.WorkOrderId = WO.WorkOrderId
				INNER JOIN DBO.ItemMaster IM_WOP WITH (NOLOCK) ON IM_WOP.ItemMasterId = WOP.ItemMasterId
				INNER JOIN DBO.ItemMaster IM_Mat WITH (NOLOCK) ON IM_Mat.ItemMasterId = WOM.ItemMasterId
				INNER JOIN DBO.Condition Cond WITH (NOLOCK) ON Cond.ConditionId = WOM.ConditionCodeId
				
				LEFT JOIN DBO.WorkOrderStage WOStage WITH (NOLOCK) ON WOStage.WorkOrderStageId = WOP.WorkOrderStageId
				LEFT JOIN DBO.PurchaseOrderPart POP WITH(NOLOCK) on WOM.ItemMasterId = POP.ItemMasterId AND WO.WorkOrderId = POP.WorkOrderId
				LEFT JOIN dbo.PurchaseOrder PO WITH(NOLOCK) on POP.PurchaseOrderId = PO.PurchaseOrderId AND PO.IsFromBulkPO = 1
				LEFT JOIN DBO.VendorRFQPurchaseOrderPart POPRFQ WITH(NOLOCK) on WOM.ItemMasterId = POPRFQ.ItemMasterId AND WO.WorkOrderId = POPRFQ.WorkOrderId
				LEFT JOIN dbo.VendorRFQPurchaseOrder PORFQ WITH(NOLOCK) on POPRFQ.VendorRFQPurchaseOrderId = PORFQ.VendorRFQPurchaseOrderId AND PORFQ.IsFromBulkPO = 1
			  WHERE
			  WOP.MasterCompanyId = @MasterCompanyId AND WOStage.WorkOrderStageId = @StageId
			  AND (CASE WHEN  ISNULL(PO.IsFromBulkPO,0) = 1 OR  ISNULL(PORFQ.IsFromBulkPO,0) = 1 THEN 1 ELSE ISNULL(PO.IsFromBulkPO,0)END) != 1 
			  AND (CASE WHEN  ISNULL(PORFQ.IsFromBulkPO,0) = 1 OR ISNULL(PO.IsFromBulkPO,0) = 1  THEN 1 ELSE ISNULL(PORFQ.IsFromBulkPO,0)END) != 1 

			 UNION 

			  SELECT DISTINCT
			  	2 AS OrderNo,
			 	CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN 'PORFQ Created' ELSE'Pending' END AS [Status],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN PO.StatusId ELSE (SELECT TOP 1 VendorRFQStatusId  FROM dbo.VendorRFQStatus  WITH (NOLOCK) WHERE Status = 'Open') END As StatusId,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN (SELECT TOP 1 [Status] FROM dbo.VendorRFQStatus  WITH (NOLOCK)  WHERE VendorRFQStatusId = PO.StatusId) ELSE (SELECT TOP 1 [Status] FROM dbo.VendorRFQStatus WITH (NOLOCK)  WHERE Status = 'Open') END As StatusName,
				ISNULL(PO.VendorRFQPurchaseOrderNumber,'') poRfqNo,
				ISNULL(PO.VendorRFQPurchaseOrderId,0) PurchaseOrderId,
				WOM.WorkOrderId,
				IM_Mat.partnumber AS PN,
				IM_Mat.PartDescription AS PNDescription,
				Cond.Description AS Condition,
				WOM.ConditionCodeId AS ConditionId,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END AS Quantity,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END UnitCost,
				((CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END) * (CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END))AS ExtendedCost,
				0 WorkOrderMaterialsId,
				WOM.WorkOrderMaterialsKitId WorkOrderMaterialsKitId,
				WOM.ItemMasterId WOM_itemId,
				WOM.ConditionCodeId  WOM_condD,
				CASE WHEN ISNULL((SELECT TOP 1 PO.PurchaseOrderNumber FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC),'') != '' THEN  (SELECT TOP 1 ISNULL(Stk.PurchaseOrderUnitCost,0) FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC) ELSE 0 END AS [LastPurchasePrice],
				(SELECT TOP 1 PO.PurchaseOrderNumber FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC) AS [LastPONumber],
				CASE WHEN ISNULL((SELECT TOP 1 PO.PurchaseOrderNumber FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId ORDER BY Stk.CreatedDate DESC),'') != '' THEN (SELECT TOP 1 Stk.EntryDate FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC) ELSE NULL END AS [LastPODate],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN (SELECT TOP 1 Vend.VendorName FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC) ELSE PO.VendorName END AS [VendorName],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN (SELECT TOP 1 Vend.VendorId FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC)ELSE PO.VendorId END AS [VendorId],
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN (SELECT TOP 1 Vend.VendorCode FROM DBO.Stockline Stk WITH (NOLOCK) LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC)ELSE (SELECT TOP 1 VendorCode FROM dbo.Vendor VN WHERE VN.VendorId = PO.VendorId) END AS [VendorCode],

				WO.WorkOrderNum AS WONum,
				IM_WOP.partnumber AS MPN,
				IM_WOP.PartDescription AS MPNDescription,
				(SELECT TOP 1 Stk.SerialNumber FROM DBO.Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId  ORDER BY Stk.CreatedDate DESC) AS [SerialNum],
				WO.CustomerName AS Customer,
				IM_ITM.ManufacturerId,
				IM_ITM.ManufacturerName Manufacturer,
				WOM.ItemMasterId ItemMasterId,
				IM_WOP.MinimumOrderQuantity,
				ISNULL(PO.IsFromBulkPO,0) IsFromBulkPO,
				CASE WHEN ISNULL(PO.VendorRFQPurchaseOrderId,0) > 0 THEN POP.NeedByDate ELSE NULL END NeedBy,
				CASE WHEN ISNULL(PO.VendorRFQPurchaseOrderId,0) > 0 THEN  POP.PromisedDate ELSE NULL END  EstReceivedDate
				,PO.CreatedDate CreatedDate
				,POP.VendorRFQPOPartRecordId 
				FROM DBO.WorkOrderPartNumber WOP WITH (NOLOCK)
				INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOP.ID
				
				INNER JOIN DBO.WorkOrderMaterialsKit WOM WITH (NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId
				LEFT JOIN DBO.ItemMaster IM_ITM WITH (NOLOCK) ON IM_ITM.ItemMasterId = WOM.ItemMasterId
				
				INNER JOIN DBO.WorkOrder WO WITH (NOLOCK) ON WOM.WorkOrderId = WO.WorkOrderId
				INNER JOIN DBO.ItemMaster IM_WOP WITH (NOLOCK) ON IM_WOP.ItemMasterId = WOP.ItemMasterId
				INNER JOIN DBO.ItemMaster IM_Mat WITH (NOLOCK) ON IM_Mat.ItemMasterId = WOM.ItemMasterId
				INNER JOIN DBO.Condition Cond WITH (NOLOCK) ON Cond.ConditionId = WOM.ConditionCodeId
				
				LEFT JOIN DBO.WorkOrderStage WOStage WITH (NOLOCK) ON WOStage.WorkOrderStageId = WOP.WorkOrderStageId
				INNER JOIN DBO.VendorRFQPurchaseOrderPart POP WITH(NOLOCK) on WOM.ItemMasterId = POP.ItemMasterId AND WO.WorkOrderId = POP.WorkOrderId AND POP.ConditionId = COND.ConditionId
				INNER JOIN dbo.VendorRFQPurchaseOrder PO WITH(NOLOCK) on POP.VendorRFQPurchaseOrderId = PO.VendorRFQPurchaseOrderId AND PO.IsFromBulkPO = 1
			  WHERE
			  WOP.MasterCompanyId = @MasterCompanyId AND WOStage.WorkOrderStageId = @StageId AND PO.IsFromBulkPO  = 1	

			) , ResultCount AS(Select COUNT(porfqNo) AS totalItems FROM Result) 
			SELECT * INTO #TempResult FROM  Result 
			 WHERE 
			 Quantity > 0 
			 AND
			 ((@GlobalFilter <>'' AND ((PN LIKE '%' + @GlobalFilter + '%') OR
					(poRfqNo LIKE '%' + @GlobalFilter + '%') OR
					(PNDescription LIKE '%' + @GlobalFilter + '%') OR
					(Manufacturer LIKE '%' + @GlobalFilter + '%') OR
					(Condition LIKE '%' + @GlobalFilter + '%') OR
					(VendorName LIKE '%' + @GlobalFilter + '%') OR
					(NeedBy like '%' + @GlobalFilter + '%') OR
					(EstReceivedDate like '%' + @GlobalFilter + '%') OR
					(CAST(Quantity AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
					(UnitCost LIKE '%' + @GlobalFilter + '%') OR
					(Extendedcost LIKE '%' + @GlobalFilter + '%') OR
					(LastPurchasePrice like '%' + @GlobalFilter + '%') OR
					(LastPONumber like '%' + @GlobalFilter + '%') OR
					(LastPODate like '%' + @GlobalFilter + '%') OR
					(WONum like '%' + @GlobalFilter + '%') OR
					(MPN like '%' + @GlobalFilter + '%') OR
					(MPNDescription like '%' + @GlobalFilter + '%') OR
					(SerialNum like '%' + @GlobalFilter + '%') OR
					(Customer like '%' + @GlobalFilter + '%')))
					OR
					(@GlobalFilter = '' AND (ISNULL(@PN, '') = '' OR PN LIKE '%' + @PN + '%') AND
					(ISNULL(@PoRfqNo, '') = '' OR poRfqNo LIKE '%' + @PoRfqNo + '%') AND
					(ISNULL(@PNDescription, '') = '' OR PNDescription LIKE '%' + @PNDescription + '%') AND
					(ISNULL(@Manufacturer, '') = '' OR Manufacturer LIKE '%' + @Manufacturer + '%') AND
					(ISNULL(@Condition, '') = '' OR Condition LIKE '%' + @Condition + '%') AND
					(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND
					(ISNULL(@NeedBy,'') ='' OR CAST(NeedBy AS Date) = CAST(@NeedBy AS date)) AND
					(ISNULL(@EstReceivedDate,'') ='' OR CAST(EstReceivedDate AS Date) = CAST(@EstReceivedDate AS date)) AND
					(IsNull(@Quantity, 0) = 0 OR CAST(Quantity as VARCHAR(10)) like @Quantity) AND
					(ISNULL(@UnitCost, 0) = 0 OR CAST(UnitCost as VARCHAR(10)) LIKE @UnitCost) AND
					(ISNULL(@Extendedcost, 0) = 0 OR CAST(Extendedcost as VARCHAR(10)) LIKE @Extendedcost) AND
					(ISNULL(@LastPurchasePrice, 0) = 0 OR CAST(LastPurchasePrice as VARCHAR(10)) = @LastPurchasePrice) AND
					(ISNULL(@LastPONumber, '') = '' OR LastPONumber  like '%'+ @LastPONumber + '%') AND
					(ISNULL(@LastPODate,'') ='' OR CAST(LastPODate AS Date) = CAST(@LastPODate AS date)) AND
					(IsNull(@WONum, '') = '' OR WONum like '%'+ @WONum + '%') AND
					(IsNull(@MPN, '') = '' OR MPN like '%' + @MPN + '%') AND
					(IsNull(@MPNDescription, '') = '' OR MPNDescription like '%' + @MPNDescription + '%') AND
					(IsNull(@SerialNum, '') = '' OR SerialNum like '%' + @SerialNum + '%') AND
					(IsNull(@Customer, '') = '' OR Customer like '%' + @Customer + '%'))
				  )

			SELECT @Count = COUNT(porfqNo) FROM #TempResult			

			SELECT *, @Count AS NumberOfItems FROM #TempResult
			ORDER BY  
			CASE WHEN (@SortOrder=1  AND @SortColumn='OrderNo')  THEN OrderNo END ASC,
			--CASE WHEN (@SortOrder=1  AND @SortColumn='OrderNo')  THEN PurchaseOrderId END DESC,
			--CASE WHEN (@SortOrder=1  AND @SortColumn='OrderNo')  THEN CreatedDate END DESC,
			CASE WHEN (@SortOrder=-1  AND @SortColumn='OrderNo')  THEN OrderNo END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PN')  THEN PN END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PN')  THEN PN END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PNDescription')  THEN PNDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PNDescription')  THEN PNDescription END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturer')  THEN Manufacturer END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturer')  THEN Manufacturer END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Condition')  THEN Condition END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Condition')  THEN Condition END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='Quantity')  THEN Quantity END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Quantity')  THEN Quantity END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UnitCost')  THEN UnitCost END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UnitCost')  THEN UnitCost END DESC,           
			CASE WHEN (@SortOrder=1  AND @SortColumn='Extendedcost')  THEN Extendedcost END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Extendedcost')  THEN Extendedcost END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LastPurchasePrice')  THEN LastPurchasePrice END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LastPurchasePrice')  THEN LastPurchasePrice END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LastPONumber')  THEN LastPONumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LastPONumber')  THEN LastPONumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='LastPODate')  THEN LastPODate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='LastPODate')  THEN LastPODate END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='VendorName')  THEN VendorName END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='VendorName')  THEN VendorName END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='NeedBy')  THEN NeedBy END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='NeedBy')  THEN NeedBy END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='EstReceivedDate')  THEN EstReceivedDate END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='EstReceivedDate')  THEN EstReceivedDate END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='WONum')  THEN WONum END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='WONum')  THEN WONum END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='MPN')  THEN MPN END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='MPN')  THEN MPN END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='MPNDescription')  THEN MPNDescription END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='MPNDescription')  THEN MPNDescription END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='SerialNum')  THEN SerialNum END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='SerialNum')  THEN SerialNum END DESC,
			CASE WHEN (@SortOrder=1 and @SortColumn='Customer')  THEN Customer END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='Customer')  THEN Customer END DESC,
		    CASE WHEN (@SortOrder=1 and @SortColumn='PORFQNO')  THEN poRfqNo END ASC,
			CASE WHEN (@SortOrder=-1 and @SortColumn='PORFQNO')  THEN poRfqNo END DESC
			,CreatedDate  DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
		END
		COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetBulkPOProcessingList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@PoRfqNo, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
            RETURN(1);
	END CATCH
END