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
	1    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
*************************************************************/
create     PROCEDURE [dbo].[USP_GetAllStocklineForAircraft]
(
    @ItemMasterId BIGINT,
    @MasterCompanyId INT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
		
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
			--cn.Description AS UnitOfMeasure,
			'' AS UnitOfMeasure,
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
		--LEFT JOIN dbo.UnitOfMeasure cn WITH (NOLOCK) ON sl.StockUnitOfMeasureId = cn.UnitOfMeasureId
		WHERE sl.ItemMasterId = @ItemMasterId
			AND sl.MasterCompanyId = @MasterCompanyId
			AND sl.QuantityAvailable > 0
			AND sl.IsParent = 1
     AND ISNULL(im.IsNonStock,0) = 0
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