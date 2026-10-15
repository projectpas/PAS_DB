/*************************************************************
 ** File:   [USP_GetStocklineSubComponentList]
 ** Description: Returns the parent stockline header (result set 1) and the stocklines linked to it as sub-components (result set 2).
 ** Date:   10/14/2026
 ** Author:  Kishor Makwana

 ** PARAMETERS:
	@ParentStocklineId  - stockline the sub-components are attached to
	@MasterCompanyId    - master company

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    10/14/2026  Kishor Makwana     [PN-18321] Created 

-- EXEC [dbo].[USP_GetStocklineSubComponentList] @ParentStocklineId = 1, @MasterCompanyId = 1
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetStocklineSubComponentList]
	@ParentStocklineId BIGINT,
	@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN TRY
		-- Result set 1 : parent header (shown read-only in the popup)
		SELECT
			s.[StockLineId],
			s.[PartNumber],
			s.[PNDescription] AS [PartDescription],
			s.[SerialNumber],
			s.[Manufacturer],
			s.[Condition],
			s.[StockLineNumber],
			s.[ControlNumber],
			ISNULL(s.[SubComponentParentStocklineId], 0) AS [SubComponentParentStocklineId]
		FROM [dbo].[Stockline] s WITH (NOLOCK)
		WHERE s.[StockLineId] = @ParentStocklineId
		  AND s.[MasterCompanyId] = @MasterCompanyId;

		-- Result set 2 : linked sub-components
		SELECT
			s.[StockLineId],
			s.[PartNumber],
			s.[PNDescription] AS [PartDescription],
			s.[StockLineNumber],
			s.[ControlNumber],
			s.[IdNumber],
			s.[SerialNumber],
			s.[Manufacturer],
			s.[Condition],
			ISNULL(s.[isSerialized], 0) AS [IsSerialized],
			ISNULL(s.[QuantityOnHand], 0) AS [QuantityOnHand],
			ISNULL(s.[QuantityAvailable], 0) AS [QuantityAvailable],
			ISNULL(s.[QuantityReserved], 0) AS [QuantityReserved],
			ISNULL(s.[SubComponentQty], 0) AS [Qty],
			ISNULL(s.[QuantityAvailable], 0) AS [MaxQty],
			s.[Site],
			s.[Warehouse],
			s.[Location]
		FROM [dbo].[Stockline] s WITH (NOLOCK)
		WHERE s.[SubComponentParentStocklineId] = @ParentStocklineId
		  AND s.[MasterCompanyId] = @MasterCompanyId
		  AND ISNULL(s.[isDeleted], 0) = 0
		ORDER BY s.[PartNumber], s.[StockLineNumber];
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetStocklineSubComponentList'
			, @ProcedureParameters VARCHAR(3000) = '@ParentStocklineId = ''' + CONVERT(VARCHAR(20), ISNULL(@ParentStocklineId, 0)) + ''', @MasterCompanyId = ''' + CONVERT(VARCHAR(20), ISNULL(@MasterCompanyId, 0)) + ''''
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
			  @DatabaseName = @DatabaseName
			, @AdhocComments = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName = @ApplicationName
			, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN(1);
	END CATCH
END