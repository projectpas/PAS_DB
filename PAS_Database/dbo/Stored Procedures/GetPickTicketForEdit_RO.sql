/*************************************************************           
 ** File:   [GetPickTicketForEdit_RO]
 ** Author: unknown
 ** Description: 
 ** Purpose:         
 ** Date:          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------
	1	 17/04/2025		Vishal Suthar	Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
-- NOTE: Added IsPiecePart condition in RepairOrderPart table for the UOM backport.
************************************************************************/
CREATE   PROCEDURE [dbo].[GetPickTicketForEdit_RO]
	@ROPickTicketId bigint,
	@RepairOrderId bigint,
	@RepairOrderPartId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		;WITH cte as(
			SELECT SUM(QtyToShip) AS TotalQtyToShip, RepairOrderId, RepairOrderPartId 
			FROM ROPickTicket WITH(NOLOCK) WHERE RepairOrderId = @RepairOrderId and RepairOrderPartId = @RepairOrderPartId
			GROUP BY RepairOrderId, RepairOrderPartId
		)
		select sopt.ROPickTicketId,
			sopt.RepairOrderId,
			sopt.RepairOrderPartId,
			imt.PartNumber,
			sl.StockLineId,
			imt.ItemMasterId As PartId,
			imt.PartDescription AS Description,
			sl.StockLineNumber,
			sl.SerialNumber,
			ISNULL(sl.QuantityAvailable, 0) AS QtyAvailable,
			ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand,
			sopt.QtyToShip,
			CASE 
				WHEN imt.IsPma = 1 and imt.IsDER = 1 THEN 'PMA&DER'
				WHEN imt.IsPma = 1 and imt.IsDER = 0 THEN 'PMA'
				WHEN imt.IsPma = 0 and imt.IsDER = 1 THEN 'DER'
			ELSE 'OEM'
			END AS StockType,
			CASE WHEN sl.TraceableToType = 1 THEN cusTraceble.Name
				WHEN sl.TraceableToType = 2 THEN vTraceble.VendorName
				WHEN sl.TraceableToType = 9 THEN leTraceble.Name
				WHEN sl.TraceableToType = 4 THEN CAST(sl.TraceableTo as varchar)
			ELSE ''
			END AS TracableToName,
			ISNULL(sop.QuantityOrdered, 0) - ISNULL(cte.TotalQtyToShip, 0) as QtyToPick from cte
		INNER JOIN DBO.ROPickTicket sopt WITH(NOLOCK) on sopt.RepairOrderId = cte.RepairOrderId AND sopt.RepairOrderPartId = cte.RepairOrderPartId
		INNER JOIN DBO.RepairOrder so WITH(NOLOCK) on so.RepairOrderId = sopt.RepairOrderId
		INNER JOIN DBO.RepairOrderPart sop WITH(NOLOCK) on sop.RepairOrderId = sopt.RepairOrderId AND sop.RepairOrderPartRecordId = sopt.RepairOrderPartId AND ISNULL(sop.IsPiecePart,0) = 0
		INNER JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
		INNER JOIN DBO.Stockline sl WITH(NOLOCK) on sl.StockLineId = sop.StockLineId
		LEFT JOIN DBO.Customer cusTraceble WITH(NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
		LEFT JOIN DBO.Vendor vTraceble WITH(NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
		LEFT JOIN DBO.LegalEntity leTraceble WITH(NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
		WHERE sopt.ROPickTicketId = @ROPickTicketId AND ISNULL(imt.IsNonStock,0) = 0 AND ISNULL(sl.IsNonStock,0) = 0 ;
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetPickTicketForEdit_RO' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ROPickTicketId, '') + ''',
														@Parameter2 = ' + ISNULL(@RepairOrderId,'') + ', 
														@Parameter3 = ' + ISNULL(@RepairOrderPartId,'') + ''
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