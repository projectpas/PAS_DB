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
     1    10/10/2024	AMIT GHEDIYA		Created
     2    12/07/2024	VISHAL SUTHAR		Removing the stockline from unreserve list those are already billed
	 3    17/01/2025	AMIT GHEDIYA		Handle mutiple invoiced data with laytest invoiced.
	 4    07-07-2025    Moin Bloch          Changed Old To New Billing Table
	 5    02/01/2026    Moin Bloch		    UOM Related Changes
	 6    07/01/2026    Rajesh Gami			Added MasterCompanyId Parameter While Calling UOM Conversion Function
EXEC [dbo].[GetUnReservedStockPartsListBySOId]  10851,0,0
**************************************************************/
CREATE    PROCEDURE [dbo].[GetUnReservedStockPartsListBySOId]
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

		;WITH UnreserveList AS (SELECT DISTINCT
			   sopi.SalesOrderReservePartId,
			   sop.SalesOrderPartId,
			   so.SalesOrderId,
			   im.ItemMasterId,
			   sop.ConditionId,
			   condi.[Description],
			   im.PartNumber,
			   im.PartDescription,
			   --sop.QtyOrder,
			   [dbo].[fn_ConvertUOM](ISNULL(sop.[QtyOrder], 0),stl.[StockUnitOfMeasure] ,stl.[ConsumeUnitOfMeasure],0,so.MasterCompanyId) AS QtyOrder,
			   sopi.ReservedById,
			   sopi.IssuedById,
			   sopi.ReservedDate,
			   sopi.IssuedDate,
			   sopi.IsAltPart,
			   sopi.IsEquPart,
			   sopi.AltPartMasterPartId,
			   sopi.EquPartMasterPartId,
			   --sopi.QtyToReserve AS 'QtyToUnReserve',
			   [dbo].[fn_ConvertUOM](ISNULL(sopi.[QtyToReserve], 0),stl.[StockUnitOfMeasure] ,stl.[ConsumeUnitOfMeasure],0,so.MasterCompanyId) AS 'QtyToUnReserve',
			   --sopi.QtyToReserve,
			   [dbo].[fn_ConvertUOM](ISNULL(sopi.[QtyToReserve], 0),stl.[StockUnitOfMeasure] ,stl.[ConsumeUnitOfMeasure],0,so.MasterCompanyId) AS QtyToReserve,
			   --sopi.TotalReserved,
			   [dbo].[fn_ConvertUOM](ISNULL(sopi.[TotalReserved], 0),stl.[StockUnitOfMeasure] ,stl.[ConsumeUnitOfMeasure],0,so.MasterCompanyId) AS TotalReserved,
			   @PartStatus As 'PartStatusId',
			   CASE 
			       WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMADER' 
			       WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
			       WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
			       ELSE 'OEM'
			   END AS StockType,
			   --stl.QuantityAvailable,
			   [dbo].[fn_ConvertUOM](ISNULL(stl.[QuantityAvailable], 0),stl.[StockUnitOfMeasure], stl.[ConsumeUnitOfMeasure],0,so.MasterCompanyId) AS QuantityAvailable, 
			   --stl.QuantityOnHand,
			   [dbo].[fn_ConvertUOM](ISNULL(stl.[QuantityOnHand], 0),stl.[StockUnitOfMeasure], stl.[ConsumeUnitOfMeasure],0,so.MasterCompanyId) AS QuantityOnHand, 
			   --stl.QuantityOnOrder,
			   [dbo].[fn_ConvertUOM](ISNULL(stl.[QuantityOnOrder], 0),stl.[StockUnitOfMeasure], stl.[ConsumeUnitOfMeasure],0,so.MasterCompanyId) AS QuantityOnOrder, 
			   stl.StockLineId,
			   --stl.QuantityIssued,
			   [dbo].[fn_ConvertUOM](ISNULL(stl.[QuantityIssued], 0),stl.[StockUnitOfMeasure], stl.[ConsumeUnitOfMeasure],0,so.MasterCompanyId) AS QuantityIssued, 
			   --stl.QuantityReserved,
			   [dbo].[fn_ConvertUOM](ISNULL(stl.[QuantityReserved], 0),stl.[StockUnitOfMeasure], stl.[ConsumeUnitOfMeasure],0,so.MasterCompanyId) AS QuantityReserved, 
			   --stl.QuantityToReceive,
			   [dbo].[fn_ConvertUOM](ISNULL(stl.[QuantityToReceive], 0),stl.[StockUnitOfMeasure], stl.[ConsumeUnitOfMeasure],0,so.MasterCompanyId) AS QuantityToReceive, 
			   stl.StockLineNumber,
			   stl.ControlNumber,
			   stl.MasterCompanyId,
			   im.ManufacturerName,
			   CASE WHEN 
				   @isFromShipping = 0
			   THEN 
				   ISNULL((SELECT --ISNULL(sobii.QtyBilled, 0) 
				   ISNULL([dbo].[fn_ConvertUOM](ISNULL(sobii.[QtyBilled], 0),stl.[StockUnitOfMeasure], stl.[ConsumeUnitOfMeasure],0,so.MasterCompanyId),0)
				   FROM [DBO].[BillingInvoicing] sobi WITH(NOLOCK)
				   LEFT JOIN [DBO].[BillingInvoicingItems] sobii WITH(NOLOCK) ON sobii.BillingInvoicingId = sobi.BillingInvoicingId				   
				   WHERE sobi.ReferenceId = @SalesOrderId AND ISNULL(sobi.IsPerformaInvoice, 0) = 0 AND sobi.[ModuleId] = @SOModuleId
				   AND sobii.StockLineId = stl.StockLineId
				   AND ISNULL(sobi.IsVersionIncrease,0) = 0), 0) 
				ELSE 0 END AS NoofPieces
		FROM [dbo].[SalesOrder] so WITH(NOLOCK)
		JOIN [dbo].[SalesOrderPartV1] sop WITH(NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
		JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON sop.ItemMasterId = im.ItemMasterId
		JOIN [dbo].[Customer] cu WITH(NOLOCK) ON so.CustomerId = cu.CustomerId
		JOIN [dbo].[SalesOrderReserveParts] sopi WITH(NOLOCK) ON sop.SalesOrderPartId = sopi.SalesOrderPartId and sop.SalesOrderId = sopi.SalesOrderId
		JOIN [dbo].[StockLine] stl WITH(NOLOCK) ON sopi.StockLineId = stl.StockLineId
		LEFT JOIN [DBO].[Condition] condi WITH(NOLOCK) ON sop.ConditionId = condi.ConditionId
		WHERE so.IsDeleted = 0 
		AND sop.IsDeleted = 0
		AND (sopi.TotalReserved > 0)
		AND so.SalesOrderId = @SalesOrderId
		AND (@ItemMasterId IS NULL OR im.ItemMasterId = @ItemMasterId))

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
			   ManufacturerName
			   FROM UnreserveList
			   WHERE NoofPieces = 0;
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