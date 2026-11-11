
/*************************************************************
 ** File:   [USP_GetLeaseStocklineSubComponents]
 ** Description: Lease > Add Item list > Actions > View Sub Components : the Sub Component stocklines linked to the main stockline
                 of one lease item (Stockline.SubComponentParentStocklineId = LeaseStockline.StockLineId, IsSubComponent = 1).
                 Only the sub components of the selected main stockline are returned (deleted stocklines are skipped).
 ** Date:   09-NOV-2026
 ** Author:  Kishor Makwana

 ** RETURN VALUE: one row per sub component stockline (StockLineId, ItemMasterId, PN, PNDescription, Manufacturer, Condition, Qty,
                 StockLineNumber, SerialNumber, ControlNumber)
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09-NOV-2026  Kishor Makwana    [PN-18499] Created

-- EXEC [dbo].[USP_GetLeaseStocklineSubComponents] @LeaseStocklineId = 1
************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetLeaseStocklineSubComponents]
	@LeaseStocklineId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN TRY
		SELECT SL.[StockLineId] AS [StockLineId],
			   SL.[ItemMasterId] AS [ItemMasterId],
			   SL.[PartNumber] AS [PN],
			   SL.[PNDescription] AS [PNDescription],
			   MAN.[Name] AS [Manufacturer],
			   COND.[Description] AS [Condition],
			   SL.[Quantity] AS [Qty],
			   SL.[StockLineNumber] AS [StockLineNumber],
			   SL.[SerialNumber] AS [SerialNumber],
			   SL.[ControlNumber] AS [ControlNumber]
		FROM [dbo].[LeaseStockline] LSL WITH (NOLOCK)
		INNER JOIN [dbo].[Stockline] SL WITH (NOLOCK) ON SL.[SubComponentParentStocklineId] = LSL.[StockLineId]
			AND ISNULL(SL.[IsSubComponent], 0) = 1 AND ISNULL(SL.[isDeleted], 0) = 0
		LEFT JOIN [dbo].[Manufacturer] MAN WITH (NOLOCK) ON MAN.[ManufacturerId] = SL.[ManufacturerId]
		LEFT JOIN [dbo].[Condition] COND WITH (NOLOCK) ON COND.[ConditionId] = SL.[ConditionId]
		WHERE LSL.[LeaseStocklineId] = @LeaseStocklineId AND LSL.[StockLineId] IS NOT NULL
		ORDER BY SL.[PartNumber], SL.[StockLineId];
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetLeaseStocklineSubComponents'
			, @ProcedureParameters VARCHAR(3000) = '@LeaseStocklineId = ''' + CONVERT(VARCHAR(20), ISNULL(@LeaseStocklineId, 0)) + ''''
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
			  @DatabaseName = @DatabaseName
			, @AdhocComments = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName = @ApplicationName
			, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR('Something went wrong (error log id : %d)', 16, 1, @ErrorLogID);
		RETURN(1);
	END CATCH
END
