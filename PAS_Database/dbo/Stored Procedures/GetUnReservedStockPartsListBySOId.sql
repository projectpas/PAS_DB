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

EXEC [dbo].[GetUnReservedStockPartsListBySOId]  1103
**************************************************************/
CREATE    PROCEDURE [dbo].[GetUnReservedStockPartsListBySOId]
    @SalesOrderId INT
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON
  BEGIN TRY
		DECLARE @PartStatus INT = 5;
		SELECT DISTINCT
			   sopi.SalesOrderReservePartId,
			   sop.SalesOrderPartId,
			   so.SalesOrderId,
			   im.ItemMasterId,
			   sop.ConditionId,
			   condi.[Description],
			   im.PartNumber,
			   im.PartDescription,
			   sop.QtyOrder,
			   sopi.ReservedById,
			   sopi.IssuedById,
			   sopi.ReservedDate,
			   sopi.IssuedDate,
			   sopi.IsAltPart,
			   sopi.IsEquPart,
			   sopi.AltPartMasterPartId,
			   sopi.EquPartMasterPartId,
			   sopi.QtyToReserve AS 'QtyToUnReserve',
			   sopi.QtyToReserve,
			   sopi.TotalReserved,
			   @PartStatus As 'PartStatusId',
			   CASE 
			       WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMADER' 
			       WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
			       WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
			       ELSE 'OEM'
			   END AS StockType,
			   stl.QuantityAvailable,
			   stl.QuantityOnHand,
			   stl.QuantityOnOrder,
			   stl.StockLineId,
			   stl.QuantityIssued,
			   stl.QuantityReserved,
			   stl.QuantityToReceive,
			   stl.StockLineNumber,
			   stl.ControlNumber,
			   stl.MasterCompanyId,
			   im.ManufacturerName
		FROM [DBO].[SalesOrder] so WITH(NOLOCK)
		JOIN [DBO].[SalesOrderPartV1] sop WITH(NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
		JOIN [DBO].[ItemMaster] im WITH(NOLOCK) ON sop.ItemMasterId = im.ItemMasterId
		JOIN [DBO].[Customer] cu WITH(NOLOCK) ON so.CustomerId = cu.CustomerId
		JOIN [DBO].[SalesOrderReserveParts] sopi WITH(NOLOCK) ON sop.SalesOrderPartId = sopi.SalesOrderPartId and sop.SalesOrderId = sopi.SalesOrderId
		JOIN [DBO].[StockLine] stl WITH(NOLOCK) ON sopi.StockLineId = stl.StockLineId
		LEFT JOIN [DBO].[Condition] condi WITH(NOLOCK) ON sop.ConditionId = condi.ConditionId
		WHERE so.IsDeleted = 0 
		AND sop.IsDeleted = 0
		AND sopi.TotalReserved > 0
		AND so.SalesOrderId = @SalesOrderId;
  END TRY
  BEGIN CATCH
    IF @@trancount > 0
		ROLLBACK TRAN;
		DECLARE @ErrorLogID int
		,@DatabaseName varchar(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
		,@AdhocComments varchar(150) = 'GetUnReservedStockPartsListBySOId'
		,@ProcedureParameters varchar(3000) = '@Parameter1 = ' + ISNULL(@SalesOrderId, '') + ''
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