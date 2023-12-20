/*************************************************************           
 ** File:   [dbo].[sp_VendorRMA_GetPickTicketForEdit]          
 ** Author:   Amit Ghediya
 ** Description: Get Vendor RMA pick ticket stockline data for edit.
 ** Date: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/23/2023   Amit Ghediya   created

**************************************************************/ 
CREATE   PROCEDURE [dbo].[sp_VendorRMA_GetPickTicketForEdit]
@RMAPickTicketId bigint,
@VendorRMAId bigint,
@VendorRMADetailId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		;WITH cte as(
			select SUM(QtyToShip) as TotalQtyToShip, VendorRMAId, VendorRMADetailId from RMAPickTicket WITH(NOLOCK) where VendorRMAId = @VendorRMAId and VendorRMADetailId = @VendorRMADetailId
			group by VendorRMAId, VendorRMADetailId
		)
		select sopt.RMAPickTicketId,
			sopt.VendorRMAId,
			sopt.VendorRMADetailId,
			imt.PartNumber
			,sl.StockLineId
			,imt.ItemMasterId As PartId
			,imt.PartDescription AS Description
			,sl.StockLineNumber
			,sl.SerialNumber
			,ISNULL(sl.QuantityAvailable, 0) AS QtyAvailable
			,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand,
			sopt.QtyToShip
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
				 ISNULL(sop.Qty, 0) - ISNULL(cte.TotalQtyToShip, 0) as QtyToPick from cte
		INNER JOIN DBO.RMAPickTicket sopt WITH(NOLOCK) on sopt.VendorRMAId = cte.VendorRMAId AND sopt.VendorRMADetailId = cte.VendorRMADetailId
		INNER JOIN DBO.VendorRMA so WITH(NOLOCK) on so.VendorRMAId = sopt.VendorRMAId
		INNER JOIN DBO.VendorRMADetail sop WITH(NOLOCK) on sop.VendorRMAId = sopt.VendorRMAId AND sop.VendorRMADetailId = sopt.VendorRMADetailId
		INNER JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = sop.ItemMasterId
		INNER JOIN DBO.Stockline sl WITH(NOLOCK) on sl.StockLineId = sop.StockLineId
		LEFT JOIN DBO.Customer cusTraceble WITH(NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId
		LEFT JOIN DBO.Vendor vTraceble WITH(NOLOCK) ON sl.TraceableTo = vTraceble.VendorId
		LEFT JOIN DBO.LegalEntity leTraceble WITH(NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId
		WHERE sopt.RMAPickTicketId = @RMAPickTicketId;
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_VendorRMA_GetPickTicketForEdit' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RMAPickTicketId, '') + ''',
														@Parameter2 = ' + ISNULL(@VendorRMAId,'') + ', 
														@Parameter3 = ' + ISNULL(@VendorRMADetailId,'') + ''
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