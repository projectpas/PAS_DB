/*************************************************************           
 ** File:   [sp_GetSOShippingParentList]           
 ** Author:   
 ** Description: 
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
	1	10/15/2024		VISHAL SUTHAR		Modified to make use of new SO part tables
	1	12/02/2024		AMIT GHEDIYA		Modified for get soPartid for expand & collapse
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
     
 -- [dbo].[sp_GetSOShippingParentList] 1269
**************************************************************/
CREATE Procedure [dbo].[sp_GetSOShippingParentList]
@SalesOrderId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		SELECT DISTINCT imt.ItemMasterId AS SalesOrderPartId,sop.SalesOrderPartId AS SOPartId, sop.ConditionId, 0 AS ItemNo, so.SalesOrderNumber, imt.partnumber, imt.PartDescription, 
		SUM(ISNULL(sopt.QtyToShip, 0)) AS QtyToShip,
		SUM(ISNULL(sosi.QtyShipped, 0)) AS QtyShipped,
		sop.SalesOrderId,
		SUM(ISNULL(sopt.QtyToShip, 0)) - SUM(ISNULL(sosi.QtyShipped, 0)) AS QtyRemaining,
		CASE WHEN SUM(ISNULL(sopt.QtyToShip, 0)) = SUM(ISNULL(sosi.QtyShipped, 0)) THEN 'Shipped'
		ELSE 'Shipping' END AS [Status]
		FROM DBO.SalesOrderPartV1 sop WITH (NOLOCK)
		LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId
		LEFT JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
		INNER JOIN DBO.SOPickTicket sopt WITH (NOLOCK) ON sopt.SalesOrderId = sop.SalesOrderId AND sopt.SalesOrderPartId = sop.SalesOrderPartId AND sopt.SalesOrderPartStocklineId = stk.SalesOrderStocklineId
		LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId
		 AND ISNULL(imt.IsNonStock,0) = 0 LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = stk.StockLineId AND sl.ConditionId = sop.ConditionId
		LEFT JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) ON sosi.SalesOrderPartId = sop.SalesOrderPartId 
					AND sosi.SOPickTicketId = sopt.SOPickTicketId
		LEFT JOIN DBO.SalesOrderShipping sos WITH (NOLOCK) ON sos.SalesOrderShippingId = sosi.SalesOrderShippingId 
					AND sos.SalesOrderId = sopt.SalesOrderId AND sos.SalesOrderId = @SalesOrderId
		WHERE sop.SalesOrderId = @SalesOrderId AND sopt.IsConfirmed = 1
		GROUP BY so.SalesOrderNumber, imt.partnumber, imt.PartDescription, imt.ItemMasterId,sop.SalesOrderPartId, sop.SalesOrderId, sop.ConditionId
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_GetSOShippingParentList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''
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