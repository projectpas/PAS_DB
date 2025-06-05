/*************************************************************           
 ** File:   [GetPickTicketPrint]           
 ** Author:    
 ** Description: This stored procedure is used to retrieve pickticket data for pdf
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
	1										This stored procedure is used to retrieve pickticket data for pdf
	2    08/14/2023	  Devendra SHekh		added ReadyToPick to result 
	3    08/17/2023	  Devendra SHekh		REMOVED ReadyToPick and added QtyRemaining
	4    09/25/2023	  Devendra SHekh		PICKTICKET issue resolved
	5    11/08/2023   Amit Ghediya          pick ticket issue for multipele part resolved
	6    10/15/2024   Vishal Suthar			Modified SP to get Pick ticket print data from new SO Part tables
	7    11/15/2024   Vishal Suthar			Fixed issue with populating list of stockline in Pick Ticket Print
	8    11/26/2024   Vishal Suthar			Fixed issue with populating qty to pick and qty remaining
	9    12/05/2024   Vishal Suthar			Fixed issue with printing and picked qty issue
	10   12/10/2024	  Moin Bloch		    Modified fixed dublicate Pickticket issue
     
-- EXEC [dbo].[GetPickTicketPrint] 1457, 1776, 1236
**************************************************************/
CREATE     PROCEDURE [dbo].[GetPickTicketPrint]
	@SalesOrderId bigint,
	@SalesOrderPartId bigint,
	@SOPickTicketId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	--BEGIN TRANSACTION
	--BEGIN
		DECLARE @pickTicketNo VARCHAR(50), @masterCompanyId BIGINT

		SELECT @pickTicketNo = [SOPickTicketNumber], @masterCompanyId = [MasterCompanyId] FROM [dbo].[SOPickTicket] WITH (NOLOCK) WHERE [SOPickTicketId] = @SOPickTicketId;

		;WITH TResrvePart AS (
			SELECT COUNT(sopp.[SalesOrderPartId]) AS TotalResrvePart, 
			       sopp.[SalesOrderId]
				FROM [dbo].[SalesOrderPartV1] sopp WITH(NOLOCK)
				LEFT JOIN [dbo].[SalesOrderStocklineV1] SOS WITH(NOLOCK) ON SOS.SalesOrderPartId = SOPP.SalesOrderPartId
				LEFT JOIN [dbo].[SOPickTicket] sopt WITH(NOLOCK) ON sopt.SalesOrderId = sopp.SalesOrderId AND SOPT.SalesOrderPartStocklineId = SOS.SalesOrderStocklineId
				WHERE SOPT.SalesOrderId = @SalesOrderId AND sopp.SalesOrderId = @SalesOrderId AND SOPickTicketNumber = @pickTicketNo
				group by sopp.SalesOrderId
			)
	 --,cte AS(
		--	SELECT ISNULL(SUM([QtyToShip]),0) AS TotalQtyToShip, 
		--	          MIN([QtyRemaining]) AS MinQty, 
		--			  SOPick.[SalesOrderId],
		--			  SOPick.[SalesOrderPartId]
		--		FROM [dbo].[SOPickTicket] SOPick WITH(NOLOCK) 
		--		WHERE SOPick.SalesOrderId = @SalesOrderId 
		--		AND SOPickTicketNumber = @pickTicketNo
		--		GROUP BY SOPick.SalesOrderId, SOPick.SalesOrderPartId
		--     )		
		SELECT sopt.[SOPickTicketId], 
		       sopt.[CreatedDate] AS SOPickTicketDate, 
			    sopt.[SalesOrderId], 
			    sl.[StockLineNumber], 
			    stk.[QtyOrder] Qty, 		
			   --CASE WHEN [MinQty] = 0 AND TResrvePart.[TotalResrvePart] > 1 THEN cte.[TotalQtyToShip] + 0 
			   --WHEN [MinQty] > 0 THEN cte.[TotalQtyToShip] + [MinQty] ELSE cte.[TotalQtyToShip] + sopt.[QtyRemaining] END AS [QtyToPick],
			    sopt.QtyToShip AS QtyToPick,
			    imt.[partnumber] AS PartNumber, 
			    imt.[PartDescription], 
			    sopt.[SOPickTicketNumber],
			    sl.[SerialNumber], 
			    sl.[ControlNumber], 
			    sl.[IdNumber], 
			    co.[Description] AS ConditionDescription,
			    so.[SalesOrderNumber], 
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
			   sop.[Notes], 		
			  sopt.[QtyToShip] AS QtyShipped,			
			  --CASE WHEN [MinQty] = 0 AND TResrvePart.[TotalResrvePart] > 1 THEN 0 WHEN [MinQty] > 0 THEN [MinQty] ELSE sopt.[QtyRemaining] END AS QtyRemaining
			  sopt.QtyRemaining AS QtyRemaining
		FROM [dbo].[SOPickTicket] sopt WITH(NOLOCK)
		--INNER JOIN cte WITH(NOLOCK) ON cte.SalesOrderId = sopt.SalesOrderId AND cte.SalesOrderPartId = sopt.SalesOrderPartId
		INNER JOIN [dbo].[SalesOrderStocklineV1] stk WITH(NOLOCK) ON stk.SalesOrderStocklineId = sopt.SalesOrderPartStocklineId
		INNER JOIN [dbo].[SalesOrderPartV1] sop WITH(NOLOCK) ON sop.SalesOrderId = sopt.SalesOrderId AND sop.SalesOrderPartId = stk.SalesOrderPartId
		INNER JOIN [dbo].[SalesOrder] so WITH(NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
		INNER JOIN [dbo].[Stockline] sl WITH(NOLOCK) ON sl.StockLineId = stk.StockLineId
		INNER JOIN [dbo].[ItemMaster] imt WITH(NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId
		 LEFT JOIN [dbo].[Condition] co WITH(NOLOCK) ON co.ConditionId = sop.ConditionId
		 LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON uom.UnitOfMeasureId = imt.ConsumeUnitOfMeasureId
		 LEFT JOIN [dbo].[Site] s WITH(NOLOCK) ON s.SiteId = sl.SiteId
		 LEFT JOIN [dbo].[Warehouse] w WITH(NOLOCK) ON w.WarehouseId = sl.WarehouseId
		 LEFT JOIN [dbo].[Location] l WITH(NOLOCK) ON l.LocationId = sl.LocationId
		 LEFT JOIN [dbo].[Shelf] sh WITH(NOLOCK) ON sh.ShelfId = sl.ShelfId
		 LEFT JOIN [dbo].[Bin] bn WITH(NOLOCK) ON bn.BinId = sl.BinId
		 LEFT JOIN [dbo].[Priority] p WITH(NOLOCK) ON p.PriorityId = sop.PriorityId
		 LEFT JOIN [dbo].[PurchaseOrder] po WITH(NOLOCK) ON po.PurchaseOrderId = sl.PurchaseOrderId
		 LEFT JOIN TResrvePart WITH(NOLOCK) ON TResrvePart.SalesOrderId = sopt.SalesOrderId
		WHERE 
		so.SalesOrderId = @SalesOrderId
		AND sopt.SOPickTicketNumber = @pickTicketNo
		ORDER BY sopt.SOPickTicketId ASC
	--END
	--COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetPickTicketPrint' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@SalesOrderId, '') AS VARCHAR(100)) + ''',
													 @Parameter2 = ' + CAST(ISNULL(@SalesOrderPartId,'') AS VARCHAR(100)) + ', 
													 @Parameter3 = ' + CAST(ISNULL(@SOPickTicketId,'') AS VARCHAR(100)) + ''
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