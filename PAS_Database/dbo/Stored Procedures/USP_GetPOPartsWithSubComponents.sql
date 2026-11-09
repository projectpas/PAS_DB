
/*************************************************************
 ** File:   [USP_GetPOPartsWithSubComponents]
 ** Description: PO Receiving - ids of the PO parts that have Sub Components (Item Master > Sub Assembly > Sub Component,
                 Auto Create Stockline = Yes). Only ids are returned (one light query), the Receiving PO screen uses it to show the
                 Sub Component expand button. The sub component rows themselves are loaded on expand
                 (USP_GetSubComponentsForReceivingPOPart).
 ** Date:   09-NOV-2026
 ** Author:  Kishor Makwana

 ** RETURN VALUE: PurchaseOrderPartRecordId list
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    09-NOV-2026  Kishor Makwana    [PN-18498] Created

-- EXEC [dbo].[USP_GetPOPartsWithSubComponents] @PurchaseOrderId = 2371, @MasterCompanyId = 1
************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetPOPartsWithSubComponents]
	@PurchaseOrderId BIGINT,
	@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN TRY
		SELECT DISTINCT POP.[PurchaseOrderPartRecordId]
		FROM [dbo].[PurchaseOrderPart] POP WITH (NOLOCK)
		INNER JOIN [dbo].[ItemMaster] MIM WITH (NOLOCK) ON MIM.[ItemMasterId] = POP.[ItemMasterId]
			AND ISNULL(MIM.[IsNonStock], 0) = 0 AND ISNULL(MIM.[IsAsset], 0) = 0
		INNER JOIN [dbo].[SubComponent] SC WITH (NOLOCK) ON SC.[ItemMasterId] = POP.[ItemMasterId]
			AND SC.[MasterCompanyId] = @MasterCompanyId AND ISNULL(SC.[IsActive], 0) = 1 AND ISNULL(SC.[IsDeleted], 0) = 0
			AND ISNULL(SC.[IsAutoCreateStockline], 0) = 1 AND ISNULL(SC.[Quantity], 0) > 0
			AND SC.[MappingItemMasterId] <> POP.[ItemMasterId]
		INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = SC.[MappingItemMasterId]
			AND ISNULL(IM.[IsActive], 1) = 1 AND ISNULL(IM.[IsDeleted], 0) = 0
		WHERE POP.[PurchaseOrderId] = @PurchaseOrderId
		  AND ISNULL(POP.[IsDeleted], 0) = 0
		  AND ISNULL(POP.[ItemTypeId], 1) = 1;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetPOPartsWithSubComponents'
			, @ProcedureParameters VARCHAR(3000) = '@PurchaseOrderId = ''' + CONVERT(VARCHAR(20), ISNULL(@PurchaseOrderId, 0)) + ''', @MasterCompanyId = ''' + CONVERT(VARCHAR(20), ISNULL(@MasterCompanyId, 0)) + ''''
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
