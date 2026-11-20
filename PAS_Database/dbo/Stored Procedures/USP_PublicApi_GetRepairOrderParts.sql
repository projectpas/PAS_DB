
/*************************************************************
 ** File:   [USP_PublicApi_GetRepairOrderParts]
 ** Author: Moin Bloch
 ** Description: 4.22 Part lines of the ROs on one page (@RepairOrderIds = comma separated ids, max one page).
 **              Main lines have IsParent = 1; split lines have ParentId set and carry their ship-to destination.
 **              DiscountPercent is RepairOrderPart.DiscountPercent (a Percent id) as its percentage. ROs of another
 **              company are ignored.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/repairorders (part lines)
 ** Date:   18/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    18/11/2026   Moin Bloch    Created
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

  EXEC [dbo].[USP_PublicApi_GetRepairOrderParts] @MasterCompanyId = 1, @RepairOrderIds = '3052'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetRepairOrderParts]
    @MasterCompanyId INT,
    @RepairOrderIds  VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            -- Ids are used by the API to group lines per RO and nest split lines; not returned to clients.
            P.[RepairOrderId],
            P.[RepairOrderPartRecordId] AS [RepairOrderPartId],
            CASE WHEN ISNULL(P.[IsParent], 0) = 1 THEN NULL ELSE NULLIF(P.[ParentId], 0) END AS [ParentRepairOrderPartId],
            P.[PartNumber],
            P.[PartDescription],
            P.[ManufacturerPN] AS [ManufacturerPartNumber],
            P.[Manufacturer],
            P.[AltEquiPartNumber],
            P.[RevisedPartNumber],
            P.[ItemType],
            P.[StockType],
            P.[Condition],
            P.[UnitOfMeasure],
            P.[Priority],
            NULLIF(LTRIM(RTRIM(P.[WorkPerformed])), '') AS [WorkPerformed],
            P.[StockLineNumber],
            P.[ControlNumber],
            NULLIF(LTRIM(RTRIM(P.[SerialNumber])), '') AS [SerialNumber],
            P.[NeedByDate],
            P.[EstRecordDate] AS [EstReceiveDate],
            ISNULL(P.[QuantityOrdered], 0) AS [QuantityOrdered],
            ISNULL(P.[QuantityReceived], 0) AS [QuantityReceived],
            ISNULL(P.[QuantityBackOrdered], 0) AS [QuantityBackOrdered],
            ISNULL(P.[QuantityRejected], 0) AS [QuantityRejected],
            P.[VendorListPrice],
            PCT.[PercentValue] AS [DiscountPercent],
            P.[DiscountPerUnit],
            P.[DiscountAmount],
            P.[UnitCost],
            P.[ExtendedCost],
            P.[FunctionalCurrency],
            NULLIF(LTRIM(RTRIM(P.[VendorQuoteNo])), '') AS [VendorQuoteNo],
            P.[VendorQuoteDate],
            P.[WorkOrderNo],
            P.[SubWorkOrderNo],
            P.[SalesOrderNo],
            NULLIF(LTRIM(RTRIM(P.[ACTailNum])), '') AS [AircraftTailNumber],
            NULLIF(LTRIM(RTRIM(P.[ReferenceNumber])), '') AS [ReferenceNumber],
            P.[RoPartSplitUserType] AS [ShipToType],
            P.[RoPartSplitUser] AS [ShipToName],
            P.[RoPartSplitSiteName] AS [ShipToSite]
        FROM [dbo].[RepairOrderPart] P WITH (NOLOCK)
        INNER JOIN [dbo].[RepairOrder] RO WITH (NOLOCK)
            ON RO.[RepairOrderId] = P.[RepairOrderId] AND RO.[MasterCompanyId] = @MasterCompanyId AND RO.[IsDeleted] = 0
        LEFT JOIN [dbo].[Percent] PCT WITH (NOLOCK) ON PCT.[PercentId] = P.[DiscountPercent]
        WHERE P.[RepairOrderId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@RepairOrderIds, ','))
          AND ISNULL(P.[IsDeleted], 0) = 0
        ORDER BY P.[RepairOrderId], ISNULL(NULLIF(P.[ParentId], 0), P.[RepairOrderPartRecordId]), P.[RepairOrderPartRecordId];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetRepairOrderParts'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@RepairOrderIds, '') AS VARCHAR(100))
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