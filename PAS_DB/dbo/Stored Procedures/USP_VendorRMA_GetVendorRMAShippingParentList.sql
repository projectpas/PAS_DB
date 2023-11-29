/*************************************************************           
 ** File:   [USP_VendorRMA_GetVendorRMAShippingParentList]          
 ** Author:   Amit Ghediya
 ** Description: This stored procedure is used to get shipping parent list data.
 ** Purpose:         
 ** Date:   06/27/2023        
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author					Change Description            
 ** --   --------     -------				--------------------------------          
    1    06/27/2023   Amit Ghediya			Created
	2    07/04/2023   Amit Ghediya  Updated for get RMANum from PArt lavel.
     
 EXECUTE USP_VendorRMA_GetVendorRMAShippingParentList 41
**************************************************************/
CREATE       Procedure [dbo].[USP_VendorRMA_GetVendorRMAShippingParentList]
@VendorRMAId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		SELECT DISTINCT imt.ItemMasterId AS VendorRMADetailId, sl.ConditionId, 0 AS ItemNo, sop.RMANum AS RMANumber, imt.partnumber, imt.PartDescription, 
			SUM(ISNULL(sopt.QtyToShip, 0)) AS QtyToShip,
			SUM(ISNULL(sosi.QtyShipped, 0)) AS QtyShipped,
			sop.VendorRMAId,
			SUM(ISNULL(sopt.QtyToShip, 0)) - SUM(ISNULL(sosi.QtyShipped, 0)) AS QtyRemaining,
			CASE WHEN SUM(ISNULL(sopt.QtyToShip, 0)) = SUM(ISNULL(sosi.QtyShipped, 0)) THEN 'Shipped'
			ELSE 'Shipping' END AS [Status]
			FROM DBO.VendorRMADetail sop WITH (NOLOCK)
			LEFT JOIN DBO.VendorRMA so WITH (NOLOCK) ON so.VendorRMAId = sop.VendorRMAId
			INNER JOIN DBO.RMAPickTicket sopt WITH (NOLOCK) ON sopt.VendorRMAId = sop.VendorRMAId AND sopt.VendorRMADetailId = sop.VendorRMADetailId
			LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId
			LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = sop.StockLineId --AND sl.ConditionId = sop.ConditionId
			LEFT JOIN DBO.RMAShippingItem sosi WITH (NOLOCK) ON sosi.VendorRMADetailId = sop.VendorRMADetailId 
						AND sosi.RMAPickTicketId = sopt.RMAPickTicketId
			LEFT JOIN DBO.RMAShipping sos WITH (NOLOCK) ON sos.RMAShippingId = sosi.RMAShippingId 
						AND sos.VendorRMAId = sopt.VendorRMAId
			WHERE sop.VendorRMAId = @VendorRMAId AND sopt.IsConfirmed = 1
			GROUP BY sop.RMANum, imt.partnumber, imt.PartDescription, imt.ItemMasterId, sop.VendorRMAId, sl.ConditionId
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_VendorRMA_GetVendorRMAShippingParentList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRMAId, '') + ''
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