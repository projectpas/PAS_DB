
/*************************************************************           
 ** File:   [USP_Lot_GetStockPartNumbersFromLot]           
 ** Author: Amit Ghediya
 ** Description: This stored procedure is used to Get added part list from lot.
 ** Date:   12/04/2023
 ** PARAMETERS:           
 ** RETURN VALUE:
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author  		Change Description            
 ** --   --------     -------		---------------------------     
    1    12/04/2023   Amit Ghediya     Created
**************************************************************
 EXEC USP_Lot_GetStockPartNumbersFromLot 1,1
**************************************************************/
Create    PROCEDURE [dbo].[USP_Lot_GetStockPartNumbersFromLot] 
@LotId BIGINT =0,
@MasterCompanyId INT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
  BEGIN TRANSACTION
	BEGIN
		
		SELECT 
			DISTINCT 
			im.partnumber AS 'PartNumber',
			im.ItemMasterId AS 'ItemMasterId'
		FROM [dbo].[LotTransInOutDetails] lin  WITH (NOLOCK)
		INNER JOIN [dbo].[Stockline] stk WITH (NOLOCK) ON lin.StockLineId = stk.StockLineId
		INNER JOIN [dbo].[ItemMaster] im WITH (NOLOCK) ON stk.ItemMasterId = im.ItemMasterId
		WHERE lin.LotId = @LotId AND stk.QuantityAvailable > 0;			

	END
	COMMIT  TRANSACTION
  END TRY
  BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_Lot_GetStockPartNumbersFromLot]',
            @ProcedureParameters varchar(3000) = '@LotId = ''' + CAST(ISNULL(@LotId, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
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