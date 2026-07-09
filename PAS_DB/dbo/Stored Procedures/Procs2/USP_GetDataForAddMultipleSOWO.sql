/*************************************************************                   
 ** File:   [USP_GetDataForAddMultipleSOWO]                   
 ** Author:   Shrey Chandegara      
 ** Description:       
 ** Purpose:                 
 ** Date:   13-10-2023               
                  
 ** RETURN VALUE:                   
          
 **************************************************************                   
  ** Change History                   
 **************************************************************                   
 ** PR   Date         Author				Change Description                    
 ** --   --------     -------			--------------------------------                  
    1    13-10-2023   Shrey Chandegara		Created
	2    24-11-2023   Shrey Chandegara		update for requested qty.
	3    12/06/2023   Vishal Suthar			Modified to see work order from material KIT
	4    13/12/2023   Devendra Shekh		added kit details for subwo
	5    13/08/2023   Vishal Suthar			Modified to allow Alt and Equ parts to map
    6    11/05/2024	  Vishal Suthar			Modified to make use of new SO Part tables  
	7	 12/05/2024	  Ayushi Patel			Added missing brackets in where clouse 
	8	 12/17/2024	  Ayushi Patel			Added cancel so condition in where clouse
	9    12/30/2025   Sahdev Saliya         Implemented filtering in all spaces using the search text.
	10    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	11    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0

 EXECUTE USP_GetDataForAddMultipleSOWO 'loadwo',102539,7,2688,14760     
**************************************************************/         
CREATE    PROCEDURE [dbo].[USP_GetDataForAddMultipleSOWO]      
	@viewType VARCHAR (50) = NULL,      
	@ItemMasterId BIGINT,      
	@ConditionId BIGINT,      
	@PurchaseOrderId BIGINT,      
	@PurchaseOrderPartRecordId BIGINT,
	@SearchText VARCHAR (50) = NULL
