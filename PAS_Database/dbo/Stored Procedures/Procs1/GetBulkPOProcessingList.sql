/***************************************************************************************************************************************             
  ** Change History             
 ***************************************************************************************************************************************             
 ** PR   Date						 Author							Change Description              
 ** --   --------					 -------						-------------------------------            
    1   
	2    16/11/2023				 Ayesha Sultana						Modified - Filter on status implementation & inline filter bug fixes
	3    02/11/2024              MOIN BLOCH                         OPTIMIZE SP
****************************************************************************************************************************************/ 

CREATE      PROCEDURE [dbo].[GetBulkPOProcessingList]
@PageNumber INT = 1,
@PageSize INT = 10,
@SortColumn VARCHAR(50)=NULL,
@SortOrder INT = NULL,
@StatusId INT = 1,
@Status VARCHAR(50) = 'Pending',
@GlobalFilter VARCHAR(50) = '',	
@statusName VARCHAR(50)=null,
@PoRfqNo VARCHAR(50) = NULL,
@PN VARCHAR(100) = NULL,
@PNDescription VARCHAR(200) = NULL,
@Manufacturer VARCHAR(200) = NULL,
@Condition VARCHAR(100) = NULL,
@Quantity INT = NULL,
@UnitCost DECIMAL(18,2) = NULL,
@ExtendedCost DECIMAL(18,2) = NULL,
@LastPurchasePrice DECIMAL(18,2) = NULL,
@LastPONumber VARCHAR(50) = NULL,
@lastPODate DATETIME = NULL,
@VendorId BIGINT = NULL,
@VendorName VARCHAR(50) = NULL,
@NeedBy DATETIME = NULL,
@EstReceivedDate DATETIME = NULL,
@WONum VARCHAR(50) = NULL,
@SONum VARCHAR(50) = NULL,
@MPN VARCHAR(50) = NULL,
@MPNDescription VARCHAR(50) = NULL,
@SerialNum VARCHAR(50) = NULL,
@Customer VARCHAR(50) = NULL,
@CreatedBy  VARCHAR(50) = NULL,
@CreatedDate datetime = NULL,
@UpdatedBy  VARCHAR(50) = NULL,
@UpdatedDate  DATETIME = NULL,
@EmployeeId BIGINT = NULL,
@MasterCompanyId BIGINT = NULL,
@IsPOGenerated BIT =NULL,
@ReturnIds VARCHAR(MAX) = NULL,
@filterAsStatus VARCHAR(20) = NULL
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		DECLARE @RecordFrom INT;
		DECLARE @IsActive BIT = 1;
		DECLARE @Count INT;
		DECLARE @StageId BIGINT = 0;
		DECLARE @POOpenStatusId INT;
		DECLARE @POOpenStatus VARCHAR(10);
		DECLARE @RFQPOOpenStatusId INT;
		DECLARE @RFQPOOpenStatus VARCHAR(10);
		SET @RecordFrom = (@PageNumber - 1) * @PageSize;
		
		SELECT @StageId = [WorkOrderStageId] FROM [dbo].[PurchaseOrderSettingMaster] WITH (NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;
		SELECT @POOpenStatusId = [POStatusId] FROM [dbo].[PoStatus] WITH (NOLOCK)  WHERE UPPER([Status]) = 'OPEN'; 
		SELECT @POOpenStatus = [Status] FROM [dbo].[PoStatus] WITH (NOLOCK) WHERE UPPER([Status]) = 'OPEN';
		SELECT @RFQPOOpenStatusId = [VendorRFQStatusId]  FROM [dbo].[VendorRFQStatus]  WITH (NOLOCK) WHERE UPPER([Status]) = 'OPEN';
		SELECT @RFQPOOpenStatus = [Status] FROM [dbo].[VendorRFQStatus] WITH (NOLOCK) WHERE UPPER([Status]) = 'OPEN';

			IF OBJECT_ID(N'tempdb..#TEMPBulkPORecords') IS NOT NULL    
			BEGIN    
				DROP TABLE #TEMPBulkPORecords
			END

			CREATE TABLE #TEMPBulkPORecords(        
				[ID] BIGINT IDENTITY(1,1),      
			    [OrderNo] INT NULL,
				[ItemMasterId] BIGINT NULL,
				[StatusId] INT NULL,
				[StatusName] VARCHAR(10) NULL,
				[poRfqNo] VARCHAR(20) NULL,
				[PurchaseOrderId] BIGINT NULL,
				[PN] VARCHAR(50) NULL,
				[PNDescription] NVARCHAR(MAX) NULL,
				[Condition]	VARCHAR(20) NULL,
				[ConditionCodeId] BIGINT NULL,
				[Quantity] INT NULL,
				[UnitCost] DECIMAL(18,2) NULL,
				[ExtendedCost] DECIMAL(18,2) NULL,
				[LastPurchasePrice]	DECIMAL(18,2) NULL, 
				[LastPONumber] VARCHAR(20) NULL,
				[LastPODate] DATETIME NULL,
				[VendorName] VARCHAR(50) NULL,
				[VendorId] BIGINT NULL,
				[VendorCode] VARCHAR(20) NULL,
				[WONum] VARCHAR(20) NULL,
				[MPN] VARCHAR(50) NULL,
				[MPNDescription]  NVARCHAR(MAX) NULL,
				[SerialNum] VARCHAR(50) NULL,
				[Customer] VARCHAR(20) NULL,
				[Manufacturer] VARCHAR(50) NULL,
				[MinimumOrderQuantity] INT NULL,
				[IsFromBulkPO] BIT NULL,
				[NeedBy] DATETIME NULL,
				[EstReceivedDate] DATETIME NULL,
				[VendorRFQPOPartRecordId] BIGINT NULL,
				[CreatedDate] DATETIME NULL
			) 

		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn = UPPER('CreatedDate')
		END 
		ELSE
		BEGIN 
			SET @SortColumn = UPPER(@SortColumn)
		END
		
		IF (@filterAsStatus = '')
		BEGIN			
			SET @filterAsStatus = 'all'
		END

		IF (@filterAsStatus = NULL)
		BEGIN			
			SET @filterAsStatus = 'all'
		END

		IF(@ReturnIds IS NOT NULL AND @ReturnIds != '')
		BEGIN
			SET @SortColumn = UPPER('OrderNo')
			SET @SortOrder = 1
		END		
		BEGIN TRY
		
		IF (@filterAsStatus = 'all')
		BEGIN
			-- 1
			INSERT INTO #TEMPBulkPORecords([OrderNo],[ItemMasterId],[StatusId],[StatusName],[poRfqNo],[PurchaseOrderId],[PN],[PNDescription],[Condition],[ConditionCodeId],[Quantity],
				[UnitCost],[ExtendedCost],[LastPurchasePrice],[LastPONumber],[LastPODate],[VendorName],[VendorId],[VendorCode],[WONum],[MPN],
				[MPNDescription],[SerialNum],[Customer],[Manufacturer],[MinimumOrderQuantity],[IsFromBulkPO],[NeedBy],[EstReceivedDate],[VendorRFQPOPartRecordId],[CreatedDate])
		 
		   	 SELECT 
				2 AS OrderNo,
				WOM.ItemMasterId,
				COALESCE(NULLIF(PO.IsFromBulkPO, 0), @POOpenStatusId),				
				COALESCE((SELECT [Status] FROM [dbo].[PoStatus] WITH (NOLOCK) WHERE [POStatusId] = PO.[StatusId]),  @POOpenStatus),				
				ISNULL(PO.PurchaseOrderNumber,''),
				ISNULL(PO.PurchaseOrderId,0),			
				IM_ITM.partnumber,
				IM_ITM.PartDescription,				
				Cond.[Description],	
				WOM.ConditionCodeId,				
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END,
				((CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END) * (CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END)),													
				0,
				'',
				NULL,
				PO.VendorName,
				PO.VendorId,
				ISNULL((SELECT TOP 1 VendorCode FROM dbo.Vendor VN WITH (NOLOCK) WHERE VN.VendorId = PO.VendorId),''),							
				WO.WorkOrderNum,
				IM_WOP.partnumber,
				IM_WOP.PartDescription,
				'',
				WO.CustomerName,			
				IM_ITM.ManufacturerName,			
				IM_WOP.MinimumOrderQuantity,
				ISNULL(PO.IsFromBulkPO,0),
				CASE WHEN ISNULL(PO.PurchaseOrderId,0) > 0 THEN POP.NeedByDate ELSE NULL END,
				CASE WHEN ISNULL(PO.PurchaseOrderId,0) > 0 THEN  POP.EstDeliveryDate ELSE NULL END,
				0 VendorRFQPOPartRecordId,	
				PO.CreatedDate
			FROM [dbo].[WorkOrderMaterials] WOM WITH (NOLOCK)
				INNER JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH (NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId	
				INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOP.ID	
				INNER JOIN [dbo].[ItemMaster] IM_ITM WITH (NOLOCK) ON IM_ITM.ItemMasterId = WOM.ItemMasterId				
			    INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId
			    INNER JOIN [dbo].[ItemMaster] IM_WOP WITH (NOLOCK) ON IM_WOP.ItemMasterId = WOP.ItemMasterId
			    INNER JOIN [dbo].[Condition] Cond WITH (NOLOCK) ON Cond.ConditionId = WOM.ConditionCodeId				
			    INNER JOIN [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) ON WOM.ItemMasterId = POP.ItemMasterId AND WO.WorkOrderId = POP.WorkOrderId AND POP.ConditionId = COND.ConditionId
			    INNER JOIN [dbo].[PurchaseOrder] PO WITH(NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND PO.IsFromBulkPO = 1
												
		   WHERE WOP.MasterCompanyId = @MasterCompanyId AND WOP.WorkOrderStageId = @StageId AND PO.IsFromBulkPO  = 1 
				
		 --  UPDATE #TEMPBulkPORecords SET [LastPurchasePrice] = ISNULL(tmpcash.[PurchaseOrderUnitCost],0),
		 --                                [LastPONumber] = ISNULL(tmpcash.[PurchaseOrderNumber],''),
			--							 [LastPODate] = [EntryDate],
			--							 [SerialNum] = [SerialNumber]
			--FROM (SELECT TOP 1 Stk.[PurchaseOrderUnitCost],PO.[PurchaseOrderNumber],Stk.[EntryDate],Stk.[ItemMasterId],Stk.[ConditionId],Stk.[SerialNumber]
			--		FROM [dbo].[Stockline] Stk WITH (NOLOCK) 
			--		JOIN #TEMPBulkPORecords temp ON temp.ItemMasterId = Stk.ItemMasterId AND temp.ConditionCodeId = Stk.ConditionId	
			--		LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId
			--		ORDER BY Stk.[CreatedDate] DESC					
			--)tmpcash WHERE tmpcash.ItemMasterId = #TEMPBulkPORecords.ItemMasterId AND tmpcash.ConditionId = #TEMPBulkPORecords.ConditionCodeId
			
			--UPDATE #TEMPBulkPORecords SET [VendorName] = CASE WHEN ISNULL(tmpcash.IsFromBulkPO,0) = 0 THEN ISNULL(tmpcash.[VendorName],'')  ELSE ISNULL(tmpcash.POVendorName,'') END,  
			--                              [VendorCode] = CASE WHEN ISNULL(tmpcash.IsFromBulkPO,0) = 0 THEN ISNULL(tmpcash.[VendorCode],'')  ELSE ISNULL(tmpcash.POVendorCode,'') END  
			--FROM (SELECT TOP 1 Vend.VendorName,Vend.VendorCode, temp.VendorName AS POVendorName,temp.VendorCode AS POVendorCode ,temp.IsFromBulkPO,Stk.[ItemMasterId],Stk.[ConditionId]
			--	FROM DBO.Stockline Stk WITH (NOLOCK) 
			--	LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId				
			--	JOIN #TEMPBulkPORecords temp ON temp.ItemMasterId = Stk.ItemMasterId AND temp.ConditionCodeId = Stk.ConditionId	
			
			--)tmpcash WHERE tmpcash.ItemMasterId = #TEMPBulkPORecords.ItemMasterId AND tmpcash.ConditionId = #TEMPBulkPORecords.ConditionCodeId

			--  2
			INSERT INTO #TEMPBulkPORecords([OrderNo],[ItemMasterId],[StatusId],[StatusName],[poRfqNo],[PurchaseOrderId],[PN],[PNDescription],[Condition],[ConditionCodeId],[Quantity],
				[UnitCost],[ExtendedCost],[LastPurchasePrice],[LastPONumber],[LastPODate],[VendorName],[VendorId],[VendorCode],[WONum],[MPN],
				[MPNDescription],[SerialNum],[Customer],[Manufacturer],[MinimumOrderQuantity],[IsFromBulkPO],[NeedBy],[EstReceivedDate],[VendorRFQPOPartRecordId],[CreatedDate])
			 SELECT 
			 	1 AS OrderNo,	
				WOM.ItemMasterId,
				COALESCE(NULLIF(PO.IsFromBulkPO, 0), @POOpenStatusId),
				COALESCE((SELECT [Status] FROM [dbo].[PoStatus] WITH (NOLOCK) WHERE [POStatusId] = PO.[StatusId]),  @POOpenStatus),
				'',
				0,			
				IM_ITM.partnumber,
				IM_ITM.PartDescription,
				Cond.[Description],
				WOM.ConditionCodeId,
				((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)),
				ISNULL(WOM.UnitCost,0),
				((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) * ISNULL(WOM.UnitCost,0),						
				0,
				'',
				NULL,
				PO.VendorName,
				PO.VendorId,
				ISNULL((SELECT TOP 1 VendorCode FROM dbo.Vendor VN WITH (NOLOCK) WHERE VN.VendorId = PO.VendorId),''),	
				WO.WorkOrderNum,
				IM_WOP.partnumber,
				IM_WOP.PartDescription,
				'',
				WO.CustomerName,
				IM_ITM.ManufacturerName,
				IM_WOP.MinimumOrderQuantity,
				0,
				NULL,
				NULL,
				0,
				DATEADD(day, 1, GETDATE()) 
				FROM [dbo].[WorkOrderMaterials] WOM WITH (NOLOCK)
					INNER JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH (NOLOCK) ON	WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId				
					INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOP.ID
					LEFT JOIN  [dbo].[ItemMaster] IM_ITM WITH (NOLOCK) ON IM_ITM.ItemMasterId = WOM.ItemMasterId				
					INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId
					INNER JOIN [dbo].[ItemMaster] IM_WOP WITH (NOLOCK) ON IM_WOP.ItemMasterId = WOP.ItemMasterId
					INNER JOIN [dbo].[Condition] Cond WITH (NOLOCK) ON Cond.ConditionId = WOM.ConditionCodeId				
					LEFT JOIN  [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) on WOM.ItemMasterId = POP.ItemMasterId AND WO.WorkOrderId = POP.WorkOrderId
					LEFT JOIN  [dbo].[PurchaseOrder] PO WITH(NOLOCK) on POP.PurchaseOrderId = PO.PurchaseOrderId AND PO.IsFromBulkPO = 1
					LEFT JOIN  [dbo].[VendorRFQPurchaseOrderPart] POPRFQ WITH(NOLOCK) on WOM.ItemMasterId = POPRFQ.ItemMasterId AND WO.WorkOrderId = POPRFQ.WorkOrderId
					LEFT JOIN  [dbo].[VendorRFQPurchaseOrder] PORFQ WITH(NOLOCK) on POPRFQ.VendorRFQPurchaseOrderId = PORFQ.VendorRFQPurchaseOrderId AND PORFQ.IsFromBulkPO = 1
			  WHERE WOP.MasterCompanyId = @MasterCompanyId AND WOP.WorkOrderStageId = @StageId
					  AND (CASE WHEN  ISNULL(PO.IsFromBulkPO,0) = 1 OR  ISNULL(PORFQ.IsFromBulkPO,0) = 1 THEN 1 ELSE ISNULL(PO.IsFromBulkPO,0)END) != 1 
					  AND (CASE WHEN  ISNULL(PORFQ.IsFromBulkPO,0) = 1 OR ISNULL(PO.IsFromBulkPO,0) = 1  THEN 1 ELSE ISNULL(PORFQ.IsFromBulkPO,0)END) != 1 

			-- UPDATE #TEMPBulkPORecords SET [LastPurchasePrice] = ISNULL(tmpcash2.[PurchaseOrderUnitCost],0),
		 --                                [LastPONumber] = ISNULL(tmpcash2.[PurchaseOrderNumber],''),
			--							 [LastPODate] = [EntryDate],
			--							 [SerialNum] = [SerialNumber]
			--FROM (SELECT TOP 1 Stk.[PurchaseOrderUnitCost],PO.[PurchaseOrderNumber],Stk.[EntryDate],Stk.[ItemMasterId],Stk.[ConditionId],Stk.[SerialNumber]
			--		FROM [dbo].[Stockline] Stk WITH (NOLOCK) 
			--		JOIN #TEMPBulkPORecords temp ON temp.ItemMasterId = Stk.ItemMasterId AND temp.ConditionCodeId = Stk.ConditionId	
			--		LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId
			--		ORDER BY Stk.[CreatedDate] DESC					
			--)tmpcash2 WHERE tmpcash2.ItemMasterId = #TEMPBulkPORecords.ItemMasterId AND tmpcash2.ConditionId = #TEMPBulkPORecords.ConditionCodeId
			
			--UPDATE #TEMPBulkPORecords SET [VendorName] = CASE WHEN ISNULL(tmpcash2.IsFromBulkPO,0) = 0 THEN ISNULL(tmpcash2.[VendorName],'')  ELSE ISNULL(tmpcash2.POVendorName,'') END,  
			--                              [VendorCode] = CASE WHEN ISNULL(tmpcash2.IsFromBulkPO,0) = 0 THEN ISNULL(tmpcash2.[VendorCode],'')  ELSE ISNULL(tmpcash2.POVendorCode,'') END  
			--FROM (SELECT TOP 1 Vend.VendorName,Vend.VendorCode, temp.VendorName AS POVendorName,temp.VendorCode AS POVendorCode ,temp.IsFromBulkPO,Stk.[ItemMasterId],Stk.[ConditionId]
			--	FROM DBO.Stockline Stk WITH (NOLOCK) 
			--	LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId				
			--	JOIN #TEMPBulkPORecords temp ON temp.ItemMasterId = Stk.ItemMasterId AND temp.ConditionCodeId = Stk.ConditionId	
			
			--)tmpcash2 WHERE tmpcash2.ItemMasterId = #TEMPBulkPORecords.ItemMasterId AND tmpcash2.ConditionId = #TEMPBulkPORecords.ConditionCodeId
			
			--3

			INSERT INTO #TEMPBulkPORecords([OrderNo],[ItemMasterId],[StatusId],[StatusName],[poRfqNo],[PurchaseOrderId],[PN],[PNDescription],[Condition],[ConditionCodeId],[Quantity],
				[UnitCost],[ExtendedCost],[LastPurchasePrice],[LastPONumber],[LastPODate],[VendorName],[VendorId],[VendorCode],[WONum],[MPN],
				[MPNDescription],[SerialNum],[Customer],[Manufacturer],[MinimumOrderQuantity],[IsFromBulkPO],[NeedBy],[EstReceivedDate],[VendorRFQPOPartRecordId],[CreatedDate])
			  SELECT 
			  	2 AS OrderNo,
				WOM.ItemMasterId,
				COALESCE(NULLIF(PO.IsFromBulkPO, 0), @RFQPOOpenStatusId),
				COALESCE((SELECT [Status] FROM [dbo].[VendorRFQStatus] WITH (NOLOCK) WHERE [VendorRFQStatusId] = PO.[StatusId]),  @RFQPOOpenStatus),				
				ISNULL(PO.VendorRFQPurchaseOrderNumber,''),
				ISNULL(PO.VendorRFQPurchaseOrderId,0),				
				IM_ITM.partnumber,
				IM_ITM.PartDescription,
				Cond.[Description],
				WOM.ConditionCodeId,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END,
				((CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END) * (CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END)),
				0,
				'', 
				NULL,
				PO.VendorName,
				PO.VendorId,
				ISNULL((SELECT TOP 1 VendorCode FROM dbo.Vendor VN WITH (NOLOCK) WHERE VN.VendorId = PO.VendorId),''),					
				WO.WorkOrderNum,
				IM_WOP.partnumber,
				IM_WOP.PartDescription,
				'',
				WO.CustomerName,
				IM_ITM.ManufacturerName,
				IM_WOP.MinimumOrderQuantity,
				ISNULL(PO.IsFromBulkPO,0),
				CASE WHEN ISNULL(PO.VendorRFQPurchaseOrderId,0) > 0 THEN POP.NeedByDate ELSE NULL END,
				CASE WHEN ISNULL(PO.VendorRFQPurchaseOrderId,0) > 0 THEN  POP.PromisedDate ELSE NULL END
				,POP.VendorRFQPOPartRecordId 
				,PO.CreatedDate
				FROM [dbo].[WorkOrderMaterials] WOM  WITH (NOLOCK)
					INNER JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH (NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId	
					INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON  WOWF.WorkOrderPartNoId = WOP.ID			
					LEFT JOIN  [dbo].[ItemMaster] IM_ITM WITH (NOLOCK) ON IM_ITM.ItemMasterId = WOM.ItemMasterId				
					INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId
					INNER JOIN [dbo].[ItemMaster] IM_WOP WITH (NOLOCK) ON IM_WOP.ItemMasterId = WOP.ItemMasterId
					INNER JOIN [dbo].[Condition] Cond WITH (NOLOCK) ON Cond.ConditionId = WOM.ConditionCodeId				
					INNER JOIN [dbo].[VendorRFQPurchaseOrderPart] POP WITH(NOLOCK) on WOM.ItemMasterId = POP.ItemMasterId AND WO.WorkOrderId = POP.WorkOrderId AND POP.ConditionId = COND.ConditionId
					INNER JOIN [dbo].[VendorRFQPurchaseOrder] PO WITH(NOLOCK) on POP.VendorRFQPurchaseOrderId = PO.VendorRFQPurchaseOrderId AND PO.IsFromBulkPO = 1
			  WHERE WOP.MasterCompanyId = @MasterCompanyId AND WOP.WorkOrderStageId = @StageId AND PO.IsFromBulkPO  = 1 
		   
		 --  UPDATE #TEMPBulkPORecords SET [LastPurchasePrice] = ISNULL(tmpcash.[PurchaseOrderUnitCost],0),
		 --                                [LastPONumber] = ISNULL(tmpcash.[PurchaseOrderNumber],''),
			--							 [LastPODate] = [EntryDate],
			--							 [SerialNum] = [SerialNumber]
			--FROM (SELECT TOP 1 Stk.[PurchaseOrderUnitCost],PO.[PurchaseOrderNumber],Stk.[EntryDate],Stk.[ItemMasterId],Stk.[ConditionId],Stk.[SerialNumber]
			--		FROM [dbo].[Stockline] Stk WITH (NOLOCK) 
			--		JOIN #TEMPBulkPORecords temp ON temp.ItemMasterId = Stk.ItemMasterId AND temp.ConditionCodeId = Stk.ConditionId	
			--		LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId
			--		ORDER BY Stk.[CreatedDate] DESC					
			--)tmpcash WHERE tmpcash.ItemMasterId = #TEMPBulkPORecords.ItemMasterId AND tmpcash.ConditionId = #TEMPBulkPORecords.ConditionCodeId
			
			--UPDATE #TEMPBulkPORecords SET [VendorName] = CASE WHEN ISNULL(tmpcash.IsFromBulkPO,0) = 0 THEN ISNULL(tmpcash.[VendorName],'')  ELSE ISNULL(tmpcash.POVendorName,'') END,  
			--                              [VendorCode] = CASE WHEN ISNULL(tmpcash.IsFromBulkPO,0) = 0 THEN ISNULL(tmpcash.[VendorCode],'')  ELSE ISNULL(tmpcash.POVendorCode,'') END  
			--FROM (SELECT TOP 1 Vend.VendorName,Vend.VendorCode, temp.VendorName AS POVendorName,temp.VendorCode AS POVendorCode ,temp.IsFromBulkPO,Stk.[ItemMasterId],Stk.[ConditionId]
			--	FROM DBO.Stockline Stk WITH (NOLOCK) 
			--	LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId				
			--	JOIN #TEMPBulkPORecords temp ON temp.ItemMasterId = Stk.ItemMasterId AND temp.ConditionCodeId = Stk.ConditionId	
			
			--)tmpcash WHERE tmpcash.ItemMasterId = #TEMPBulkPORecords.ItemMasterId AND tmpcash.ConditionId = #TEMPBulkPORecords.ConditionCodeId
			
			--4

			INSERT INTO #TEMPBulkPORecords([OrderNo],[ItemMasterId],[StatusId],[StatusName],[poRfqNo],[PurchaseOrderId],[PN],[PNDescription],[Condition],[ConditionCodeId],[Quantity],
				[UnitCost],[ExtendedCost],[LastPurchasePrice],[LastPONumber],[LastPODate],[VendorName],[VendorId],[VendorCode],[WONum],[MPN],
				[MPNDescription],[SerialNum],[Customer],[Manufacturer],[MinimumOrderQuantity],[IsFromBulkPO],[NeedBy],[EstReceivedDate],[VendorRFQPOPartRecordId],[CreatedDate])
			 SELECT 
			   	2 AS OrderNo,
				WOM.ItemMasterId,
				COALESCE(NULLIF(PO.IsFromBulkPO, 0),  @POOpenStatusId),
				COALESCE((SELECT [Status] FROM [dbo].[PoStatus] WITH (NOLOCK) WHERE [POStatusId] = PO.[StatusId]),  @POOpenStatus),
				ISNULL(PO.PurchaseOrderNumber,''),
				ISNULL(PO.PurchaseOrderId,0),				
				IM_ITM.partnumber,
				IM_ITM.PartDescription,
				Cond.[Description],
				WOM.ConditionCodeId,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END,
				((CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END) * (CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END)),				
				0,
				'',
				NULL,
				PO.VendorName,
				PO.VendorId,
				ISNULL((SELECT TOP 1 VendorCode FROM dbo.Vendor VN WITH (NOLOCK) WHERE VN.VendorId = PO.VendorId),''),	
				WO.WorkOrderNum,
				IM_WOP.partnumber,
				IM_WOP.PartDescription,
				'',
				WO.CustomerName,
				IM_ITM.ManufacturerName,
				IM_WOP.MinimumOrderQuantity,
				ISNULL(PO.IsFromBulkPO,0),
				CASE WHEN ISNULL(PO.PurchaseOrderId,0) > 0 THEN POP.NeedByDate ELSE NULL END,
				CASE WHEN ISNULL(PO.PurchaseOrderId,0) > 0 THEN  POP.EstDeliveryDate ELSE NULL END,
				0 VendorRFQPOPartRecordId,
				PO.CreatedDate 
				FROM[dbo].[WorkOrderMaterialsKit] WOM  WITH (NOLOCK)
					INNER JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH (NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId		
					INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOP.ID		
					LEFT JOIN  [dbo].[ItemMaster] IM_ITM WITH (NOLOCK) ON IM_ITM.ItemMasterId = WOM.ItemMasterId				
					INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId
					INNER JOIN [dbo].[ItemMaster] IM_WOP WITH (NOLOCK) ON IM_WOP.ItemMasterId = WOP.ItemMasterId
					INNER JOIN [dbo].[Condition] Cond WITH (NOLOCK) ON Cond.ConditionId = WOM.ConditionCodeId				
					INNER JOIN [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) ON WOM.ItemMasterId = POP.ItemMasterId AND WO.WorkOrderId = POP.WorkOrderId AND POP.ConditionId = COND.ConditionId
					INNER JOIN [dbo].[PurchaseOrder] PO WITH(NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND PO.IsFromBulkPO = 1
			  WHERE WOP.MasterCompanyId = @MasterCompanyId AND WOP.WorkOrderStageId = @StageId AND PO.IsFromBulkPO  = 1 
			  
			--UPDATE #TEMPBulkPORecords SET [LastPurchasePrice] = ISNULL(tmpcash.[PurchaseOrderUnitCost],0),
		 --                                [LastPONumber] = ISNULL(tmpcash.[PurchaseOrderNumber],''),
			--							 [LastPODate] = [EntryDate],
			--							 [SerialNum] = [SerialNumber]
			--FROM (SELECT TOP 1 Stk.[PurchaseOrderUnitCost],PO.[PurchaseOrderNumber],Stk.[EntryDate],Stk.[ItemMasterId],Stk.[ConditionId],Stk.[SerialNumber]
			--		FROM [dbo].[Stockline] Stk WITH (NOLOCK) 
			--		JOIN #TEMPBulkPORecords temp ON temp.ItemMasterId = Stk.ItemMasterId AND temp.ConditionCodeId = Stk.ConditionId	
			--		LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId
			--		ORDER BY Stk.[CreatedDate] DESC					
			--)tmpcash WHERE tmpcash.ItemMasterId = #TEMPBulkPORecords.ItemMasterId AND tmpcash.ConditionId = #TEMPBulkPORecords.ConditionCodeId
			
			--UPDATE #TEMPBulkPORecords SET [VendorName] = CASE WHEN ISNULL(tmpcash.IsFromBulkPO,0) = 0 THEN ISNULL(tmpcash.[VendorName],'')  ELSE ISNULL(tmpcash.POVendorName,'') END,  
			--                              [VendorCode] = CASE WHEN ISNULL(tmpcash.IsFromBulkPO,0) = 0 THEN ISNULL(tmpcash.[VendorCode],'')  ELSE ISNULL(tmpcash.POVendorCode,'') END  
			--FROM (SELECT TOP 1 Vend.VendorName,Vend.VendorCode, temp.VendorName AS POVendorName,temp.VendorCode AS POVendorCode ,temp.IsFromBulkPO,Stk.[ItemMasterId],Stk.[ConditionId]
			--	FROM DBO.Stockline Stk WITH (NOLOCK) 
			--	LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId				
			--	JOIN #TEMPBulkPORecords temp ON temp.ItemMasterId = Stk.ItemMasterId AND temp.ConditionCodeId = Stk.ConditionId	
			
			--)tmpcash WHERE tmpcash.ItemMasterId = #TEMPBulkPORecords.ItemMasterId AND tmpcash.ConditionId = #TEMPBulkPORecords.ConditionCodeId
			
		--5

			INSERT INTO #TEMPBulkPORecords([OrderNo],[ItemMasterId],[StatusId],[StatusName],[poRfqNo],[PurchaseOrderId],[PN],[PNDescription],[Condition],[ConditionCodeId],[Quantity],
				[UnitCost],[ExtendedCost],[LastPurchasePrice],[LastPONumber],[LastPODate],[VendorName],[VendorId],[VendorCode],[WONum],[MPN],
				[MPNDescription],[SerialNum],[Customer],[Manufacturer],[MinimumOrderQuantity],[IsFromBulkPO],[NeedBy],[EstReceivedDate],[VendorRFQPOPartRecordId],[CreatedDate])			
			SELECT 
			 	1 AS OrderNo,		
				WOM.ItemMasterId,
				COALESCE(NULLIF(PO.IsFromBulkPO, 0), @POOpenStatusId),
				COALESCE((SELECT [Status] FROM [dbo].[PoStatus] WITH (NOLOCK) WHERE [POStatusId] = PO.[StatusId]),  @POOpenStatus),
				'',
				0 PurchaseOrderId,				
				IM_ITM.partnumber,
				IM_ITM.PartDescription,
				Cond.[Description],
				WOM.ConditionCodeId,
				((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)),
				ISNULL(WOM.UnitCost,0),
				((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) * ISNULL(WOM.UnitCost,0),
	            0,
				'',
				NULL,
				PO.VendorName,
				PO.VendorId,
				ISNULL((SELECT TOP 1 VendorCode FROM dbo.Vendor VN WITH (NOLOCK) WHERE VN.VendorId = PO.VendorId),''),	
				WO.WorkOrderNum,
				IM_WOP.partnumber,
				IM_WOP.PartDescription,
				'',
				WO.CustomerName,
				IM_ITM.ManufacturerName,
				IM_WOP.MinimumOrderQuantity,
				0 IsFromBulkPO,
				NULL,
				NULL,
				0 VendorRFQPOPartRecordId,
				DATEADD(DAY, 1, GETDATE())
				FROM [dbo].[WorkOrderMaterialsKit] WOM WITH (NOLOCK)
					INNER JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH (NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId		
					INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON  WOWF.WorkOrderPartNoId = WOP.ID	
					LEFT JOIN  [dbo].[ItemMaster] IM_ITM WITH (NOLOCK) ON IM_ITM.ItemMasterId = WOM.ItemMasterId				
					INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOM.WorkOrderId = WO.WorkOrderId
					INNER JOIN [dbo].[ItemMaster] IM_WOP WITH (NOLOCK) ON IM_WOP.ItemMasterId = WOP.ItemMasterId
					INNER JOIN [dbo].[Condition] Cond WITH (NOLOCK) ON Cond.ConditionId = WOM.ConditionCodeId				
					LEFT JOIN  [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) on WOM.ItemMasterId = POP.ItemMasterId AND WO.WorkOrderId = POP.WorkOrderId
					LEFT JOIN  [dbo].[PurchaseOrder] PO WITH(NOLOCK) on POP.PurchaseOrderId = PO.PurchaseOrderId AND PO.IsFromBulkPO = 1
					LEFT JOIN  [dbo].[VendorRFQPurchaseOrderPart] POPRFQ WITH(NOLOCK) on WOM.ItemMasterId = POPRFQ.ItemMasterId AND WO.WorkOrderId = POPRFQ.WorkOrderId
					LEFT JOIN  [dbo].[VendorRFQPurchaseOrder] PORFQ WITH(NOLOCK) on POPRFQ.VendorRFQPurchaseOrderId = PORFQ.VendorRFQPurchaseOrderId AND PORFQ.IsFromBulkPO = 1
			  WHERE WOP.MasterCompanyId = @MasterCompanyId AND WOP.WorkOrderStageId = @StageId
			  AND (CASE WHEN  ISNULL(PO.IsFromBulkPO,0) = 1 OR  ISNULL(PORFQ.IsFromBulkPO,0) = 1 THEN 1 ELSE ISNULL(PO.IsFromBulkPO,0)END) != 1 
			  AND (CASE WHEN  ISNULL(PORFQ.IsFromBulkPO,0) = 1 OR ISNULL(PO.IsFromBulkPO,0) = 1  THEN 1 ELSE ISNULL(PORFQ.IsFromBulkPO,0)END) != 1 

			--  UPDATE #TEMPBulkPORecords SET [LastPurchasePrice] = ISNULL(tmpcash.[PurchaseOrderUnitCost],0),
		 --                                [LastPONumber] = ISNULL(tmpcash.[PurchaseOrderNumber],''),
			--							 [LastPODate] = [EntryDate],
			--							 [SerialNum] = [SerialNumber]
			--FROM (SELECT TOP 1 Stk.[PurchaseOrderUnitCost],PO.[PurchaseOrderNumber],Stk.[EntryDate],Stk.[ItemMasterId],Stk.[ConditionId],Stk.[SerialNumber]
			--		FROM [dbo].[Stockline] Stk WITH (NOLOCK) 
			--		JOIN #TEMPBulkPORecords temp ON temp.ItemMasterId = Stk.ItemMasterId AND temp.ConditionCodeId = Stk.ConditionId	
			--		LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId
			--		ORDER BY Stk.[CreatedDate] DESC					
			--)tmpcash WHERE tmpcash.ItemMasterId = #TEMPBulkPORecords.ItemMasterId AND tmpcash.ConditionId = #TEMPBulkPORecords.ConditionCodeId
			
			--UPDATE #TEMPBulkPORecords SET [VendorName] = CASE WHEN ISNULL(tmpcash.IsFromBulkPO,0) = 0 THEN ISNULL(tmpcash.[VendorName],'')  ELSE ISNULL(tmpcash.POVendorName,'') END,  
			--                              [VendorCode] = CASE WHEN ISNULL(tmpcash.IsFromBulkPO,0) = 0 THEN ISNULL(tmpcash.[VendorCode],'')  ELSE ISNULL(tmpcash.POVendorCode,'') END  
			--FROM (SELECT TOP 1 Vend.VendorName,Vend.VendorCode, temp.VendorName AS POVendorName,temp.VendorCode AS POVendorCode ,temp.IsFromBulkPO,Stk.[ItemMasterId],Stk.[ConditionId]
			--	FROM DBO.Stockline Stk WITH (NOLOCK) 
			--	LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId				
			--	JOIN #TEMPBulkPORecords temp ON temp.ItemMasterId = Stk.ItemMasterId AND temp.ConditionCodeId = Stk.ConditionId	
			
			--)tmpcash WHERE tmpcash.ItemMasterId = #TEMPBulkPORecords.ItemMasterId AND tmpcash.ConditionId = #TEMPBulkPORecords.ConditionCodeId

			--6

			INSERT INTO #TEMPBulkPORecords([OrderNo],[ItemMasterId],[StatusId],[StatusName],[poRfqNo],[PurchaseOrderId],[PN],[PNDescription],[Condition],[ConditionCodeId],[Quantity],
				[UnitCost],[ExtendedCost],[LastPurchasePrice],[LastPONumber],[LastPODate],[VendorName],[VendorId],[VendorCode],[WONum],[MPN],
				[MPNDescription],[SerialNum],[Customer],[Manufacturer],[MinimumOrderQuantity],[IsFromBulkPO],[NeedBy],[EstReceivedDate],[VendorRFQPOPartRecordId],[CreatedDate])
			SELECT 
			  	2 AS OrderNo,
				WOM.ItemMasterId,
				COALESCE(NULLIF(PO.IsFromBulkPO, 0), @RFQPOOpenStatusId),
				COALESCE((SELECT [Status] FROM [dbo].[VendorRFQStatus] WITH (NOLOCK) WHERE [VendorRFQStatusId] = PO.[StatusId]),  @RFQPOOpenStatus),	
				ISNULL(PO.VendorRFQPurchaseOrderNumber,''),
				ISNULL(PO.VendorRFQPurchaseOrderId,0),				
				IM_ITM.partnumber,
				IM_ITM.PartDescription,
				Cond.[Description],
				WOM.ConditionCodeId,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END,
				((CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END) * (CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END)),
	            0,
				'',
				NULL,
				PO.VendorName,
				PO.VendorId,
				ISNULL((SELECT TOP 1 VendorCode FROM dbo.Vendor VN WITH (NOLOCK) WHERE VN.VendorId = PO.VendorId),''),	
				WO.WorkOrderNum,
				IM_WOP.partnumber,
				IM_WOP.PartDescription,
				'',
				WO.CustomerName,
				IM_ITM.ManufacturerName,
				IM_WOP.MinimumOrderQuantity,
				ISNULL(PO.IsFromBulkPO,0),
				CASE WHEN ISNULL(PO.VendorRFQPurchaseOrderId,0) > 0 THEN POP.NeedByDate ELSE NULL END,
				CASE WHEN ISNULL(PO.VendorRFQPurchaseOrderId,0) > 0 THEN  POP.PromisedDate ELSE NULL END
				,POP.VendorRFQPOPartRecordId
				,PO.CreatedDate
				FROM [dbo].[WorkOrderMaterialsKit] WOM WITH (NOLOCK)
					INNER JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH (NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId				
					INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOP.ID		
					LEFT JOIN  [dbo].[ItemMaster] IM_ITM WITH (NOLOCK) ON IM_ITM.ItemMasterId = WOM.ItemMasterId				
					INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId
					INNER JOIN [dbo].[ItemMaster] IM_WOP WITH (NOLOCK) ON IM_WOP.ItemMasterId = WOP.ItemMasterId
					INNER JOIN [dbo].[Condition] Cond WITH (NOLOCK) ON Cond.ConditionId = WOM.ConditionCodeId				
					INNER JOIN [dbo].[VendorRFQPurchaseOrderPart] POP WITH(NOLOCK) on WOM.ItemMasterId = POP.ItemMasterId AND WO.WorkOrderId = POP.WorkOrderId AND POP.ConditionId = COND.ConditionId
					INNER JOIN [dbo].[VendorRFQPurchaseOrder] PO WITH(NOLOCK) on POP.VendorRFQPurchaseOrderId = PO.VendorRFQPurchaseOrderId AND PO.IsFromBulkPO = 1						
			  WHERE  WOP.MasterCompanyId = @MasterCompanyId AND WOP.WorkOrderStageId = @StageId AND PO.IsFromBulkPO  = 1 

			UPDATE #TEMPBulkPORecords SET [LastPurchasePrice] = ISNULL(tmpcash.[PurchaseOrderUnitCost],0),
		                                 [LastPONumber] = ISNULL(tmpcash.[PurchaseOrderNumber],''),
										 [LastPODate] = [EntryDate],
										 [SerialNum] = [SerialNumber]
			FROM (SELECT TOP 1 Stk.[PurchaseOrderUnitCost],PO.[PurchaseOrderNumber],Stk.[EntryDate],Stk.[ItemMasterId],Stk.[ConditionId],Stk.[SerialNumber]
					FROM [dbo].[Stockline] Stk WITH (NOLOCK) 
					JOIN #TEMPBulkPORecords temp ON temp.ItemMasterId = Stk.ItemMasterId AND temp.ConditionCodeId = Stk.ConditionId	
					LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId
					ORDER BY Stk.[CreatedDate] DESC					
			)tmpcash WHERE tmpcash.ItemMasterId = #TEMPBulkPORecords.ItemMasterId AND tmpcash.ConditionId = #TEMPBulkPORecords.ConditionCodeId
			
			UPDATE #TEMPBulkPORecords SET [VendorName] = CASE WHEN ISNULL(tmpcash.IsFromBulkPO,0) = 0 THEN ISNULL(tmpcash.[VendorName],'')  ELSE ISNULL(tmpcash.POVendorName,'') END,  
			                              [VendorCode] = CASE WHEN ISNULL(tmpcash.IsFromBulkPO,0) = 0 THEN ISNULL(tmpcash.[VendorCode],'')  ELSE ISNULL(tmpcash.POVendorCode,'') END  
			FROM (SELECT TOP 1 Vend.VendorName,Vend.VendorCode, temp.VendorName AS POVendorName,temp.VendorCode AS POVendorCode ,temp.IsFromBulkPO,Stk.[ItemMasterId],Stk.[ConditionId]
				FROM DBO.Stockline Stk WITH (NOLOCK) 
				LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId				
				JOIN #TEMPBulkPORecords temp ON temp.ItemMasterId = Stk.ItemMasterId AND temp.ConditionCodeId = Stk.ConditionId				
			)tmpcash WHERE tmpcash.ItemMasterId = #TEMPBulkPORecords.ItemMasterId AND tmpcash.ConditionId = #TEMPBulkPORecords.ConditionCodeId
											

			SELECT *  INTO #TempResult111 FROM #TEMPBulkPORecords		
			--SELECT *  INTO #TempResult111 FROM Result		
			 WHERE Quantity > 0 
					 AND
					 ((@GlobalFilter <>'' AND ((PN LIKE '%' + @GlobalFilter + '%') OR                                            -- StatusName
							(StatusName LIKE '%' + @GlobalFilter + '%') OR
							(poRfqNo LIKE '%' + @GlobalFilter + '%') OR
							(PNDescription LIKE '%' + @GlobalFilter + '%') OR
							(Manufacturer LIKE '%' + @GlobalFilter + '%') OR
							(Condition LIKE '%' + @GlobalFilter + '%') OR
							(VendorName LIKE '%' + @GlobalFilter + '%') OR
							(NeedBy LIKE '%' + @GlobalFilter + '%') OR
							(EstReceivedDate LIKE '%' + @GlobalFilter + '%') OR
							(CAST(Quantity AS NVARCHAR(10)) LIKE '%' + @GlobalFilter + '%') OR
							(UnitCost LIKE '%' + @GlobalFilter + '%') OR
							(Extendedcost LIKE '%' + @GlobalFilter + '%') OR
							(LastPurchasePrice LIKE '%' + @GlobalFilter + '%') OR
							(LastPONumber LIKE '%' + @GlobalFilter + '%') OR
							(LastPODate LIKE '%' + @GlobalFilter + '%') OR
							(WONum LIKE '%' + @GlobalFilter + '%') OR
							(MPN LIKE '%' + @GlobalFilter + '%') OR
							(MPNDescription LIKE '%' + @GlobalFilter + '%') OR
							(SerialNum LIKE '%' + @GlobalFilter + '%') OR
							(Customer LIKE '%' + @GlobalFilter + '%')))
							OR
							(@GlobalFilter = '' AND (ISNULL(@PN, '') = '' OR PN LIKE '%' + @PN + '%') AND
							(ISNULL(@statusName, '') = '' OR StatusName LIKE '%' + @statusName + '%') AND
							(ISNULL(@PoRfqNo, '') = '' OR poRfqNo LIKE '%' + @PoRfqNo + '%') AND
							(ISNULL(@PNDescription, '') = '' OR PNDescription LIKE '%' + @PNDescription + '%') AND
							(ISNULL(@Manufacturer, '') = '' OR Manufacturer LIKE '%' + @Manufacturer + '%') AND
							(ISNULL(@Condition, '') = '' OR Condition LIKE '%' + @Condition + '%') AND
							(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND
							(ISNULL(@NeedBy,'') ='' OR CAST(NeedBy AS Date) = CAST(@NeedBy AS date)) AND
							(ISNULL(@EstReceivedDate,'') ='' OR CAST(EstReceivedDate AS Date) = CAST(@EstReceivedDate AS date)) AND
							(IsNull(@Quantity, 0) = 0 OR CAST(Quantity as VARCHAR(10)) LIKE @Quantity) AND
							(ISNULL(@UnitCost, 0) = 0 OR CAST(UnitCost as VARCHAR(10)) LIKE @UnitCost) AND
							(ISNULL(@Extendedcost, 0) = 0 OR CAST(Extendedcost as VARCHAR(10)) LIKE @Extendedcost) AND
							(ISNULL(@LastPurchasePrice, 0) = 0 OR CAST(LastPurchasePrice as VARCHAR(10)) = @LastPurchasePrice) AND
							(ISNULL(@LastPONumber, '') = '' OR LastPONumber  LIKE '%'+ @LastPONumber + '%') AND
							(ISNULL(@LastPODate,'') ='' OR CAST(LastPODate AS Date) = CAST(@LastPODate AS date)) AND
							(IsNull(@WONum, '') = '' OR WONum LIKE '%'+ @WONum + '%') AND
							(IsNull(@MPN, '') = '' OR MPN LIKE '%' + @MPN + '%') AND
							(IsNull(@MPNDescription, '') = '' OR MPNDescription LIKE '%' + @MPNDescription + '%') AND
							(IsNull(@SerialNum, '') = '' OR SerialNum LIKE '%' + @SerialNum + '%') AND
							(IsNull(@Customer, '') = '' OR Customer LIKE '%' + @Customer + '%'))
						  )

					SELECT @Count = COUNT(porfqNo) FROM #TempResult111			

					SELECT *, @Count AS NumberOfItems FROM #TempResult111
					ORDER BY  
								CASE WHEN (@SortOrder=1  AND @SortColumn='OrderNo')  THEN OrderNo END ASC,								
								CASE WHEN (@SortOrder=-1  AND @SortColumn='OrderNo')  THEN OrderNo END DESC,
								CASE WHEN (@SortOrder=1  AND @SortColumn='StatusName')  THEN StatusName END ASC,
								CASE WHEN (@SortOrder=-1 AND @SortColumn='StatusName')  THEN StatusName END DESC,
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
								CASE WHEN (@SortOrder=1 AND @SortColumn='VendorName')  THEN VendorName END ASC,
								CASE WHEN (@SortOrder=-1 AND @SortColumn='VendorName')  THEN VendorName END DESC,
								CASE WHEN (@SortOrder=1 AND @SortColumn='NeedBy')  THEN NeedBy END ASC,
								CASE WHEN (@SortOrder=-1 AND @SortColumn='NeedBy')  THEN NeedBy END DESC,
								CASE WHEN (@SortOrder=1 AND @SortColumn='EstReceivedDate')  THEN EstReceivedDate END ASC,
								CASE WHEN (@SortOrder=-1 AND @SortColumn='EstReceivedDate')  THEN EstReceivedDate END DESC,
								CASE WHEN (@SortOrder=1 AND @SortColumn='WONum')  THEN WONum END ASC,
								CASE WHEN (@SortOrder=-1 AND @SortColumn='WONum')  THEN WONum END DESC,
								CASE WHEN (@SortOrder=1 AND @SortColumn='MPN')  THEN MPN END ASC,
								CASE WHEN (@SortOrder=-1 AND @SortColumn='MPN')  THEN MPN END DESC,
								CASE WHEN (@SortOrder=1 AND @SortColumn='MPNDescription')  THEN MPNDescription END ASC,
								CASE WHEN (@SortOrder=-1 AND @SortColumn='MPNDescription')  THEN MPNDescription END DESC,
								CASE WHEN (@SortOrder=1 AND @SortColumn='SerialNum')  THEN SerialNum END ASC,
								CASE WHEN (@SortOrder=-1 AND @SortColumn='SerialNum')  THEN SerialNum END DESC,
								CASE WHEN (@SortOrder=1 AND @SortColumn='Customer')  THEN Customer END ASC,
								CASE WHEN (@SortOrder=-1 AND @SortColumn='Customer')  THEN Customer END DESC,
								CASE WHEN (@SortOrder=1 AND @SortColumn='PORFQNO')  THEN poRfqNo END ASC,
								CASE WHEN (@SortOrder=-1 AND @SortColumn='PORFQNO')  THEN poRfqNo END DESC
								,CreatedDate  DESC
					OFFSET @RecordFrom ROWS 
					FETCH NEXT @PageSize ROWS ONLY

			
		END

		ELSE
		BEGIN					
			--1

			INSERT INTO #TEMPBulkPORecords([OrderNo],[ItemMasterId],[StatusId],[StatusName],[poRfqNo],[PurchaseOrderId],[PN],[PNDescription],[Condition],[ConditionCodeId],[Quantity],
				[UnitCost],[ExtendedCost],[LastPurchasePrice],[LastPONumber],[LastPODate],[VendorName],[VendorId],[VendorCode],[WONum],[MPN],
				[MPNDescription],[SerialNum],[Customer],[Manufacturer],[MinimumOrderQuantity],[IsFromBulkPO],[NeedBy],[EstReceivedDate],[VendorRFQPOPartRecordId],[CreatedDate])
		 
		   	 SELECT 
				2 AS OrderNo,
				WOM.ItemMasterId,
				COALESCE(NULLIF(PO.IsFromBulkPO, 0), @POOpenStatusId),				
				COALESCE((SELECT [Status] FROM [dbo].[PoStatus] WITH (NOLOCK) WHERE [POStatusId] = PO.[StatusId]),  @POOpenStatus),				
				ISNULL(PO.PurchaseOrderNumber,''),
				ISNULL(PO.PurchaseOrderId,0),			
				IM_ITM.partnumber,
				IM_ITM.PartDescription,				
				Cond.[Description],	
				WOM.ConditionCodeId,				
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END,
				((CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END) * (CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END)),													
				0,
				'',
				NULL,
				PO.VendorName,
				PO.VendorId,
				ISNULL((SELECT TOP 1 VendorCode FROM dbo.Vendor VN WITH (NOLOCK) WHERE VN.VendorId = PO.VendorId),''),							
				WO.WorkOrderNum,
				IM_WOP.partnumber,
				IM_WOP.PartDescription,
				'',
				WO.CustomerName,			
				IM_ITM.ManufacturerName,			
				IM_WOP.MinimumOrderQuantity,
				ISNULL(PO.IsFromBulkPO,0),
				CASE WHEN ISNULL(PO.PurchaseOrderId,0) > 0 THEN POP.NeedByDate ELSE NULL END,
				CASE WHEN ISNULL(PO.PurchaseOrderId,0) > 0 THEN  POP.EstDeliveryDate ELSE NULL END,
				0 VendorRFQPOPartRecordId,	
				PO.CreatedDate
			FROM [dbo].[WorkOrderMaterials] WOM WITH (NOLOCK)
				INNER JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH (NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId	
				INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOP.ID	
				INNER JOIN [dbo].[ItemMaster] IM_ITM WITH (NOLOCK) ON IM_ITM.ItemMasterId = WOM.ItemMasterId				
			    INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId
			    INNER JOIN [dbo].[ItemMaster] IM_WOP WITH (NOLOCK) ON IM_WOP.ItemMasterId = WOP.ItemMasterId
			    INNER JOIN [dbo].[Condition] Cond WITH (NOLOCK) ON Cond.ConditionId = WOM.ConditionCodeId				
			    INNER JOIN [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) ON WOM.ItemMasterId = POP.ItemMasterId AND WO.WorkOrderId = POP.WorkOrderId AND POP.ConditionId = COND.ConditionId
			    INNER JOIN [dbo].[PurchaseOrder] PO WITH(NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND PO.IsFromBulkPO = 1

		WHERE	WOP.MasterCompanyId = @MasterCompanyId AND WOP.WorkOrderStageId = @StageId AND PO.IsFromBulkPO  = 1 
		   AND CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN (SELECT TOP 1 [Status] FROM dbo.PoStatus WITH (NOLOCK)  WHERE POStatusId = PO.StatusId) ELSE @POOpenStatus END  = @filterAsStatus
		   			
			--2

			INSERT INTO #TEMPBulkPORecords([OrderNo],[ItemMasterId],[StatusId],[StatusName],[poRfqNo],[PurchaseOrderId],[PN],[PNDescription],[Condition],[ConditionCodeId],[Quantity],
				[UnitCost],[ExtendedCost],[LastPurchasePrice],[LastPONumber],[LastPODate],[VendorName],[VendorId],[VendorCode],[WONum],[MPN],
				[MPNDescription],[SerialNum],[Customer],[Manufacturer],[MinimumOrderQuantity],[IsFromBulkPO],[NeedBy],[EstReceivedDate],[VendorRFQPOPartRecordId],[CreatedDate])
			 SELECT 
			 	1 AS OrderNo,	
				WOM.ItemMasterId,
				COALESCE(NULLIF(PO.IsFromBulkPO, 0), @POOpenStatusId),
				COALESCE((SELECT [Status] FROM [dbo].[PoStatus] WITH (NOLOCK) WHERE [POStatusId] = PO.[StatusId]),  @POOpenStatus),
				'',
				0,			
				IM_ITM.partnumber,
				IM_ITM.PartDescription,
				Cond.[Description],
				WOM.ConditionCodeId,
				((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)),
				ISNULL(WOM.UnitCost,0),
				((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) * ISNULL(WOM.UnitCost,0),						
				0,
				'',
				NULL,
				PO.VendorName,
				PO.VendorId,
				ISNULL((SELECT TOP 1 VendorCode FROM dbo.Vendor VN WITH (NOLOCK) WHERE VN.VendorId = PO.VendorId),''),	
				WO.WorkOrderNum,
				IM_WOP.partnumber,
				IM_WOP.PartDescription,
				'',
				WO.CustomerName,
				IM_ITM.ManufacturerName,
				IM_WOP.MinimumOrderQuantity,
				0,
				NULL,
				NULL,
				0,
				DATEADD(day, 1, GETDATE()) 
				FROM [dbo].[WorkOrderMaterials] WOM WITH (NOLOCK)
					INNER JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH (NOLOCK) ON	WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId				
					INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOP.ID
					LEFT JOIN  [dbo].[ItemMaster] IM_ITM WITH (NOLOCK) ON IM_ITM.ItemMasterId = WOM.ItemMasterId				
					INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId
					INNER JOIN [dbo].[ItemMaster] IM_WOP WITH (NOLOCK) ON IM_WOP.ItemMasterId = WOP.ItemMasterId
					INNER JOIN [dbo].[Condition] Cond WITH (NOLOCK) ON Cond.ConditionId = WOM.ConditionCodeId				
					LEFT JOIN  [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) on WOM.ItemMasterId = POP.ItemMasterId AND WO.WorkOrderId = POP.WorkOrderId
					LEFT JOIN  [dbo].[PurchaseOrder] PO WITH(NOLOCK) on POP.PurchaseOrderId = PO.PurchaseOrderId AND PO.IsFromBulkPO = 1
					LEFT JOIN  [dbo].[VendorRFQPurchaseOrderPart] POPRFQ WITH(NOLOCK) on WOM.ItemMasterId = POPRFQ.ItemMasterId AND WO.WorkOrderId = POPRFQ.WorkOrderId
					LEFT JOIN  [dbo].[VendorRFQPurchaseOrder] PORFQ WITH(NOLOCK) on POPRFQ.VendorRFQPurchaseOrderId = PORFQ.VendorRFQPurchaseOrderId AND PORFQ.IsFromBulkPO = 1

				WHERE
					  WOP.MasterCompanyId = @MasterCompanyId AND WOP.WorkOrderStageId = @StageId
					  AND (CASE WHEN  ISNULL(PO.IsFromBulkPO,0) = 1 OR  ISNULL(PORFQ.IsFromBulkPO,0) = 1 THEN 1 ELSE ISNULL(PO.IsFromBulkPO,0)END) != 1 
					  AND (CASE WHEN  ISNULL(PORFQ.IsFromBulkPO,0) = 1 OR ISNULL(PO.IsFromBulkPO,0) = 1  THEN 1 ELSE ISNULL(PORFQ.IsFromBulkPO,0)END) != 1 
					  AND CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN (SELECT TOP 1 [Status] FROM dbo.PoStatus WITH (NOLOCK)  WHERE POStatusId = PO.StatusId) ELSE @POOpenStatus END  = @filterAsStatus
					  			
			--3

			INSERT INTO #TEMPBulkPORecords([OrderNo],[ItemMasterId],[StatusId],[StatusName],[poRfqNo],[PurchaseOrderId],[PN],[PNDescription],[Condition],[ConditionCodeId],[Quantity],
				[UnitCost],[ExtendedCost],[LastPurchasePrice],[LastPONumber],[LastPODate],[VendorName],[VendorId],[VendorCode],[WONum],[MPN],
				[MPNDescription],[SerialNum],[Customer],[Manufacturer],[MinimumOrderQuantity],[IsFromBulkPO],[NeedBy],[EstReceivedDate],[VendorRFQPOPartRecordId],[CreatedDate])
			  SELECT 
			  	2 AS OrderNo,
				WOM.ItemMasterId,
				COALESCE(NULLIF(PO.IsFromBulkPO, 0), @RFQPOOpenStatusId),
				COALESCE((SELECT [Status] FROM [dbo].[VendorRFQStatus] WITH (NOLOCK) WHERE [VendorRFQStatusId] = PO.[StatusId]),  @RFQPOOpenStatus),				
				ISNULL(PO.VendorRFQPurchaseOrderNumber,''),
				ISNULL(PO.VendorRFQPurchaseOrderId,0),				
				IM_ITM.partnumber,
				IM_ITM.PartDescription,
				Cond.[Description],
				WOM.ConditionCodeId,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END,
				((CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END) * (CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END)),
				0,
				'', 
				NULL,
				PO.VendorName,
				PO.VendorId,
				ISNULL((SELECT TOP 1 VendorCode FROM dbo.Vendor VN WITH (NOLOCK) WHERE VN.VendorId = PO.VendorId),''),					
				WO.WorkOrderNum,
				IM_WOP.partnumber,
				IM_WOP.PartDescription,
				'',
				WO.CustomerName,
				IM_ITM.ManufacturerName,
				IM_WOP.MinimumOrderQuantity,
				ISNULL(PO.IsFromBulkPO,0),
				CASE WHEN ISNULL(PO.VendorRFQPurchaseOrderId,0) > 0 THEN POP.NeedByDate ELSE NULL END,
				CASE WHEN ISNULL(PO.VendorRFQPurchaseOrderId,0) > 0 THEN  POP.PromisedDate ELSE NULL END
				,POP.VendorRFQPOPartRecordId 
				,PO.CreatedDate
				FROM [dbo].[WorkOrderMaterials] WOM  WITH (NOLOCK)
					INNER JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH (NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId	
					INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON  WOWF.WorkOrderPartNoId = WOP.ID			
					LEFT JOIN  [dbo].[ItemMaster] IM_ITM WITH (NOLOCK) ON IM_ITM.ItemMasterId = WOM.ItemMasterId				
					INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId
					INNER JOIN [dbo].[ItemMaster] IM_WOP WITH (NOLOCK) ON IM_WOP.ItemMasterId = WOP.ItemMasterId
					INNER JOIN [dbo].[Condition] Cond WITH (NOLOCK) ON Cond.ConditionId = WOM.ConditionCodeId				
					INNER JOIN [dbo].[VendorRFQPurchaseOrderPart] POP WITH(NOLOCK) on WOM.ItemMasterId = POP.ItemMasterId AND WO.WorkOrderId = POP.WorkOrderId AND POP.ConditionId = COND.ConditionId
					INNER JOIN [dbo].[VendorRFQPurchaseOrder] PO WITH(NOLOCK) on POP.VendorRFQPurchaseOrderId = PO.VendorRFQPurchaseOrderId AND PO.IsFromBulkPO = 1

			  WHERE WOP.MasterCompanyId = @MasterCompanyId AND WOP.WorkOrderStageId = @StageId AND PO.IsFromBulkPO  = 1 
			  AND CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN (SELECT TOP 1 [Status] FROM dbo.VendorRFQStatus  WITH (NOLOCK)  WHERE VendorRFQStatusId = PO.StatusId) ELSE (SELECT TOP 1 [Status] FROM dbo.VendorRFQStatus WITH (NOLOCK)  WHERE [Status] = 'Open') END  = @filterAsStatus
			  			  
			-- ************************************* KIT Bulk PO ***************************************	  			   			   			  					 		 			  	   	   	  	 
		
			--4

			INSERT INTO #TEMPBulkPORecords([OrderNo],[ItemMasterId],[StatusId],[StatusName],[poRfqNo],[PurchaseOrderId],[PN],[PNDescription],[Condition],[ConditionCodeId],[Quantity],
				[UnitCost],[ExtendedCost],[LastPurchasePrice],[LastPONumber],[LastPODate],[VendorName],[VendorId],[VendorCode],[WONum],[MPN],
				[MPNDescription],[SerialNum],[Customer],[Manufacturer],[MinimumOrderQuantity],[IsFromBulkPO],[NeedBy],[EstReceivedDate],[VendorRFQPOPartRecordId],[CreatedDate])
			 SELECT 
			   	2 AS OrderNo,
				WOM.ItemMasterId,
				COALESCE(NULLIF(PO.IsFromBulkPO, 0),  @POOpenStatusId),
				COALESCE((SELECT [Status] FROM [dbo].[PoStatus] WITH (NOLOCK) WHERE [POStatusId] = PO.[StatusId]),  @POOpenStatus),
				ISNULL(PO.PurchaseOrderNumber,''),
				ISNULL(PO.PurchaseOrderId,0),				
				IM_ITM.partnumber,
				IM_ITM.PartDescription,
				Cond.[Description],
				WOM.ConditionCodeId,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END,
				((CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END) * (CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END)),				
				0,
				'',
				NULL,
				PO.VendorName,
				PO.VendorId,
				ISNULL((SELECT TOP 1 VendorCode FROM dbo.Vendor VN WITH (NOLOCK) WHERE VN.VendorId = PO.VendorId),''),	
				WO.WorkOrderNum,
				IM_WOP.partnumber,
				IM_WOP.PartDescription,
				'',
				WO.CustomerName,
				IM_ITM.ManufacturerName,
				IM_WOP.MinimumOrderQuantity,
				ISNULL(PO.IsFromBulkPO,0),
				CASE WHEN ISNULL(PO.PurchaseOrderId,0) > 0 THEN POP.NeedByDate ELSE NULL END,
				CASE WHEN ISNULL(PO.PurchaseOrderId,0) > 0 THEN  POP.EstDeliveryDate ELSE NULL END,
				0 VendorRFQPOPartRecordId,
				PO.CreatedDate 
				FROM[dbo].[WorkOrderMaterialsKit] WOM  WITH (NOLOCK)
					INNER JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH (NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId		
					INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOP.ID		
					LEFT JOIN  [dbo].[ItemMaster] IM_ITM WITH (NOLOCK) ON IM_ITM.ItemMasterId = WOM.ItemMasterId				
					INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId
					INNER JOIN [dbo].[ItemMaster] IM_WOP WITH (NOLOCK) ON IM_WOP.ItemMasterId = WOP.ItemMasterId
					INNER JOIN [dbo].[Condition] Cond WITH (NOLOCK) ON Cond.ConditionId = WOM.ConditionCodeId				
					INNER JOIN [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) ON WOM.ItemMasterId = POP.ItemMasterId AND WO.WorkOrderId = POP.WorkOrderId AND POP.ConditionId = COND.ConditionId
					INNER JOIN [dbo].[PurchaseOrder] PO WITH(NOLOCK) ON POP.PurchaseOrderId = PO.PurchaseOrderId AND PO.IsFromBulkPO = 1
			  WHERE WOP.MasterCompanyId = @MasterCompanyId AND WOP.WorkOrderStageId = @StageId AND PO.IsFromBulkPO  = 1 
			        AND CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN (SELECT TOP 1 [Status] FROM dbo.PoStatus WITH (NOLOCK)  WHERE POStatusId = PO.StatusId) ELSE @POOpenStatus END  = @filterAsStatus
					 			
			--5
		
			INSERT INTO #TEMPBulkPORecords([OrderNo],[ItemMasterId],[StatusId],[StatusName],[poRfqNo],[PurchaseOrderId],[PN],[PNDescription],[Condition],[ConditionCodeId],[Quantity],
				[UnitCost],[ExtendedCost],[LastPurchasePrice],[LastPONumber],[LastPODate],[VendorName],[VendorId],[VendorCode],[WONum],[MPN],
				[MPNDescription],[SerialNum],[Customer],[Manufacturer],[MinimumOrderQuantity],[IsFromBulkPO],[NeedBy],[EstReceivedDate],[VendorRFQPOPartRecordId],[CreatedDate])			
			SELECT 
			 	1 AS OrderNo,		
				WOM.ItemMasterId,
				COALESCE(NULLIF(PO.IsFromBulkPO, 0), @POOpenStatusId),
				COALESCE((SELECT [Status] FROM [dbo].[PoStatus] WITH (NOLOCK) WHERE [POStatusId] = PO.[StatusId]),  @POOpenStatus),
				'',
				0 PurchaseOrderId,				
				IM_ITM.partnumber,
				IM_ITM.PartDescription,
				Cond.[Description],
				WOM.ConditionCodeId,
				((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)),
				ISNULL(WOM.UnitCost,0),
				((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) * ISNULL(WOM.UnitCost,0),
	            0,
				'',
				NULL,
				PO.VendorName,
				PO.VendorId,
				ISNULL((SELECT TOP 1 VendorCode FROM dbo.Vendor VN WITH (NOLOCK) WHERE VN.VendorId = PO.VendorId),''),	
				WO.WorkOrderNum,
				IM_WOP.partnumber,
				IM_WOP.PartDescription,
				'',
				WO.CustomerName,
				IM_ITM.ManufacturerName,
				IM_WOP.MinimumOrderQuantity,
				0 IsFromBulkPO,
				NULL,
				NULL,
				0 VendorRFQPOPartRecordId,
				DATEADD(DAY, 1, GETDATE())
				FROM [dbo].[WorkOrderMaterialsKit] WOM WITH (NOLOCK)
					INNER JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH (NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId		
					INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON  WOWF.WorkOrderPartNoId = WOP.ID	
					LEFT JOIN  [dbo].[ItemMaster] IM_ITM WITH (NOLOCK) ON IM_ITM.ItemMasterId = WOM.ItemMasterId				
					INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOM.WorkOrderId = WO.WorkOrderId
					INNER JOIN [dbo].[ItemMaster] IM_WOP WITH (NOLOCK) ON IM_WOP.ItemMasterId = WOP.ItemMasterId
					INNER JOIN [dbo].[Condition] Cond WITH (NOLOCK) ON Cond.ConditionId = WOM.ConditionCodeId				
					LEFT JOIN  [dbo].[PurchaseOrderPart] POP WITH(NOLOCK) on WOM.ItemMasterId = POP.ItemMasterId AND WO.WorkOrderId = POP.WorkOrderId
					LEFT JOIN  [dbo].[PurchaseOrder] PO WITH(NOLOCK) on POP.PurchaseOrderId = PO.PurchaseOrderId AND PO.IsFromBulkPO = 1
					LEFT JOIN  [dbo].[VendorRFQPurchaseOrderPart] POPRFQ WITH(NOLOCK) on WOM.ItemMasterId = POPRFQ.ItemMasterId AND WO.WorkOrderId = POPRFQ.WorkOrderId
					LEFT JOIN  [dbo].[VendorRFQPurchaseOrder] PORFQ WITH(NOLOCK) on POPRFQ.VendorRFQPurchaseOrderId = PORFQ.VendorRFQPurchaseOrderId AND PORFQ.IsFromBulkPO = 1
			  WHERE WOP.MasterCompanyId = @MasterCompanyId AND WOP.WorkOrderStageId = @StageId
			  AND (CASE WHEN  ISNULL(PO.IsFromBulkPO,0) = 1 OR  ISNULL(PORFQ.IsFromBulkPO,0) = 1 THEN 1 ELSE ISNULL(PO.IsFromBulkPO,0)END) != 1 
			  AND (CASE WHEN  ISNULL(PORFQ.IsFromBulkPO,0) = 1 OR ISNULL(PO.IsFromBulkPO,0) = 1  THEN 1 ELSE ISNULL(PORFQ.IsFromBulkPO,0)END) != 1 
			  AND CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN (SELECT TOP 1 [Status] FROM dbo.PoStatus WITH (NOLOCK)  WHERE POStatusId = PO.StatusId) ELSE @POOpenStatus END  = @filterAsStatus
			  			
			--6

			INSERT INTO #TEMPBulkPORecords([OrderNo],[ItemMasterId],[StatusId],[StatusName],[poRfqNo],[PurchaseOrderId],[PN],[PNDescription],[Condition],[ConditionCodeId],[Quantity],
				[UnitCost],[ExtendedCost],[LastPurchasePrice],[LastPONumber],[LastPODate],[VendorName],[VendorId],[VendorCode],[WONum],[MPN],
				[MPNDescription],[SerialNum],[Customer],[Manufacturer],[MinimumOrderQuantity],[IsFromBulkPO],[NeedBy],[EstReceivedDate],[VendorRFQPOPartRecordId],[CreatedDate])
			SELECT 
			  	2 AS OrderNo,
				WOM.ItemMasterId,
				COALESCE(NULLIF(PO.IsFromBulkPO, 0), @RFQPOOpenStatusId),
				COALESCE((SELECT [Status] FROM [dbo].[VendorRFQStatus] WITH (NOLOCK) WHERE [VendorRFQStatusId] = PO.[StatusId]),  @RFQPOOpenStatus),	
				ISNULL(PO.VendorRFQPurchaseOrderNumber,''),
				ISNULL(PO.VendorRFQPurchaseOrderId,0),				
				IM_ITM.partnumber,
				IM_ITM.PartDescription,
				Cond.[Description],
				WOM.ConditionCodeId,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END,
				CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END,
				((CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN ((ISNULL(WOM.Quantity, 0) - (ISNULL(WOM.TotalReserved, 0) + ISNULL(WOM.TotalIssued, 0))) - (SELECT ISNULL(SUM(QuantityAvailable), 0) FROM [DBO].Stockline Stk WITH (NOLOCK) WHERE Stk.ItemMasterId = WOM.ItemMasterId AND Stk.ConditionId = WOM.ConditionCodeId AND Stk.IsParent = 1 AND Stk.IsCustomerStock = 0)) ELSE ISNULL(POP.QuantityOrdered,0) END) * (CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 0 THEN  ISNULL(WOM.UnitCost,0) ELSE ISNULL(POP.UnitCost,0) END)),
	            0,
				'',
				NULL,
				PO.VendorName,
				PO.VendorId,
				ISNULL((SELECT TOP 1 VendorCode FROM dbo.Vendor VN WITH (NOLOCK) WHERE VN.VendorId = PO.VendorId),''),	
				WO.WorkOrderNum,
				IM_WOP.partnumber,
				IM_WOP.PartDescription,
				'',
				WO.CustomerName,
				IM_ITM.ManufacturerName,
				IM_WOP.MinimumOrderQuantity,
				ISNULL(PO.IsFromBulkPO,0),
				CASE WHEN ISNULL(PO.VendorRFQPurchaseOrderId,0) > 0 THEN POP.NeedByDate ELSE NULL END,
				CASE WHEN ISNULL(PO.VendorRFQPurchaseOrderId,0) > 0 THEN  POP.PromisedDate ELSE NULL END
				,POP.VendorRFQPOPartRecordId
				,PO.CreatedDate
				FROM [dbo].[WorkOrderMaterialsKit] WOM WITH (NOLOCK)
					INNER JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH (NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId				
					INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOP.ID		
					LEFT JOIN  [dbo].[ItemMaster] IM_ITM WITH (NOLOCK) ON IM_ITM.ItemMasterId = WOM.ItemMasterId				
					INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WOP.WorkOrderId = WO.WorkOrderId
					INNER JOIN [dbo].[ItemMaster] IM_WOP WITH (NOLOCK) ON IM_WOP.ItemMasterId = WOP.ItemMasterId
					INNER JOIN [dbo].[Condition] Cond WITH (NOLOCK) ON Cond.ConditionId = WOM.ConditionCodeId				
					INNER JOIN [dbo].[VendorRFQPurchaseOrderPart] POP WITH(NOLOCK) on WOM.ItemMasterId = POP.ItemMasterId AND WO.WorkOrderId = POP.WorkOrderId AND POP.ConditionId = COND.ConditionId
					INNER JOIN [dbo].[VendorRFQPurchaseOrder] PO WITH(NOLOCK) on POP.VendorRFQPurchaseOrderId = PO.VendorRFQPurchaseOrderId AND PO.IsFromBulkPO = 1									 
			  WHERE  WOP.MasterCompanyId = @MasterCompanyId AND WOP.WorkOrderStageId = @StageId AND PO.IsFromBulkPO  = 1 
			  AND CASE WHEN ISNULL(PO.IsFromBulkPO,0) = 1 THEN (SELECT TOP 1 [Status] FROM dbo.VendorRFQStatus  WITH (NOLOCK)  WHERE VendorRFQStatusId = PO.StatusId) ELSE (SELECT TOP 1 [Status] FROM dbo.VendorRFQStatus WITH (NOLOCK)  WHERE [Status] = 'Open') END  = @filterAsStatus


			UPDATE #TEMPBulkPORecords SET [LastPurchasePrice] = ISNULL(tmpcash.[PurchaseOrderUnitCost],0),
		                                 [LastPONumber] = ISNULL(tmpcash.[PurchaseOrderNumber],''),
										 [LastPODate] = [EntryDate],
										 [SerialNum] = [SerialNumber]
			FROM (SELECT TOP 1 Stk.[PurchaseOrderUnitCost],PO.[PurchaseOrderNumber],Stk.[EntryDate],Stk.[ItemMasterId],Stk.[ConditionId],Stk.[SerialNumber]
					FROM [dbo].[Stockline] Stk WITH (NOLOCK) 
					JOIN #TEMPBulkPORecords temp ON temp.ItemMasterId = Stk.ItemMasterId AND temp.ConditionCodeId = Stk.ConditionId	
					LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON Stk.PurchaseOrderId = PO.PurchaseOrderId
					ORDER BY Stk.[CreatedDate] DESC					
			)tmpcash WHERE tmpcash.ItemMasterId = #TEMPBulkPORecords.ItemMasterId AND tmpcash.ConditionId = #TEMPBulkPORecords.ConditionCodeId
			
			UPDATE #TEMPBulkPORecords SET [VendorName] = CASE WHEN ISNULL(tmpcash.IsFromBulkPO,0) = 0 THEN ISNULL(tmpcash.[VendorName],'')  ELSE ISNULL(tmpcash.POVendorName,'') END,  
			                              [VendorCode] = CASE WHEN ISNULL(tmpcash.IsFromBulkPO,0) = 0 THEN ISNULL(tmpcash.[VendorCode],'')  ELSE ISNULL(tmpcash.POVendorCode,'') END  
			FROM (SELECT TOP 1 Vend.VendorName,Vend.VendorCode, temp.VendorName AS POVendorName,temp.VendorCode AS POVendorCode ,temp.IsFromBulkPO,Stk.[ItemMasterId],Stk.[ConditionId]
				FROM DBO.Stockline Stk WITH (NOLOCK) 
				LEFT JOIN [dbo].[Vendor] Vend WITH (NOLOCK) ON Stk.VendorId = Vend.VendorId				
				JOIN #TEMPBulkPORecords temp ON temp.ItemMasterId = Stk.ItemMasterId AND temp.ConditionCodeId = Stk.ConditionId				
			)tmpcash WHERE tmpcash.ItemMasterId = #TEMPBulkPORecords.ItemMasterId AND tmpcash.ConditionId = #TEMPBulkPORecords.ConditionCodeId
											

			SELECT *  INTO #TempResult222 FROM #TEMPBulkPORecords		
			 WHERE Quantity > 0 
					 AND
					 ((@GlobalFilter <>'' AND ((PN LIKE '%' + @GlobalFilter + '%') OR                                            -- StatusName
							(StatusName LIKE '%' + @GlobalFilter + '%') OR
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
							(LastPurchasePrice LIKE '%' + @GlobalFilter + '%') OR
							(LastPONumber LIKE '%' + @GlobalFilter + '%') OR
							(LastPODate LIKE '%' + @GlobalFilter + '%') OR
							(WONum LIKE '%' + @GlobalFilter + '%') OR
							(MPN LIKE '%' + @GlobalFilter + '%') OR
							(MPNDescription LIKE '%' + @GlobalFilter + '%') OR
							(SerialNum LIKE '%' + @GlobalFilter + '%') OR
							(Customer LIKE '%' + @GlobalFilter + '%')))
							OR
							(@GlobalFilter = '' AND (ISNULL(@PN, '') = '' OR PN LIKE '%' + @PN + '%') AND
							(ISNULL(@statusName, '') = '' OR StatusName LIKE '%' + @statusName + '%') AND
							(ISNULL(@PoRfqNo, '') = '' OR poRfqNo LIKE '%' + @PoRfqNo + '%') AND
							(ISNULL(@PNDescription, '') = '' OR PNDescription LIKE '%' + @PNDescription + '%') AND
							(ISNULL(@Manufacturer, '') = '' OR Manufacturer LIKE '%' + @Manufacturer + '%') AND
							(ISNULL(@Condition, '') = '' OR Condition LIKE '%' + @Condition + '%') AND
							(ISNULL(@VendorName,'') ='' OR VendorName LIKE '%' + @VendorName + '%') AND
							(ISNULL(@NeedBy,'') ='' OR CAST(NeedBy AS Date) = CAST(@NeedBy AS date)) AND
							(ISNULL(@EstReceivedDate,'') ='' OR CAST(EstReceivedDate AS Date) = CAST(@EstReceivedDate AS date)) AND
							(ISNULL(@Quantity, 0) = 0 OR CAST(Quantity as VARCHAR(10)) LIKE @Quantity) AND
							(ISNULL(@UnitCost, 0) = 0 OR CAST(UnitCost as VARCHAR(10)) LIKE @UnitCost) AND
							(ISNULL(@Extendedcost, 0) = 0 OR CAST(Extendedcost as VARCHAR(10)) LIKE @Extendedcost) AND
							(ISNULL(@LastPurchasePrice, 0) = 0 OR CAST(LastPurchasePrice as VARCHAR(10)) = @LastPurchasePrice) AND
							(ISNULL(@LastPONumber, '') = '' OR LastPONumber  LIKE '%'+ @LastPONumber + '%') AND
							(ISNULL(@LastPODate,'') ='' OR CAST(LastPODate AS Date) = CAST(@LastPODate AS date)) AND
							(ISNULL(@WONum, '') = '' OR WONum LIKE '%'+ @WONum + '%') AND
							(ISNULL(@MPN, '') = '' OR MPN LIKE '%' + @MPN + '%') AND
							(ISNULL(@MPNDescription, '') = '' OR MPNDescription LIKE '%' + @MPNDescription + '%') AND
							(ISNULL(@SerialNum, '') = '' OR SerialNum LIKE '%' + @SerialNum + '%') AND
							(ISNULL(@Customer, '') = '' OR Customer LIKE '%' + @Customer + '%'))
						  )

					SELECT @Count = COUNT(porfqNo) FROM #TempResult222			

					SELECT *, @Count AS NumberOfItems FROM #TempResult222
					ORDER BY  
								CASE WHEN (@SortOrder=1  AND @SortColumn='OrderNo')  THEN OrderNo END ASC,								
								CASE WHEN (@SortOrder=-1  AND @SortColumn='OrderNo')  THEN OrderNo END DESC,
								CASE WHEN (@SortOrder=1  AND @SortColumn='StatusName')  THEN StatusName END ASC,
								CASE WHEN (@SortOrder=-1 AND @SortColumn='StatusName')  THEN StatusName END DESC,
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
		
	END TRY    
	BEGIN CATCH      
		--IF @@trancount > 0
			PRINT 'ROLLBACK'
			--ROLLBACK TRAN;
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