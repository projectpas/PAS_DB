/*************************************************************           
 ** File:   [GetUnReservedStockPartsDataById]          
 ** Author:   AMIT GHEDIYA
 ** Description: This stored procedure is used to get SO for UnReserve stock Part Details for stockline unreserve qty.
 ** Purpose:         
 ** Date:   11/10/2024
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			 Author				Change Description            
 ** --   --------		 -------			--------------------------------          
     1    11/10/2024	AMIT GHEDIYA		Created

EXEC [dbo].[GetUnReservedStockPartsDataById]  1103,1
**************************************************************/
CREATE    PROCEDURE [dbo].[GetUnReservedStockPartsDataById]
    @SalesOrderId BIGINT,
	@SalesOrderPartId BIGINT
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON
  BEGIN TRY
		SELECT 
			SOP.SalesOrderId,
			SOP.ItemMasterId,
			SOP.ConditionId,
			SOP.QtyRequested,
			SOP.StatusId,
			SOST.SalesOrderPartId,
			SOST.StockLineId
		FROM [DBO].[SalesOrderPartV1] SOP 
		JOIN [DBO].[SalesOrderStocklineV1] SOST WITH(NOLOCK) ON SOP.SalesOrderPartId = SOST.SalesOrderPartId
		WHERE SOP.SalesOrderId = @SalesOrderId AND SOP.SalesOrderPartId = @SalesOrderPartId
		ORDER BY SOP.CreatedDate DESC;
  END TRY
  BEGIN CATCH
    IF @@trancount > 0
		ROLLBACK TRAN;
		DECLARE @ErrorLogID int
		,@DatabaseName varchar(100) = DB_NAME()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------
		,@AdhocComments varchar(150) = 'GetUnReservedStockPartsDataById'
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