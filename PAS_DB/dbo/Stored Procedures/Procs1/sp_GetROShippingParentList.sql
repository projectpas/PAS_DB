-- ===== PROCEDURE: [dbo].[sp_GetROShippingParentList]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs1/sp_GetROShippingParentList.sql) =====
/*************************************************************           
 ** File:   [sp_GetROShippingParentList]           
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
	1	04/17/2024		VISHAL SUTHAR		Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
     
 -- [dbo].[sp_GetROShippingParentList] 2561
**************************************************************/
CREATE   PROCEDURE [dbo].[sp_GetROShippingParentList]
	@RepairOrderId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		SELECT DISTINCT imt.ItemMasterId AS RepairOrderPartId, rop.RepairOrderPartRecordId AS ROPartId, rop.ConditionId, 0 AS ItemNo, ro.RepairOrderNumber, imt.partnumber, imt.PartDescription, 
		SUM(ISNULL(ropt.QtyToShip, 0)) AS QtyToShip,
		SUM(ISNULL(rosi.QtyShipped, 0)) AS QtyShipped,
		rop.RepairOrderId,
		SUM(ISNULL(ropt.QtyToShip, 0)) - SUM(ISNULL(rosi.QtyShipped, 0)) AS QtyRemaining,
		CASE WHEN SUM(ISNULL(ropt.QtyToShip, 0)) = SUM(ISNULL(rosi.QtyShipped, 0)) THEN 'Shipped'
		ELSE 'Shipping' END AS [Status]
		FROM DBO.RepairOrderPart rop WITH (NOLOCK)
		LEFT JOIN DBO.RepairOrder ro WITH (NOLOCK) ON ro.RepairOrderId = rop.RepairOrderId
		INNER JOIN DBO.ROPickTicket ropt WITH (NOLOCK) ON ropt.RepairOrderId = rop.RepairOrderId AND ropt.RepairOrderPartId = rop.RepairOrderPartRecordId AND ropt.StocklineId = rop.StocklineId
		LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = rop.ItemMasterId
		 AND ISNULL(imt.IsNonStock,0) = 0
		 LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = rop.StockLineId AND sl.ConditionId = rop.ConditionId AND ISNULL(sl.IsNonStock,0) = 0
		LEFT JOIN DBO.RepairOrderShippingItem rosi WITH (NOLOCK) ON rosi.RepairOrderPartId = rop.RepairOrderPartRecordId AND rosi.ROPickTicketId = ropt.ROPickTicketId
		LEFT JOIN DBO.RepairOrderShipping ros WITH (NOLOCK) ON ros.RepairOrderShippingId = rosi.RepairOrderShippingId AND ros.RepairOrderId = ropt.RepairOrderId AND ros.RepairOrderId = @RepairOrderId
		WHERE rop.RepairOrderId = @RepairOrderId AND ropt.IsConfirmed = 1
		GROUP BY ro.RepairOrderNumber, imt.partnumber, imt.PartDescription, imt.ItemMasterId, rop.RepairOrderPartRecordId, rop.RepairOrderId, rop.ConditionId
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'sp_GetROShippingParentList' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@RepairOrderId, '') + ''
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