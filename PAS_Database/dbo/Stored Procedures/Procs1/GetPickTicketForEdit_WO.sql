Create   PROCEDURE [dbo].[GetPickTicketForEdit_WO]
@WOPickTicketId bigint,
@WorkOrderId bigint,
@WorkOrderPartId bigint,
@IsMPN bit
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				IF (@IsMPN = 1)
	BEGIN
		;WITH cte as(
			select SUM(QtyToShip)as TotalQtyToShip,WorkOrderId, WorkFlowWorkOrderId from WOPickTicket where WorkOrderId=@WorkOrderId and WorkFlowWorkOrderId=@WorkOrderPartId
			group by WorkOrderId, WorkFlowWorkOrderId
		)
		select wopt.PickTicketId,
			wopt.WorkOrderId,
			wopt.WorkFlowWorkOrderId,
			CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartNumber ELSE imt.PartNumber END as 'PartNumber',
			CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedPartDescription ELSE imt.PartDescription END as 'Description', 
			sl.StockLineId
			,CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE imt.ItemMasterId END As PartId
			,CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN wop.RevisedItemmasterid ELSE imt.ItemMasterId END As ItemMasterId
			,imt.PartDescription AS Description
			,sl.StockLineNumber
			,sl.SerialNumber
			,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable
			,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand,
			wopt.QtyToShip,
			CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN mfR.Name ELSE mf.Name END as 'Manufacturer',
			CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN ISNULL(imtR.ManufacturerId, -1) ELSE ISNULL(imt.ManufacturerId, -1) END as 'ManufacturerId',
			CASE WHEN ISNULL(wop.RevisedItemmasterid, 0) > 0 THEN CASE 
				WHEN imtR.IsPma = 1 and imtR.IsDER = 1 THEN 'PMA&DER'
				WHEN imtR.IsPma = 1 and imtR.IsDER = 0 THEN 'PMA'
				WHEN imtR.IsPma = 0 and imtR.IsDER = 1 THEN 'DER'
				ELSE 'OEM'
				END ELSE CASE 
				WHEN imt.IsPma = 1 and imt.IsDER = 1 THEN 'PMA&DER'
				WHEN imt.IsPma = 1 and imt.IsDER = 0 THEN 'PMA'
				WHEN imt.IsPma = 0 and imt.IsDER = 1 THEN 'DER'
				ELSE 'OEM'
				END END as 'StockType',

			    CASE WHEN sl.TraceableToType = 1 THEN cusTraceble.Name
					WHEN sl.TraceableToType = 2 THEN vTraceble.VendorName
					WHEN sl.TraceableToType = 9 THEN leTraceble.Name
					WHEN sl.TraceableToType = 4 THEN CAST(sl.TraceableTo as varchar)
					ELSE
						''
					END
				 AS TracableToName,
				  Smf.Name as StkLineManufacturer,
				 ISNULL(wop.Quantity,0) - ISNULL(cte.TotalQtyToShip,0) as QtyToPick from cte
		INNER JOIN DBO.WOPickTicket wopt WITH(NOLOCK) on wopt.WorkOrderId = cte.WorkOrderId AND wopt.WorkFlowWorkOrderId = cte.WorkFlowWorkOrderId
		INNER JOIN DBO.WorkOrder wo WITH(NOLOCK) on wo.WorkOrderId = wopt.WorkOrderId
		INNER JOIN DBO.WorkOrderWorkFlow wowf WITH(NOLOCK) on wopt.WorkFlowWorkOrderId = wowf.WorkOrderPartNoId
		INNER JOIN WorkOrderPartNumber wop  WITH(NOLOCK) on wop.WorkOrderId = wopt.WorkorderId and wowf.WorkOrderPartNoId = wop.ID
		INNER JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
		INNER JOIN DBO.Stockline sl WITH(NOLOCK) on sl.StockLineId = wop.StockLineId
		LEFT JOIN DBO.Manufacturer mf  WITH(NOLOCK) ON imt.ManufacturerId = mf.ManufacturerId
		LEFT JOIN DBO.ItemMaster imtR WITH(NOLOCK) on imtR.ItemMasterId = wop.RevisedItemmasterid
		LEFT JOIN DBO.Manufacturer mfR  WITH(NOLOCK) ON imtR.ManufacturerId = mfR.ManufacturerId
		LEFT JOIN DBO.Customer cusTraceble WITH(NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
		LEFT JOIN DBO.Vendor vTraceble WITH(NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
		LEFT JOIN DBO.LegalEntity leTraceble WITH(NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
		LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S WITH(NOLOCK)
			INNER JOIN DBO.Manufacturer M WITH(NOLOCK) ON M.ManufacturerId = S.ManufacturerId) Smf ON Smf.ItemMasterId = imt.ItemMasterId 
					AND Smf.StockLineId = sl.StockLineId
		WHERE wopt.PickTicketId=@WOPickTicketId;
	END
	ELSE
	BEGIN
		;WITH cte as(
		select SUM(QtyToShip)as TotalQtyToShip,WorkOrderId, WorkOrderMaterialsId from WorkorderPickTicket WITH(NOLOCK) where WorkOrderId = @WorkOrderId and WorkOrderMaterialsId = @WorkOrderPartId
		group by WorkOrderId, WorkOrderMaterialsId
		)
		select wopt.PickTicketId,
			wopt.WorkOrderId,
			wopt.WorkOrderMaterialsId,
			imt.PartNumber
			,sl.StockLineId
			,imt.ItemMasterId As PartId
			,imt.PartDescription AS Description
			,sl.StockLineNumber
			,sl.SerialNumber
			,ISNULL(sl.QuantityAvailable, 0) AS QtyAvailable
			,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand,
			mf.Name AS Manufacturer
			,ISNULL(imt.ManufacturerId, -1) AS ManufacturerId
			,wopt.QtyToShip
			,CASE 
				WHEN imt.IsPma = 1 and imt.IsDER = 1 THEN 'PMA&DER'
				WHEN imt.IsPma = 1 and imt.IsDER = 0 THEN 'PMA'
				WHEN imt.IsPma = 0 and imt.IsDER = 1 THEN 'DER'
				ELSE 'OEM'
				END AS StockType
			,CASE WHEN sl.TraceableToType = 1 THEN cusTraceble.Name
					WHEN sl.TraceableToType = 2 THEN vTraceble.VendorName
					WHEN sl.TraceableToType = 9 THEN leTraceble.Name
					WHEN sl.TraceableToType = 4 THEN CAST(sl.TraceableTo as varchar)
					ELSE
						''
					END
				 AS TracableToName,
				  Smf.Name as StkLineManufacturer,
				 ISNULL(wop.Quantity, 0) - ISNULL(cte.TotalQtyToShip, 0) as QtyToPick from cte
		INNER JOIN DBO.WorkorderPickTicket wopt WITH(NOLOCK) on wopt.WorkOrderId = cte.WorkOrderId AND wopt.WorkOrderMaterialsId = cte.WorkOrderMaterialsId
		INNER JOIN DBO.WorkOrder so WITH(NOLOCK) on so.WorkOrderId = wopt.WorkOrderId
		INNER JOIN DBO.WorkOrderMaterials wop  WITH(NOLOCK) on wop.WorkOrderId = wopt.WorkorderId and wop.WorkOrderMaterialsId = wopt.WorkOrderMaterialsId
		INNER JOIN DBO.WorkOrderMaterialStockLine woms WITH(NOLOCK) on woms.WorkOrderMaterialsId = wop.WorkOrderMaterialsId
		INNER JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = wop.ItemMasterId
		INNER JOIN DBO.Stockline sl WITH(NOLOCK) on sl.StockLineId = woms.StockLineId
	    LEFT JOIN DBO.Manufacturer mf  WITH(NOLOCK) ON imt.ManufacturerId = mf.ManufacturerId
		LEFT JOIN DBO.Customer cusTraceble WITH(NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
		LEFT JOIN DBO.Vendor vTraceble WITH(NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
		LEFT JOIN DBO.LegalEntity leTraceble WITH(NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
		LEFT JOIN (SELECT ItemMasterId, [Name],StockLineId FROM DBO.Stockline S WITH(NOLOCK)
			INNER JOIN DBO.Manufacturer M WITH(NOLOCK) ON M.ManufacturerId = S.ManufacturerId) Smf ON Smf.ItemMasterId = imt.ItemMasterId 
			AND Smf.StockLineId = sl.StockLineId
		WHERE wopt.PickTicketId = @WOPickTicketId;
	END
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetPickTicketForEdit_WO' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''
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