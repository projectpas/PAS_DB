/*************************************************************           
 ** File:   [GetPickTicketPrint_RO]           
 ** Author:    
 ** Description: This stored procedure is used to retrieve pickticket data for pdf
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR  Date			Author				Change Description            
 ** --  --------		-------				--------------------------------          
	1	04/15/2025		Vishal Suthar		Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
     
-- EXEC [dbo].[GetPickTicketPrint_RO] 2561, 4686, 1
**************************************************************/
CREATE   PROCEDURE [dbo].[GetPickTicketPrint_RO]
	@RepairOrderId bigint,
	@RepairOrderPartId bigint,
	@ROPickTicketId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @pickTicketNo VARCHAR(50), @masterCompanyId BIGINT

		SELECT @pickTicketNo = [ROPickTicketNumber], @masterCompanyId = [MasterCompanyId] FROM [dbo].[ROPickTicket] WITH (NOLOCK) WHERE [ROPickTicketId] = @ROPickTicketId;

		;WITH TResrvePart AS (
			SELECT COUNT(RepairOrderPartRecordId) AS TotalResrvePart, 
			    ropp.[RepairOrderId]
			FROM [dbo].[RepairOrderPart] ropp WITH(NOLOCK)
			LEFT JOIN [dbo].[ROPickTicket] ropt WITH(NOLOCK) ON ropt.RepairOrderId = ropp.RepairOrderId AND ropt.StocklineId = ropp.StocklineId
			WHERE ropt.RepairOrderId = @RepairOrderId AND ropp.RepairOrderId = @RepairOrderId AND ROPickTicketNumber = @pickTicketNo
			GROUP BY ropp.[RepairOrderId]
			)
		,cte AS(
			SELECT ISNULL(SUM([QtyToShip]),0) AS TotalQtyToShip, 
				MIN([QtyRemaining]) AS MinQty, 
				ROPick.[RepairOrderId],
				ROPick.[RepairOrderPartId]
			FROM [dbo].[ROPickTicket] ROPick WITH(NOLOCK) 
			WHERE ROPick.RepairOrderId = @RepairOrderId 
			AND ROPickTicketNumber = @pickTicketNo
			GROUP BY ROPick.RepairOrderId, ROPick.RepairOrderPartId
		)		
		SELECT ropt.[ROPickTicketId], 
			ropt.[CreatedDate] AS ROPickTicketDate, 
			ropt.[RepairOrderId], 
			sl.[StockLineNumber], 
			rop.[QuantityOrdered] Qty, 		
			CASE WHEN [MinQty] = 0 AND TResrvePart.[TotalResrvePart] > 1 THEN cte.[TotalQtyToShip] + 0 
			WHEN [MinQty] > 0 THEN cte.[TotalQtyToShip] + [MinQty] ELSE cte.[TotalQtyToShip] + ropt.[QtyRemaining] END AS [QtyToPick],
			imt.[partnumber] AS PartNumber, 
			imt.[PartDescription], 
			ropt.[ROPickTicketNumber],
			sl.[SerialNumber], 
			sl.[ControlNumber], 
			sl.[IdNumber], 
			co.[Description] AS ConditionDescription,
			ro.[RepairOrderNumber], 
			uom.[ShortName] AS UOM, 
			s.[Name] AS SiteName, 
			w.[Name] AS WarehouseName, 
			l.[Name] AS LocationName, 
			sh.[Name] AS ShelfName,
			bn.[Name] AS BinName, 
			p.[Description] AS PriorityName, 
			po.[PurchaseOrderNumber] AS PONumber,
			sl.[QuantityOnHand], 
			sl.[QuantityAvailable] AS QtyAvailable, 
			rop.Memo Notes,
			ropt.[QtyToShip] AS QtyShipped,			
			CASE WHEN [MinQty] = 0 AND TResrvePart.[TotalResrvePart] > 1 THEN 0 WHEN [MinQty] > 0 THEN [MinQty] ELSE ropt.[QtyRemaining] END AS QtyRemaining
		FROM [dbo].[ROPickTicket] ropt WITH(NOLOCK)
		INNER JOIN cte WITH(NOLOCK) ON cte.RepairOrderId = ropt.RepairOrderId AND cte.RepairOrderPartId = ropt.RepairOrderPartId
		INNER JOIN [dbo].[RepairOrderPart] rop WITH(NOLOCK) ON rop.RepairOrderId = ropt.RepairOrderId AND rop.RepairOrderPartRecordId = ropt.RepairOrderPartId AND rop.StockLineId = ropt.StocklineId
		INNER JOIN [dbo].[RepairOrder] ro WITH(NOLOCK) ON ro.RepairOrderId = rop.RepairOrderId
		INNER JOIN [dbo].[Stockline] sl WITH(NOLOCK) ON sl.StockLineId = rop.StockLineId
		INNER JOIN [dbo].[ItemMaster] imt WITH(NOLOCK) ON imt.ItemMasterId = rop.ItemMasterId
		LEFT JOIN [dbo].[Condition] co WITH(NOLOCK) ON co.ConditionId = rop.ConditionId
		LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON uom.UnitOfMeasureId = imt.ConsumeUnitOfMeasureId
		LEFT JOIN [dbo].[Site] s WITH(NOLOCK) ON s.SiteId = sl.SiteId
		LEFT JOIN [dbo].[Warehouse] w WITH(NOLOCK) ON w.WarehouseId = sl.WarehouseId
		LEFT JOIN [dbo].[Location] l WITH(NOLOCK) ON l.LocationId = sl.LocationId
		LEFT JOIN [dbo].[Shelf] sh WITH(NOLOCK) ON sh.ShelfId = sl.ShelfId
		LEFT JOIN [dbo].[Bin] bn WITH(NOLOCK) ON bn.BinId = sl.BinId
		LEFT JOIN [dbo].[Priority] p WITH(NOLOCK) ON p.PriorityId = rop.PriorityId
		LEFT JOIN [dbo].[PurchaseOrder] po WITH(NOLOCK) ON po.PurchaseOrderId = sl.PurchaseOrderId
		LEFT JOIN TResrvePart WITH(NOLOCK) ON TResrvePart.RepairOrderId = ropt.RepairOrderId
		WHERE ro.RepairOrderId = @RepairOrderId AND ropt.ROPickTicketNumber = @pickTicketNo
		 AND ISNULL(imt.IsNonStock,0) = 0 AND ISNULL(sl.IsNonStock,0) = 0
		 ORDER BY ropt.ROPickTicketId ASC
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetPickTicketPrint_RO' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@RepairOrderId, '') AS VARCHAR(100)) + ''',
													 @Parameter2 = ' + CAST(ISNULL(@RepairOrderPartId,'') AS VARCHAR(100)) + ', 
													 @Parameter3 = ' + CAST(ISNULL(@ROPickTicketId,'') AS VARCHAR(100)) + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName = @DatabaseName
                  , @AdhocComments = @AdhocComments
                  , @ProcedureParameters = @ProcedureParameters
                  , @ApplicationName = @ApplicationName
                  , @ErrorLogID = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END