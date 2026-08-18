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
	1    08/14/2023	  Devendra SHekh		added ReadyToPick to result 
	2    08/17/2023	  Devendra SHekh		REMOVED ReadyToPick and added QtyRemaining
	3    09/25/2023	  Devendra SHekh		PICKTICKET issue resolved
	4    11/08/2023   Amit Ghediya          pick ticket issue for multipele part resolved
	5    10/15/2024   Vishal Suthar			Modified SP to get Pick ticket print data from new SO Part tables
	6    11/15/2024   Vishal Suthar			Fixed issue with populating list of stockline in Pick Ticket Print
	7    11/26/2024   Vishal Suthar			Fixed issue with populating qty to pick and qty remaining
	8    12/05/2024   Vishal Suthar			Fixed issue with printing and picked qty issue
	9   12/10/2024	  Moin Bloch		    Modified fixed dublicate Pickticket issue
	10   31/03/2026   Moin Bloch	        Update (Added UOM Changes PN-15067) 
	11   18/06/2026   Ayushi				[PN-16911]Skip fn_ConvertUOM call when ToUOM = FromUOM
	12    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	13    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	14    20/July/2026			 RAJESH GAMI						[PN-17350] - Removed IsNonStock=0 filters so Non-Stock parts appear on the pick ticket.
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
	
		SELECT sopt.[SOPickTicketId], 
		       sopt.[CreatedDate] AS SOPickTicketDate, 
			    sopt.[SalesOrderId], 
			    sl.[StockLineNumber], 
			   --stk.[QtyOrder] Qty,
				ISNULL((CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN ISNULL(stk.QtyOrder,0) ELSE dbo.fn_ConvertUOM(ISNULL(stk.QtyOrder,0),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,sl.MasterCompanyId) END),0) AS Qty,
				--sopt.QtyToShip AS QtyToPick,
				ISNULL((CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN ISNULL(sopt.QtyToShip,0) ELSE dbo.fn_ConvertUOM(ISNULL(sopt.QtyToShip,0),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,sl.MasterCompanyId) END),0) AS QtyToPick,
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
			    --sl.[QuantityOnHand],
				ISNULL((CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN ISNULL(sl.QuantityOnHand,0) ELSE dbo.fn_ConvertUOM(ISNULL(sl.QuantityOnHand,0),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,sl.MasterCompanyId) END),0) AS QuantityOnHand,
				--sl.[QuantityAvailable] AS QtyAvailable,
				ISNULL((CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN ISNULL(sl.QuantityAvailable,0) ELSE dbo.fn_ConvertUOM(ISNULL(sl.QuantityAvailable,0),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,sl.MasterCompanyId) END),0) AS QtyAvailable,
				sop.[Notes],
				--sopt.[QtyToShip] AS QtyShipped,
				ISNULL((CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN ISNULL(sopt.QtyToShip,0) ELSE dbo.fn_ConvertUOM(ISNULL(sopt.QtyToShip,0),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,sl.MasterCompanyId) END),0) AS QtyShipped,
				--sopt.QtyRemaining AS QtyRemaining
				ISNULL((CASE WHEN ISNULL(sl.StockUnitOfMeasure,'') = ISNULL(sl.ConsumeUnitOfMeasure,'') THEN ISNULL(sopt.QtyRemaining,0) ELSE dbo.fn_ConvertUOM(ISNULL(sopt.QtyRemaining,0),sl.StockUnitOfMeasure,sl.ConsumeUnitOfMeasure,0,sl.MasterCompanyId) END),0) AS QtyRemaining
		FROM [dbo].[SOPickTicket] sopt WITH(NOLOCK)
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