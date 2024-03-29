﻿-- =============================================
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

	EXEC [GetStocklineInventoryMismatch]

**************************************************************/

CREATE   PROC [dbo].[GetStocklineInventoryMismatch]

AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN

		SELECT  sl.StockLineId,
			sl.PartNumber, sl.PNDescription,sl.Manufacturer,
			con.Description  As 'Condition',sl.MasterCompanyId, sl.StocklineNumber , sl.ControlNumber ,
			sl.IdNumber,sl.SerialNumber 
		FROM [dbo].[StockLine] sl WITH (NOLOCK)
		INNER JOIN ItemMaster im WITH (NOLOCK) ON sl.ItemMasterId = im.ItemMasterId
		INNER JOIN Condition con WITH (NOLOCK) ON sl.conditionId = con.conditionId
		WHERE sl.isActive = 1 AND sl.isDeleted = 0
		AND (sl.QuantityOnHand + sl.QuantityIssued) <> (sl.QuantityReserved + sl.QuantityAvailable + sl.QuantityIssued)
	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
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