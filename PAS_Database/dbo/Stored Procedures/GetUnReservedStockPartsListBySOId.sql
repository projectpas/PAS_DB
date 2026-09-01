/*************************************************************           
 ** File:   [GetUnReservedStockPartsListBySOId]          
 ** Author:   AMIT GHEDIYA
 ** Description: This stored procedure is used to get SO for UnReserve Part Details.
 ** Purpose:         
 ** Date:   10/10/2024
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			 Author				Change Description            
 ** --   --------		 -------			--------------------------------          
     1    12/07/2024	VISHAL SUTHAR		Removing the stockline from unreserve list those are already billed
     2    10/10/2024	AMIT GHEDIYA		Created
	 3    17/01/2025	AMIT GHEDIYA		Handle mutiple invoiced data with laytest invoiced.
	 4    07-07-2025    Moin Bloch          Changed Old To New Billing Table
	 5    02/01/2026    Moin Bloch		    UOM Related Changes
	 6    07/01/2026    Rajesh Gami			Added MasterCompanyId Parameter While Calling UOM Conversion Function
	 7	  18/06/2026	Ayushi				[PN-16911]Skip fn_ConvertUOM call when ToUOM = FromUOM
	8    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	9    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	10    23/July/2026			 RAJESH GAMI						[PN-17350] - Removed leftover IsNonStock=0 exclusion filter(s) added during PN-17008/PN-17009 transitional Non-Stock merge phase (Non-Stock is now merged; filter no longer needed).
	11    30/July/2026    Moin Bloch                                 [PN-17485] - Added [IsService],[IsNonStock] Conditions For Ristrict Non Stock List to Un-Reserved
	12    12/Aug/2026    Moin Bloch                                 [PN-17485] - Changed IsService/IsNonStock filter from AND to OR
	13    17/Aug/2026     Kishor Makwana		[PN-17685] - UnResered Row not Comming
	14    21/Aug/2026     Kishor Makwana		[PN-17734] - Manage With New Column ToTalReservedQty - UnResered Row not Comming
EXEC [dbo].[GetUnReservedStockPartsListBySOId]  10851,0,0
**************************************************************/
CREATE     PROCEDURE [dbo].[GetUnReservedStockPartsListBySOId]
    @SalesOrderId BIGINT,
	@ItemMasterId BIGINT = NULL,
	@isFromShipping BIT = 0
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON
  BEGIN TRY
		DECLARE @SOModuleId INT
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';

		DECLARE @PartStatus INT = 5;

		IF(@ItemMasterId = 0) 
		BEGIN
			SET @ItemMasterId = NULL;	
		END

		;WITH UnreserveList AS (
		SELECT DISTINCT
			   sopi.SalesOrderReservePartId,
			   sop.SalesOrderPartId,
			   so.SalesOrderId,
			   im.ItemMasterId,
			   sop.ConditionId,
			   condi.[Description],
			   im.PartNumber,
			   im.PartDescription,
			   (CASE WHEN ISNULL(stl.StockUnitOfMeasure,'') = ISNULL(stl.ConsumeUnitOfMeasure,'') THEN ISNULL(sop.QtyOrder,0) ELSE dbo.fn_ConvertUOM(ISNULL(sop.QtyOrder,0),stl.StockUnitOfMeasure,stl.ConsumeUnitOfMeasure,0,so.MasterCompanyId) END) AS QtyOrder,
			   sopi.ReservedById,
			   sopi.IssuedById,
			   sopi.ReservedDate,
			   sopi.IssuedDate,
			   sopi.IsAltPart,
			   sopi.IsEquPart,
			   sopi.AltPartMasterPartId,
			   sopi.EquPartMasterPartId,
			   (CASE WHEN ISNULL(stl.StockUnitOfMeasure,'') = ISNULL(stl.ConsumeUnitOfMeasure,'') THEN ISNULL(sopi.QtyToReserve,0) ELSE dbo.fn_ConvertUOM(ISNULL(sopi.QtyToReserve,0),stl.StockUnitOfMeasure,stl.ConsumeUnitOfMeasure,0,so.MasterCompanyId) END) AS QtyToUnReserve,
			   (CASE WHEN ISNULL(stl.StockUnitOfMeasure,'') = ISNULL(stl.ConsumeUnitOfMeasure,'') THEN ISNULL(sopi.QtyToReserve,0) ELSE dbo.fn_ConvertUOM(ISNULL(sopi.QtyToReserve,0),stl.StockUnitOfMeasure,stl.ConsumeUnitOfMeasure,0,so.MasterCompanyId) END) AS QtyToReserve,
			   (CASE WHEN ISNULL(stl.StockUnitOfMeasure,'') = ISNULL(stl.ConsumeUnitOfMeasure,'') THEN ISNULL(sopi.TotalReserved,0) ELSE dbo.fn_ConvertUOM(ISNULL(sopi.TotalReserved,0),stl.StockUnitOfMeasure,stl.ConsumeUnitOfMeasure,0,so.MasterCompanyId) END) AS TotalReserved,
			   @PartStatus AS PartStatusId,
			   CASE WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMADER'
					WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
					WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
					ELSE 'OEM'
			   END AS StockType,
			   (CASE WHEN ISNULL(stl.StockUnitOfMeasure,'') = ISNULL(stl.ConsumeUnitOfMeasure,'') THEN ISNULL(stl.QuantityAvailable,0) ELSE dbo.fn_ConvertUOM(ISNULL(stl.QuantityAvailable,0),stl.StockUnitOfMeasure,stl.ConsumeUnitOfMeasure,0,so.MasterCompanyId) END) AS QuantityAvailable,
			   (CASE WHEN ISNULL(stl.StockUnitOfMeasure,'') = ISNULL(stl.ConsumeUnitOfMeasure,'') THEN ISNULL(stl.QuantityOnHand,0) ELSE dbo.fn_ConvertUOM(ISNULL(stl.QuantityOnHand,0),stl.StockUnitOfMeasure,stl.ConsumeUnitOfMeasure,0,so.MasterCompanyId) END) AS QuantityOnHand,
			   (CASE WHEN ISNULL(stl.StockUnitOfMeasure,'') = ISNULL(stl.ConsumeUnitOfMeasure,'') THEN ISNULL(stl.QuantityOnOrder,0) ELSE dbo.fn_ConvertUOM(ISNULL(stl.QuantityOnOrder,0),stl.StockUnitOfMeasure,stl.ConsumeUnitOfMeasure,0,so.MasterCompanyId) END) AS QuantityOnOrder,
			   stl.StockLineId,
			   (CASE WHEN ISNULL(stl.StockUnitOfMeasure,'') = ISNULL(stl.ConsumeUnitOfMeasure,'') THEN ISNULL(stl.QuantityIssued,0) ELSE dbo.fn_ConvertUOM(ISNULL(stl.QuantityIssued,0),stl.StockUnitOfMeasure,stl.ConsumeUnitOfMeasure,0,so.MasterCompanyId) END) AS QuantityIssued,
			   (CASE WHEN ISNULL(stl.StockUnitOfMeasure,'') = ISNULL(stl.ConsumeUnitOfMeasure,'') THEN ISNULL(stl.QuantityReserved,0) ELSE dbo.fn_ConvertUOM(ISNULL(stl.QuantityReserved,0),stl.StockUnitOfMeasure,stl.ConsumeUnitOfMeasure,0,so.MasterCompanyId) END) AS QuantityReserved,
			   (CASE WHEN ISNULL(stl.StockUnitOfMeasure,'') = ISNULL(stl.ConsumeUnitOfMeasure,'') THEN ISNULL(stl.QuantityToReceive,0) ELSE dbo.fn_ConvertUOM(ISNULL(stl.QuantityToReceive,0),stl.StockUnitOfMeasure,stl.ConsumeUnitOfMeasure,0,so.MasterCompanyId) END) AS QuantityToReceive,
			   stl.StockLineNumber,
			   stl.ControlNumber,
			   stl.MasterCompanyId,
			   im.ManufacturerName,
			   CASE WHEN @isFromShipping = 0
					THEN ISNULL((SELECT ISNULL((CASE WHEN ISNULL(stl.StockUnitOfMeasure,'') = ISNULL(stl.ConsumeUnitOfMeasure,'') THEN ISNULL(sobii.QtyBilled,0) ELSE dbo.fn_ConvertUOM(ISNULL(sobii.QtyBilled,0),stl.StockUnitOfMeasure,stl.ConsumeUnitOfMeasure,0,so.MasterCompanyId) END),0)
								 FROM DBO.BillingInvoicing sobi WITH(NOLOCK)
								 LEFT JOIN DBO.BillingInvoicingItems sobii WITH(NOLOCK) ON sobii.BillingInvoicingId = sobi.BillingInvoicingId
								 WHERE sobi.ReferenceId = @SalesOrderId
								 AND ISNULL(sobi.IsPerformaInvoice,0) = 0
								 AND sobi.ModuleId = @SOModuleId
								 AND sobii.StockLineId = stl.StockLineId
				   AND ISNULL(sobi.IsVersionIncrease,0) = 0), 0) 
				ELSE 0 END AS NoofPieces,
			   sop.ToTalReservedQty
		FROM [DBO].[SalesOrder] so WITH(NOLOCK)
		JOIN [DBO].[SalesOrderPartV1] sop WITH(NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
		JOIN [DBO].[ItemMaster] im WITH(NOLOCK) ON sop.ItemMasterId = im.ItemMasterId AND (ISNULL(im.[IsService],0) <> 1 OR ISNULL(im.[IsNonStock],0) <> 1)
		JOIN [DBO].[Customer] cu WITH(NOLOCK) ON so.CustomerId = cu.CustomerId
		JOIN [DBO].[SalesOrderReserveParts] sopi WITH(NOLOCK) ON sop.SalesOrderPartId = sopi.SalesOrderPartId and sop.SalesOrderId = sopi.SalesOrderId
		JOIN [DBO].[StockLine] stl WITH(NOLOCK) ON sopi.StockLineId = stl.StockLineId
		LEFT JOIN [DBO].[Condition] condi WITH(NOLOCK) ON sop.ConditionId = condi.ConditionId
		WHERE so.IsDeleted = 0 
		AND sop.IsDeleted = 0
		AND (sopi.TotalReserved > 0)
		AND so.SalesOrderId = @SalesOrderId
		AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId) )

		SELECT SalesOrderReservePartId,
			   SalesOrderPartId,
			   SalesOrderId,
			   ItemMasterId,
			   ConditionId,
			   [Description],
			   PartNumber,
			   PartDescription,
			   QtyOrder,
			   ReservedById,
			   IssuedById,
			   ReservedDate,
			   IssuedDate,
			   IsAltPart,
			   IsEquPart,
			   AltPartMasterPartId,
			   EquPartMasterPartId,
			   QtyToUnReserve,
			   QtyToReserve,
			   TotalReserved,
			   PartStatusId,
			   StockType,
			   QuantityAvailable,
			   QuantityOnHand,
			   QuantityOnOrder,
			   StockLineId,
			   QuantityIssued,
			   QuantityReserved,
			   QuantityToReceive,
			   StockLineNumber,
			   ControlNumber,
			   MasterCompanyId,
			   ManufacturerName,
			   ToTalReservedQty
			   FROM UnreserveList
			   WHERE (ISNULL((ISNULL(ToTalReservedQty,0) - NoofPieces),0) > 0) OR  (ISNULL((ISNULL(QtyOrder,0) - NoofPieces),0) > 0)
			   ORDER BY SalesOrderPartId ASC;
  END TRY
  BEGIN CATCH
  SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    IF @@trancount > 0
		ROLLBACK TRAN;
		DECLARE @ErrorLogID int
		,@DatabaseName varchar(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
		,@AdhocComments varchar(150) = 'GetUnReservedStockPartsListBySOId'		
		,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SalesOrderId, '') AS VARCHAR(100))  
		,@ApplicationName varchar(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END