AS
BEGIN
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @CloseSOStatusId int;
		DECLARE @CancelSOStatusId int;
        IF(@viewType = 'woview')      
        BEGIN      
			SELECT DISTINCT      
				IM.partnumber AS 'PartNumber',      
				C.Code AS 'Condition',      
				WO.WorkOrderNum AS 'ReferenceNum',      
				WO.WorkOrderId AS 'ReferenceId',      
				CASE WHEN  ( (((ISNULL(SUM(WOM.Quantity),0))  -  ((ISNULL(SUM(WOM.TotalReserved),0))  +  (ISNULL(SUM(WOM.TotalIssued),0))))  +   (ISNULL(SUM(WOMK.Quantity),0))) - (SELECT ISNULL(SUM(Sl.QuantityAvailable), 0) FROM dbo.Stockline Sl where Sl.ItemMasterId = @ItemMasterId and Sl.ConditionId = @ConditionId AND IsParent = 1 AND ISNULL(Sl.IsNonStock,0) = 0) )  > 0 THEN  (    (((ISNULL(SUM(WOM.Quantity),0))  -  ((ISNULL(SUM(WOM.TotalReserved),0))  +  (ISNULL(SUM(WOM.TotalIssued),0))))  +  (ISNULL(SUM(WOMK.Quantity),0))) - (SELECT ISNULL(SUM(Sl.QuantityAvailable), 0) FROM dbo.Stockline Sl where Sl.ItemMasterId = @ItemMasterId and Sl.ConditionId = @ConditionId AND IsParent = 1 AND ISNULL(Sl.IsNonStock,0) = 0) ) ELSE 0 END as RequestedQty,      
				WOP.PromisedDate AS 'PromisedDate',      
				WOP.EstimatedCompletionDate AS 'EstimatedCompletionDate',      
				WOP.EstimatedShipDate AS 'EstimatedShipDate',      
				@viewType AS 'ViewType'      
			FROM [WorkOrderMaterials] WOM WITH (NOLOCK)       
			LEFT JOIN [DBO].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId = WOM.WorkOrderId      
			LEFT JOIN [DBO].[WorkOrderMaterialsKit] WOMK WITH (NOLOCK) ON WOMK.ItemMasterId = @ItemMasterId AND WOMK.ConditionCodeId = @ConditionId AND WOMK.WorkOrderId = WOM.WorkOrderId  AND WOMK.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId       
			LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] Nha WITH (NOLOCK) ON Nha.ItemMasterId = @ItemMasterId AND (Nha.MappingType = 1 OR Nha.MappingType = 2)
			LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] MainNha WITH (NOLOCK) ON MainNha.MappingItemMasterId = @ItemMasterId AND (MainNha.MappingType = 1 OR MainNha.MappingType = 2)
			LEFT JOIN [DBO].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON WOP.WorkOrderId = WOM.WorkOrderId      
			LEFT JOIN [DBO].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = @ItemMasterId      
			 AND ISNULL(IM.IsNonStock,0) = 0
			 LEFT JOIN [DBO].[Condition] C WITH (NOLOCK) ON C.ConditionId = @ConditionId      
			WHERE (WOM.ItemMasterId = @ItemMasterId AND WOM.ConditionCodeId = @ConditionId)
			OR ((WOM.ItemMasterId = Nha.MappingItemMasterId OR WOM.ItemMasterId = MainNha.ItemMasterId) AND WOM.ConditionCodeId = @ConditionId) AND (@SearchText is null or WO.WorkOrderNum LIKE '%'+@SearchText+'%')
			GROUP BY WO.WorkOrderNum, WOP.PromisedDate, WOP.EstimatedCompletionDate, WOP.EstimatedShipDate, IM.partnumber, C.code, WO.WorkOrderId
			ORDER BY WO.WorkOrderId DESC      
        END      
		ELSE IF(@viewType = 'soview')      
        BEGIN      
		SET @CloseSOStatusId = (SELECT TOP 1 ID FROM DBO.MasterSalesOrderStatus where Name ='Closed' AND IsActive = 1 AND IsDeleted = 0)
		SET @CancelSOStatusId = (SELECT TOP 1 ID FROM DBO.MasterSalesOrderStatus where Name ='Cancelled' AND IsActive = 1 AND IsDeleted = 0)
			SELECT DISTINCT      
				IM.partnumber AS 'PartNumber',      
				C.Code AS 'Condition',      
				SO.SalesOrderNumber AS 'ReferenceNum',      
				SO.SalesOrderId As 'ReferenceId',      
				ISNULL((ISNULL(SOP.QtyRequested ,0)- ISNULL(SUM(SOR.QtyToReserve),0)),0) as RequestedQty, -- ISNULL(SOP.qty ,0)  - ISNULL(SOP.QtyRequested ,0)) as RequestedQty,      
				SOP.PromisedDate AS 'PromisedDate',      
				SOP.CustomerRequestDate AS 'EstimatedCompletionDate',      
				SOP.EstimatedShipDate 'EstimatedShipDate',      
				@viewType AS 'ViewType'      
			FROM [SalesOrderPartV1] SOP WITH(NOLOCK)      
			LEFT JOIN [DBO].[SalesOrderReserveParts] SOR WITH (NOLOCK) ON SOR.SalesOrderPartId = SOP.SalesOrderPartId
			LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] Nha WITH (NOLOCK) ON Nha.ItemMasterId = @ItemMasterId AND (Nha.MappingType = 1 OR Nha.MappingType = 2)
			LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] MainNha WITH (NOLOCK) ON MainNha.MappingItemMasterId = @ItemMasterId AND (MainNha.MappingType = 1 OR MainNha.MappingType = 2)
			LEFT JOIN [DBO].[SalesOrder] SO WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId      
			LEFT JOIN [DBO].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = @ItemMasterId      
			 AND ISNULL(IM.IsNonStock,0) = 0
			 LEFT JOIN [DBO].[Condition] C WITH (NOLOCK) ON C.ConditionId = @ConditionId      
			WHERE (SOP.ItemMasterId = @ItemMasterId AND SOP.ConditionId = @ConditionId 
			OR ((SOP.ItemMasterId = Nha.MappingItemMasterId OR SOP.ItemMasterId = MainNha.ItemMasterId) AND SOP.ConditionId = @ConditionId))
			AND SO.StatusId != @CloseSOStatusId AND SO.StatusId != @CancelSOStatusId AND (@SearchText is null or SO.SalesOrderNumber LIKE '%'+@SearchText+'%')
			GROUP BY SOP.QtyRequested,SOR.QtyToReserve,SO.SalesOrderNumber,SO.SalesOrderId,  SOP.PromisedDate,SOP.CustomerRequestDate,SOP.EstimatedShipDate,IM.partnumber,C.Code      
			ORDER BY SO.SalesOrderId DESC      
		END      
		ELSE IF(@viewType = 'loadwo')      
		BEGIN      
			SELECT DISTINCT      
				IM.partnumber AS 'PartNumber',      
				C.Code AS 'Condition',      
				WO.WorkOrderNum AS 'ReferenceNum',      
				WO.WorkOrderId AS 'ReferenceId',      
				CASE WHEN  ( (((ISNULL(SUM(WOM.Quantity),0))  -  ((ISNULL(SUM(WOM.TotalReserved),0))  +  (ISNULL(SUM(WOM.TotalIssued),0))))  +   (ISNULL(SUM(WOMK.Quantity),0))) - (SELECT ISNULL(SUM(Sl.QuantityAvailable), 0) FROM dbo.Stockline Sl where Sl.ItemMasterId = @ItemMasterId and Sl.ConditionId = @ConditionId AND IsParent = 1 AND IsCustomerStock = 0 AND ISNULL(Sl.IsNonStock,0) = 0) )  > 0 THEN  (    (((ISNULL(SUM(WOM.Quantity),0))  -  ((ISNULL(SUM(WOM.TotalReserved),0))  +  (ISNULL(SUM(WOM.TotalIssued),0))))  +  (ISNULL(SUM(WOMK.Quantity),0))) - (SELECT ISNULL(SUM(Sl.QuantityAvailable), 0) FROM dbo.Stockline Sl where Sl.ItemMasterId = @ItemMasterId and Sl.ConditionId = @ConditionId AND IsParent = 1 AND IsCustomerStock = 0 AND ISNULL(Sl.IsNonStock,0) = 0) ) ELSE 0 END as RequestedQty,      
				WOP.PromisedDate AS 'PromisedDate',      
				WOP.EstimatedCompletionDate AS 'EstimatedCompletionDate',      
				WOP.EstimatedShipDate AS 'EstimatedShipDate',      
				@viewType AS 'ViewType'      
			FROM [DBO].[WorkOrder] WO WITH (NOLOCK)       
			LEFT JOIN [WorkOrderMaterials] WOM WITH (NOLOCK) ON WO.WorkOrderId = WOM.WorkOrderId      
			LEFT JOIN [DBO].[WorkOrderMaterialsKit] WOMK WITH (NOLOCK) ON WOMK.WorkOrderId = WO.WorkOrderId --AND WOMK.WorkFlowWorkOrderId = WOM.WorkFlowWorkOrderId        
			LEFT JOIN [DBO].[WorkOrderPartNumber] WOP WITH (NOLOCK) ON WOP.WorkOrderId = WOM.WorkOrderId      
			LEFT JOIN [DBO].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = @ItemMasterId      
			 AND ISNULL(IM.IsNonStock,0) = 0
			 LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] Nha WITH (NOLOCK) ON Nha.ItemMasterId = @ItemMasterId AND (Nha.MappingType = 1 OR Nha.MappingType = 2)
			LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] MainNha WITH (NOLOCK) ON MainNha.MappingItemMasterId = @ItemMasterId AND (MainNha.MappingType = 1 OR MainNha.MappingType = 2)
			LEFT JOIN [DBO].[Condition] C WITH (NOLOCK) ON C.ConditionId = @ConditionId      
			WHERE ((WOM.ItemMasterId = @ItemMasterId AND WOM.ConditionCodeId = @ConditionId) OR 
			((WOM.ItemMasterId = Nha.MappingItemMasterId OR WOM.ItemMasterId = MainNha.ItemMasterId) AND WOM.ConditionCodeId = @ConditionId) OR 
			((WOMK.ItemMasterId = Nha.MappingItemMasterId OR WOMK.ItemMasterId = MainNha.ItemMasterId) AND WOMK.ConditionCodeId = @ConditionId) OR
			(WOMK.ItemMasterId = @ItemMasterId AND WOMK.ConditionCodeId = @ConditionId)) AND (@SearchText is null or WO.WorkOrderNum LIKE '%'+@SearchText+'%')
			GROUP BY WO.WorkOrderNum,      
					WOP.PromisedDate,      
					WOP.EstimatedCompletionDate,      
					WOP.EstimatedShipDate,IM.partnumber,C.code,WO.WorkOrderId      
		   ORDER BY WO.WorkOrderId DESC;
		END      
		ELSE IF(@viewType = 'loadso')      
		BEGIN
		SET @CloseSOStatusId = (SELECT TOP 1 ID FROM DBO.MasterSalesOrderStatus where Name ='Closed' AND IsActive = 1 AND IsDeleted = 0)
		SET @CancelSOStatusId = (SELECT TOP 1 ID FROM DBO.MasterSalesOrderStatus where Name ='Cancelled' AND IsActive = 1 AND IsDeleted = 0)
			SELECT DISTINCT      
                IM.partnumber AS 'PartNumber',      
				C.Code AS 'Condition',      
                SO.SalesOrderNumber AS 'ReferenceNum',      
				SO.SalesOrderId As 'ReferenceId',      
                ISNULL((ISNULL(SOP.QtyRequested ,0)- ISNULL(SUM(SOR.QtyToReserve),0)),0) as RequestedQty,      
                SOP.PromisedDate AS 'PromisedDate',      
                SOP.CustomerRequestDate AS 'EstimatedCompletionDate',      
                SOP.EstimatedShipDate 'EstimatedShipDate',      
				@viewType AS 'ViewType'      
			FROM [SalesOrderPartV1] SOP WITH(NOLOCK)      
            LEFT JOIN [DBO].[SalesOrderReserveParts] SOR WITH (NOLOCK) ON SOR.SalesOrderPartId = SOP.SalesOrderPartId      
            LEFT JOIN [DBO].[SalesOrder] SO WITH (NOLOCK) ON SO.SalesOrderId = SOP.SalesOrderId      
			LEFT JOIN [DBO].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = @ItemMasterId      
             AND ISNULL(IM.IsNonStock,0) = 0
			 LEFT JOIN [DBO].[Condition] C WITH (NOLOCK) ON C.ConditionId = @ConditionId      
			LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] Nha WITH (NOLOCK) ON Nha.ItemMasterId = @ItemMasterId AND (Nha.MappingType = 1 OR Nha.MappingType = 2)
			LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] MainNha WITH (NOLOCK) ON MainNha.MappingItemMasterId = @ItemMasterId AND (MainNha.MappingType = 1 OR MainNha.MappingType = 2)
			WHERE (SOP.ItemMasterId = @ItemMasterId AND SOP.ConditionId = @ConditionId OR
			((SOP.ItemMasterId = Nha.MappingItemMasterId OR SOP.ItemMasterId = MainNha.ItemMasterId) AND SOP.ConditionId = @ConditionId))
			AND SO.StatusId != @CloseSOStatusId  AND SO.StatusId != @CancelSOStatusId AND (@SearchText is null or SO.SalesOrderNumber LIKE '%'+@SearchText+'%')
			GROUP BY SOP.QtyRequested,SOR.QtyToReserve,SO.SalesOrderNumber,SO.SalesOrderId,  SOP.PromisedDate,SOP.CustomerRequestDate,SOP.EstimatedShipDate,IM.partnumber,C.Code      
			ORDER BY SO.SalesOrderId DESC;
		END      
		ELSE IF(@viewType = 'loadro')      
		BEGIN      
			SELECT DISTINCT      
				IM.partnumber AS 'PartNumber',      
				C.Code AS 'Condition',      
                RO.RepairOrderNumber AS 'ReferenceNum',      
				RO.RepairOrderId As 'ReferenceId',      
                0 as RequestedQty, -- ISNULL(SOP.qty ,0)  - ISNULL(SOP.QtyRequested ,0)) as RequestedQty,      
                NULL AS 'PromisedDate',      
                NULL AS 'EstimatedCompletionDate',      
                NULL 'EstimatedShipDate',      
				@viewType AS 'ViewType'      
			FROM [RepairOrderPart] ROP WITH(NOLOCK)       
            LEFT JOIN [DBO].[RepairOrder] RO WITH (NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId       
			LEFT JOIN [DBO].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = @ItemMasterId      
             AND ISNULL(IM.IsNonStock,0) = 0
			 LEFT JOIN [DBO].[Condition] C WITH (NOLOCK) ON C.ConditionId = @ConditionId      
			WHERE ROP.ItemMasterId = @ItemMasterId AND ROP.ConditionId = @ConditionId AND (@SearchText is null or RO.RepairOrderNumber LIKE '%'+@SearchText+'%')
			ORDER BY RO.RepairOrderId DESC;
		END      
		ELSE IF(@viewType = 'loadeso')      
        BEGIN
			SELECT DISTINCT      
				IM.partnumber AS 'PartNumber',      
				C.Code AS 'Condition',      
				ESO.ExchangeSalesOrderNumber AS 'ReferenceNum',      
				ESO.ExchangeSalesOrderId As 'ReferenceId',      
				ISNULL((ISNULL(ESOP.QtyRequested ,0)- ISNULL(SUM(SL.QuantityReserved),0)),0) as RequestedQty, -- ISNULL(SOP.qty ,0)  - ISNULL(SOP.QtyRequested ,0)) as RequestedQty,      
				NULL AS 'PromisedDate',      
				NULL AS 'EstimatedCompletionDate',      
				NULL 'EstimatedShipDate',      
				@viewType AS 'ViewType'      
            FROM [ExchangeSalesOrderPart] ESOP WITH(NOLOCK)           
            LEFT JOIN [DBO].[ExchangeSalesOrder] ESO WITH (NOLOCK) ON ESO.ExchangeSalesOrderId = ESOP.ExchangeSalesOrderId      
			LEFT JOIN [DBO].[Stockline] SL WITH (NOLOCK) ON SL.StockLineId = ESOP.StockLineId AND ISNULL(SL.IsNonStock,0) = 0
			LEFT JOIN [DBO].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = @ItemMasterId      
             AND ISNULL(IM.IsNonStock,0) = 0
			 LEFT JOIN [DBO].[Condition] C WITH (NOLOCK) ON C.ConditionId = @ConditionId      
			LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] Nha WITH (NOLOCK) ON Nha.ItemMasterId = @ItemMasterId AND (Nha.MappingType = 1 OR Nha.MappingType = 2)
			LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] MainNha WITH (NOLOCK) ON MainNha.MappingItemMasterId = @ItemMasterId AND (MainNha.MappingType = 1 OR MainNha.MappingType = 2)
            WHERE (ESOP.ItemMasterId = @ItemMasterId AND ESOP.ConditionId = @ConditionId
			OR ((ESOP.ItemMasterId = Nha.MappingItemMasterId OR ESOP.ItemMasterId = MainNha.ItemMasterId) AND ESOP.ConditionId = @ConditionId)) AND (@SearchText is null or ESO.ExchangeSalesOrderNumber LIKE '%'+@SearchText+'%')
			GROUP BY IM.partnumber,C.Code,ESO.ExchangeSalesOrderNumber,ESO.ExchangeSalesOrderId,ESOP.QtyRequested,SL.QuantityReserved
			ORDER BY ESO.ExchangeSalesOrderId DESC;
		END      
		ELSE IF(@viewType = 'loadswo')      
		BEGIN
			SELECT DISTINCT      
				IM.partnumber AS 'PartNumber',      
				C.Code AS 'Condition',      
				SWO.SubWorkOrderNo AS 'ReferenceNum',      
				SWO.SubWorkOrderId As 'ReferenceId',      
				--ISNULL(SWM.Quantity,0)  as RequestedQty, -- ISNULL(SOP.qty ,0)  - ISNULL(SOP.QtyRequested ,0)) as RequestedQty,    
				CASE WHEN  ( (((ISNULL(SUM(SWM.Quantity),0)) - ((ISNULL(SUM(SWM.TotalReserved),0)) + (ISNULL(SUM(SWM.TotalIssued),0)))) + (ISNULL(SUM(SWMK.Quantity),0))) - (SELECT ISNULL(SUM(Sl.QuantityAvailable), 0) FROM dbo.Stockline Sl where Sl.ItemMasterId = @ItemMasterId and Sl.ConditionId = @ConditionId AND IsParent = 1 AND IsCustomerStock = 0 AND ISNULL(Sl.IsNonStock,0) = 0) ) > 0 THEN ( (((ISNULL(SUM(SWM.Quantity),0)) - ((ISNULL(SUM(SWM.TotalReserved),0)) + (ISNULL(SUM(SWM.TotalIssued),0)))) + (ISNULL(SUM(SWMK.Quantity),0))) - (SELECT ISNULL(SUM(Sl.QuantityAvailable), 0) FROM dbo.Stockline Sl where Sl.ItemMasterId = @ItemMasterId and Sl.ConditionId = @ConditionId AND IsParent = 1 AND IsCustomerStock = 0 AND ISNULL(Sl.IsNonStock,0) = 0) ) ELSE 0 END as RequestedQty,      
				NULL AS 'PromisedDate',      
				NULL AS 'EstimatedCompletionDate',      
				NULL 'EstimatedShipDate',      
				@viewType AS 'ViewType'      
            FROM [SubWorkOrder] SWO  WITH(NOLOCK)      
            LEFT JOIN [DBO]. [SubWorkOrderMaterials] SWM WITH (NOLOCK) ON SWO.SubWorkOrderId = SWM.SubWorkOrderId      
            LEFT JOIN [DBO]. [SubWorkOrderMaterialsKit] SWMK WITH (NOLOCK) ON SWO.SubWorkOrderId = SWMK.SubWorkOrderId      
            LEFT JOIN [DBO].[ItemMaster] IM WITH (NOLOCK) ON IM.ItemMasterId = @ItemMasterId      
             AND ISNULL(IM.IsNonStock,0) = 0
             LEFT JOIN [DBO].[Condition] C WITH (NOLOCK) ON C.ConditionId = @ConditionId      
			LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] Nha WITH (NOLOCK) ON Nha.ItemMasterId = @ItemMasterId AND (Nha.MappingType = 1 OR Nha.MappingType = 2)
			LEFT JOIN [DBO].[Nha_Tla_Alt_Equ_ItemMapping] MainNha WITH (NOLOCK) ON MainNha.MappingItemMasterId = @ItemMasterId AND (MainNha.MappingType = 1 OR MainNha.MappingType = 2)
            WHERE ((SWM.ItemMasterId = @ItemMasterId AND SWM.ConditionCodeId = @ConditionId) 
			OR ((SWM.ItemMasterId = Nha.MappingItemMasterId OR SWM.ItemMasterId = MainNha.ItemMasterId) AND SWM.ConditionCodeId = @ConditionId)
			OR ((SWMK.ItemMasterId = Nha.MappingItemMasterId OR SWMK.ItemMasterId = MainNha.ItemMasterId) AND SWMK.ConditionCodeId = @ConditionId)
			OR (SWMK.ItemMasterId = @ItemMasterId AND SWMK.ConditionCodeId = @ConditionId)) AND  (@SearchText is null or SWO.SubWorkOrderNo LIKE '%'+@SearchText+'%')
			GROUP BY SWO.SubWorkOrderNo, IM.partnumber,C.code,SWO.SubWorkOrderId
			ORDER BY SWO.SubWorkOrderId DESC;
		END
		ELSE       
		BEGIN      
			SELECT '' as PartNumber      
		END
   END
  COMMIT TRANSACTION
  END TRY          
  BEGIN CATCH            
   IF @@trancount > 0      
    ROLLBACK TRAN;      
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
        , @AdhocComments     VARCHAR(150)    = 'USP_GetDataForAddMultipleSOWO'       
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterId, '') + ''      
        , @ApplicationName VARCHAR(100) = 'PAS'      
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------      
        exec spLogException       
                @DatabaseName   = @DatabaseName      
                , @AdhocComments   = @AdhocComments      
                , @ProcedureParameters  = @ProcedureParameters      
                , @ApplicationName         = @ApplicationName      
                , @ErrorLogID = @ErrorLogID OUTPUT ;      
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)      
        RETURN(1);      
  END CATCH      
END