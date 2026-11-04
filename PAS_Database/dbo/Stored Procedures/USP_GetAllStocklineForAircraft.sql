
/*************************************************************
** File:        [USP_GetAllStocklineForAircraft]
** Description:
** Purpose:
** Date:
**
** RETURN VALUE:
**************************************************************
** Change History
**************************************************************
** PR   Date         Author         Change Description
** --   ----------   -------------  --------------------------------
** 1    2026-04-08   Amit Ghediya   Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	4    23/OCT/2026			 Kishor Makwana					[PN-18118] Sub Component: stockline that is a sub-component of another stockline (or has its own sub-components) and the aircraft / engine stockline itself are not listed.
																 Optional @AircraftInstalledPartDetailsId = installed row being edited, the aircraft / engine of that row is the parent and its own components stay in the list.
*************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetAllStocklineForAircraft]
(
    @ItemMasterId BIGINT,
    @MasterCompanyId INT,
    @AircraftInstalledPartDetailsId BIGINT = NULL
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
		-- [PN-18118] stockline of the aircraft / engine of the installed row being edited (parent of its installed components)
		DECLARE @ParentStocklineId BIGINT = NULL;
		IF (ISNULL(@AircraftInstalledPartDetailsId, 0) > 0)
		BEGIN
			SELECT @ParentStocklineId = CASE WHEN ISNULL(aipd.IsFromAircraft, 0) = 1 THEN arh.StockLineId ELSE erh.StockLineId END
			FROM dbo.AircraftInstalledPartDetails aipd WITH (NOLOCK)
				LEFT JOIN dbo.AircraftRegistryHeader arh WITH (NOLOCK) ON ISNULL(aipd.IsFromAircraft, 0) = 1 AND arh.AircraftRegistryId = aipd.AircraftRegistryId
				LEFT JOIN dbo.EngineRegistryHeader erh WITH (NOLOCK) ON ISNULL(aipd.IsFromAircraft, 0) = 0 AND erh.EngineRegistryId = aipd.EngineRegistryId
			WHERE aipd.AircraftInstalledPartDetailsId = @AircraftInstalledPartDetailsId;
		END

		
		SELECT 
			sl.StockLineId,
			sl.StockLineNumber,
			sl.ConditionId,
			sl.Condition,
			sl.SerialNumber,
			sl.ControlNumber,
			sl.IdNumber,
			sl.ItemMasterId,
			im.PartNumber,
			im.PartDescription,
			CASE 
				WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMA&DER'
				WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
				WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
				ELSE 'OEM'
			END AS StockType,
			sl.ManufacturerId,
			sl.Manufacturer,
			cn.Description AS UnitOfMeasure,
			sl.QuantityAvailable,
			sl.QuantityOnHand,
			sl.PurchaseOrderUnitCost,
			sl.IsCustomerStock,
			sl.CustomerName,
			sl.TraceableTo,
			sl.TraceableToName,
			sl.Owner,
			sl.OwnerName,
			sl.ObtainFromName,
			sl.TagDate,
			sl.TagType,
			sl.CertifiedBy,
			sl.CertifiedDate,
			sl.AircraftTailNumber,
			sl.Memo
		FROM dbo.StockLine sl WITH (NOLOCK)
		INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON sl.ItemMasterId = im.ItemMasterId
		LEFT JOIN dbo.UnitOfMeasure cn WITH (NOLOCK) ON sl.StockUnitOfMeasureId = cn.UnitOfMeasureId
		WHERE sl.ItemMasterId = @ItemMasterId
			AND sl.MasterCompanyId = @MasterCompanyId
			AND sl.QuantityAvailable > 0
			AND sl.IsParent = 1
     AND ISNULL(im.IsNonStock,0) = 0 AND ISNULL(sl.IsNonStock,0) = 0
			-- [PN-18118] not a sub-component of another stockline (its own aircraft / engine components stay), not a parent of sub-components, not the aircraft / engine stockline
			AND (ISNULL(sl.IsSubComponent, 0) = 0
				 OR (@ParentStocklineId IS NOT NULL AND sl.SubComponentParentStocklineId = @ParentStocklineId))
			AND NOT EXISTS (SELECT 1 FROM dbo.Stockline c WITH (NOLOCK) WHERE c.SubComponentParentStocklineId = sl.StockLineId)
			AND NOT EXISTS (SELECT 1 FROM dbo.AircraftRegistryHeader ah WITH (NOLOCK) WHERE ah.StockLineId = sl.StockLineId)
			AND NOT EXISTS (SELECT 1 FROM dbo.EngineRegistryHeader eh WITH (NOLOCK) WHERE eh.StockLineId = sl.StockLineId)
    END TRY
    BEGIN CATCH
        DECLARE
            @ErrorLogID INT,
            @DatabaseName VARCHAR(100) = DB_NAME(),
            @AdhocComments VARCHAR(150) = 'USP_GetAllStocklineForAircraft',
            @ProcedureParameters VARCHAR(3000),
            @ApplicationName VARCHAR(100) = 'PAS';

        SET @ProcedureParameters =
              '@ItemMasterId=' + CAST(ISNULL(@ItemMasterId, 0) AS VARCHAR(20))
            + ', @MasterCompanyId=' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(20));

        EXEC spLogException
             @DatabaseName        = @DatabaseName,
             @AdhocComments       = @AdhocComments,
             @ProcedureParameters = @ProcedureParameters,
             @ApplicationName     = @ApplicationName,
             @ErrorLogID          = @ErrorLogID OUTPUT;

        RAISERROR
        (
            'Unexpected error occurred in the database. Please let the support team know the error number: %d',
            16,
            1,
            @ErrorLogID
        );

        RETURN 1;
    END CATCH
END;