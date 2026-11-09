
/*************************************************************
 ** File:   [USP_GetSubComponentsForReceivingPOPart]
 ** Description: PO Receiving - Sub Components of one PO part, loaded when the user expands the Sub Component button of the part
                 (not on page load). Same grouping as USP_CreateSubComponentStocklinesForReceiving : Item Master > Sub Assembly >
                 Sub Component rows with Auto Create Stockline = Yes, summed per sub component part number + condition
                 (blank condition -> condition of the PO part).
                 Quantity = configured Qty of ONE main part. The screen multiplies it with the Qty To Receive.
 ** Date:   09-NOV-2026
 ** Author:  Kishor Makwana

 ** RETURN VALUE: one row per sub component (SubItemMasterId, PartNumber, PartDescription, Manufacturer, ConditionId, Condition,
                 Quantity, IsSerialized)
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09-NOV-2026  Kishor Makwana    [PN-18498] Created

-- EXEC [dbo].[USP_GetSubComponentsForReceivingPOPart] @PurchaseOrderPartRecordId = 5001, @MasterCompanyId = 1
************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetSubComponentsForReceivingPOPart]
	@PurchaseOrderPartRecordId BIGINT,
	@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN TRY
		SELECT IM.[ItemMasterId] AS [SubItemMasterId],
			   IM.[partnumber] AS [PartNumber],
			   IM.[PartDescription] AS [PartDescription],
			   MAN.[Name] AS [Manufacturer],
			   COND.[ConditionId] AS [ConditionId],
			   COND.[Description] AS [Condition],
			   SUM(ISNULL(SC.[Quantity], 0)) AS [Quantity],
			   CAST(ISNULL(IM.[isSerialized], 0) AS BIT) AS [IsSerialized]
		FROM [dbo].[PurchaseOrderPart] POP WITH (NOLOCK)
		INNER JOIN [dbo].[ItemMaster] MIM WITH (NOLOCK) ON MIM.[ItemMasterId] = POP.[ItemMasterId]
			AND ISNULL(MIM.[IsNonStock], 0) = 0 AND ISNULL(MIM.[IsAsset], 0) = 0
		INNER JOIN [dbo].[SubComponent] SC WITH (NOLOCK) ON SC.[ItemMasterId] = POP.[ItemMasterId]
			AND SC.[MasterCompanyId] = @MasterCompanyId AND ISNULL(SC.[IsActive], 0) = 1 AND ISNULL(SC.[IsDeleted], 0) = 0
			AND ISNULL(SC.[IsAutoCreateStockline], 0) = 1 AND ISNULL(SC.[Quantity], 0) > 0
			AND SC.[MappingItemMasterId] <> POP.[ItemMasterId]
		INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = SC.[MappingItemMasterId]
			AND ISNULL(IM.[IsActive], 1) = 1 AND ISNULL(IM.[IsDeleted], 0) = 0
		LEFT JOIN [dbo].[Manufacturer] MAN WITH (NOLOCK) ON MAN.[ManufacturerId] = IM.[ManufacturerId]
		LEFT JOIN [dbo].[Condition] COND WITH (NOLOCK) ON COND.[ConditionId] = ISNULL(SC.[ConditionId], POP.[ConditionId])
		WHERE POP.[PurchaseOrderPartRecordId] = @PurchaseOrderPartRecordId
		  AND ISNULL(POP.[IsDeleted], 0) = 0
		GROUP BY IM.[ItemMasterId], IM.[partnumber], IM.[PartDescription], MAN.[Name], COND.[ConditionId], COND.[Description], ISNULL(IM.[isSerialized], 0)
		ORDER BY IM.[partnumber], COND.[Description];
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetSubComponentsForReceivingPOPart'
			, @ProcedureParameters VARCHAR(3000) = '@PurchaseOrderPartRecordId = ''' + CONVERT(VARCHAR(20), ISNULL(@PurchaseOrderPartRecordId, 0)) + ''', @MasterCompanyId = ''' + CONVERT(VARCHAR(20), ISNULL(@MasterCompanyId, 0)) + ''''
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
