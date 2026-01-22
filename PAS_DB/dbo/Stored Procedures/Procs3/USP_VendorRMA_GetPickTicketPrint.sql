/*************************************************************           
 ** File:   [ EXECUTE USP_VendorRMA_GetVendorRMAList]          
 ** Author:   Amit Ghediya
 ** Description: This stored procedure is used to Create for get Vendor RMA List data.
 ** Purpose:         
 ** Date:   06/26/2023        
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author						Change Description            
 ** --   --------     -------					--------------------------------          
    1    06/26/2023   Amit Ghediya				Created
    2    08/16/2023   Devendra shekh			commented RMAPickTicketNumber for cte and added ReadyToPick to result
    3    08/17/2023   Devendra shekh			removed commented RMAPickTicketNumber for cte and added ReadyToPick
     
**************************************************************/
-- EXEC [dbo].[USP_VendorRMA_GetPickTicketPrint] 262, 399, 172
CREATE   PROCEDURE [dbo].[USP_VendorRMA_GetPickTicketPrint]
	@VendorRMAId bigint,
	@VendorRMADetailId bigint,
	@RMAPickTicketId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		declare @pickTicketNo varchar(50), @masterCompanyId bigint

		Select @pickTicketNo = RMAPickTicketNumber, @masterCompanyId = MasterCompanyId FROM DBO.RMAPickTicket WITH (NOLOCK) WHERE RMAPickTicketId = @RMAPickTicketId;

		;WITH cte as(
				select SUM(QtyToShip)as TotalQtyToShip, SOPick.VendorRMAId, SOPick.VendorRMADetailId 
				from DBO.RMAPickTicket SOPick WITH(NOLOCK) 
				JOIN dbo.VendorRMADetail SOP WITH (NOLOCK) ON SOP.VendorRMADetailId = SOPick.VendorRMADetailId
				where SOPick.VendorRMAId = @VendorRMAId 
				AND RMAPickTicketNumber = @pickTicketNo
				group by SOPick.VendorRMAId, SOPick.VendorRMADetailId
		)
		--result as(
		select sopt.RMAPickTicketId, sopt.CreatedDate as RMAPickTicketDate, sopt.VendorRMAId, sl.StockLineNumber, 
		sop.Qty, 
		--sopt.QtyToShip as QtyShipped, 
		cte.TotalQtyToShip as QtyShipped, 
		imt.partnumber as PartNumber, imt.PartDescription, sopt.RMAPickTicketNumber,
		sl.SerialNumber, sl.ControlNumber, sl.IdNumber, co.[Description] as ConditionDescription,
		so.RMANumber, uom.ShortName as UOM, s.[Name] as SiteName, w.[Name] as WarehouseName, l.[Name] as LocationName, sh.[Name] as ShelfName,
		bn.[Name] as BinName,-- p.[Description] 
		'' as PriorityName, 
		po.PurchaseOrderNumber as PONumber,
		sl.QuantityOnHand, sl.QuantityAvailable as QtyAvailable, sop.Notes, 
		--(sop.QtyRequested - cte.TotalQtyToShip) as QtyToPick 
		QtyToShip as QtyToPick,
		sopt.QtyRemaining
		from RMAPickTicket sopt WITH(NOLOCK)
		INNER JOIN cte WITH(NOLOCK) ON cte.VendorRMAId = sopt.VendorRMAId AND cte.VendorRMADetailId = sopt.VendorRMADetailId
		INNER JOIN VendorRMADetail sop WITH(NOLOCK) ON sop.VendorRMAId = sopt.VendorRMAId AND sop.VendorRMADetailId = sopt.VendorRMADetailId
		INNER JOIN VendorRMA so WITH(NOLOCK) ON so.VendorRMAId = sop.VendorRMAId
		LEFT JOIN Stockline sl WITH(NOLOCK) ON sl.StockLineId = sop.StockLineId
		INNER JOIN ItemMaster imt WITH(NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId
		LEFT JOIN Condition co WITH(NOLOCK) ON co.ConditionId = sl.ConditionId
		LEFT JOIN UnitOfMeasure uom WITH(NOLOCK) ON uom.UnitOfMeasureId = imt.ConsumeUnitOfMeasureId
		LEFT JOIN [Site] s WITH(NOLOCK) ON s.SiteId = sl.SiteId
		LEFT JOIN Warehouse w WITH(NOLOCK) ON w.WarehouseId = sl.WarehouseId
		LEFT JOIN [Location] l WITH(NOLOCK) ON l.LocationId = sl.LocationId
		LEFT JOIN Shelf sh WITH(NOLOCK) ON sh.ShelfId = sl.ShelfId
		LEFT JOIN Bin bn WITH(NOLOCK) ON bn.BinId = sl.BinId
		--LEFT JOIN [Priority] p WITH(NOLOCK) ON p.PriorityId = sop.PriorityId
		LEFT JOIN PurchaseOrder po WITH(NOLOCK) ON po.PurchaseOrderId = sl.PurchaseOrderId
		WHERE 
		so.VendorRMAId = @VendorRMAId
		--sopt.SOPickTicketId = @SOPickTicketId;
		AND sopt.RMAPickTicketNumber = @pickTicketNo;

		--SELECT DISTINCT cte.RMAPickTicketId, cte.RMAPickTicketDate, cte.VendorRMAId, cte.StockLineNumber,cte.Qty, QtyShipped,PartNumber, PartDescription,
		--cte.RMAPickTicketNumber, cte.SerialNumber, cte.ControlNumber, cte.IdNumber, cte.ConditionDescription, cte.RMANumber, cte.UOM,
		--cte.SiteName, cte.WarehouseName, cte.LocationName, cte.ShelfName, cte.BinName, cte.PriorityName, cte.PONumber,
		--cte.QuantityOnHand, cte.QtyAvailable, cte.Notes, cte.QtyToPick,
		--CASE WHEN SUM(cte.QtyShipped) > 0 THEN (cte.Qty - SUM(cte.QtyShipped)) ELSE cte.Qty END AS ReadyToPick
		----cte.ReadyToPick
		--FROM result cte
		--GROUP BY cte.RMAPickTicketId, cte.RMAPickTicketDate, cte.VendorRMAId, cte.StockLineNumber,cte.Qty,QtyShipped,PartNumber, PartDescription,
		--cte.RMAPickTicketNumber, cte.SerialNumber, cte.ControlNumber, cte.IdNumber, cte.ConditionDescription, cte.RMANumber, cte.UOM,
		--cte.SiteName, cte.WarehouseName, cte.LocationName, cte.ShelfName, cte.BinName, cte.PriorityName, cte.PONumber,
		--cte.QuantityOnHand, cte.QtyAvailable, cte.Notes, cte.QtyToPick
		----,ReadyToPick

	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetPickTicketPrint' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRMAId, '') + ''',
														@Parameter2 = ' + ISNULL(@VendorRMADetailId,'') + ', 
														@Parameter3 = ' + ISNULL(@RMAPickTicketId,'') + ''
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