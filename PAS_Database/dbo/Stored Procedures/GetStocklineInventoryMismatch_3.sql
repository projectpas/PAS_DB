-- =============================================
-- Author:		Ekta Chandegra
-- Create date: 26-12-2023
-- Description:	This stored procedure is used to count Stockline Inventory mismatch.
-- =============================================

/*************************************************************   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    26-12-2023   Ekta Chandegra		Created
	2    02-01-2024   Ekta Chandegra		Add quantity related fields
	3    30-01-2024   Vishal Suthar			Modified the SP to provide proper result
	4    30-08-2024   Rajesh Gami 			Add ISNULL
	5    30-08-2024   Rajesh Gami 			Add SUM of ChildQtyOnHand
	EXEC [GetStocklineInventoryMismatch]
**************************************************************/

CREATE PROC [dbo].[GetStocklineInventoryMismatch]

AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN
		SELECT TOP 100 sl.StockLineId,
			sl.PartNumber, sl.PNDescription,sl.Manufacturer,
			con.Description  As 'Condition',sl.MasterCompanyId, sl.StocklineNumber , sl.ControlNumber ,
			sl.IdNumber,sl.SerialNumber , ISNULL(sl.QuantityIssued,0) As 'QtyIssued', ISNULL(sl.QuantityReserved,0) As 'QtyReserved',
			ISNULL(sl.QuantityAvailable,0) As 'QtyAvail', ISNULL(sl.QuantityOnHand,0) As 'QtyOnHand',
			SUM(ISNULL(child.QuantityOnHand,0)) As 'ChildQtyOnHand'
		FROM [dbo].[StockLine] sl WITH (NOLOCK)
		INNER JOIN [dbo].[ItemMaster] im WITH (NOLOCK) ON sl.ItemMasterId = im.ItemMasterId
		INNER JOIN [dbo].[Condition] con WITH (NOLOCK) ON sl.conditionId = con.conditionId
		INNER JOIN [dbo].[ChildStockline] child WITH (NOLOCK) ON sl.StockLineId = child.StockLineId
		WHERE sl.isActive = 1 AND sl.isDeleted = 0 AND sl.IsParent = 1
		AND (ISNULL(sl.QuantityOnHand,0) + ISNULL(sl.QuantityIssued,0)) <> (ISNULL(sl.QuantityReserved,0) + ISNULL(sl.QuantityAvailable,0) + ISNULL(sl.QuantityIssued,0))
		GROUP BY sl.StockLineId, sl.PartNumber, sl.PNDescription,sl.Manufacturer, sl.QuantityOnHand, con.Description, sl.MasterCompanyId, sl.StocklineNumber , sl.ControlNumber,
		sl.IdNumber,sl.SerialNumber, sl.QuantityIssued, sl.QuantityReserved, sl.QuantityAvailable
		HAVING SUM(ISNULL(child.QuantityOnHand,0)) <> ISNULL(sl.QuantityOnHand,0)
		ORDER BY sl.StockLineId DESC
	END
	END TRY    
	BEGIN CATCH      
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetStocklineInventoryMismatch' 
            , @ProcedureParameters VARCHAR(3000)  = ''
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