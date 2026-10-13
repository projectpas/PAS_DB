/*********************
 ** File:   GET WORK ORDER MATERIAL SHORTAGE LIST
 ** Author:  Nakul
 ** Description: Lists the WO material lines that current stock cannot cover, for MPNs whose Est Ship Date is within
 **              WorkOrderSettings.MaterialShortageWarningDays (default 30) of today. Drives the "Est Ship Date cannot be met"
 **              warning on WO save and on the Materials tab.
 ** Purpose: A line is short when stock (REPLACE / EXCHANGE provision) still to be reserved is more than the Qty Available
 **          left for it. Lines of the same WO with the same part + condition share that Qty Available in material order.
 **          An open PO on the line counts as cover only when its delivery date is on or before the Est Ship Date.
 **          @EstShipDatesJson NULL      -> saved Est Ship Dates (all MPNs, or only @WorkOrderPartNoId).
 **          @EstShipDatesJson not NULL  -> dates from the WO screen before save; only MPNs whose date was changed are checked.
 **          Returns nothing when the WO type's Bypass Stock Shortage Warning setting is on (the general Bypass Popups setting does not apply).
 ** Date:  12/10/2026

 ************************************************************
  ** Change History
 ************************************************************
  ** PR   Date         Author			Change Description
  ** --   --------     -------			--------------------------------
     1    12/10/2026   Nakul            Created for WO material shortage vs Est Ship Date warning [PN-12034]

 exec USP_GetWorkOrderMaterialShortageList @WorkOrderId=5960
 exec USP_GetWorkOrderMaterialShortageList @WorkOrderId=5960, @WorkOrderPartNoId=3782
 exec USP_GetWorkOrderMaterialShortageList @WorkOrderId=5960, @EstShipDatesJson=N'[{"workOrderPartNoId":3782,"estimatedShipDate":"10/15/2026"}]'
*************************************************************/
CREATE PROCEDURE [dbo].[USP_GetWorkOrderMaterialShortageList]
    @WorkOrderId       BIGINT,
    @WorkOrderPartNoId BIGINT        = NULL,
    @EstShipDatesJson  NVARCHAR(MAX) = NULL
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @MasterCompanyId INT, @WorkOrderTypeId BIGINT, @CustomerId BIGINT,
                @WarningDays INT, @BypassStockShortageWarning BIT, @Today DATE = CAST(GETDATE() AS DATE);

        SELECT @MasterCompanyId = WO.MasterCompanyId, @WorkOrderTypeId = WO.WorkOrderTypeId, @CustomerId = WO.CustomerId
        FROM [dbo].[WorkOrder] WO WITH(NOLOCK)
        WHERE WO.WorkOrderId = @WorkOrderId;

        SELECT TOP 1 @WarningDays = WOS.MaterialShortageWarningDays, @BypassStockShortageWarning = WOS.BypassStockShortageWarning
        FROM [dbo].[WorkOrderSettings] WOS WITH(NOLOCK)
        WHERE WOS.WorkOrderTypeId = @WorkOrderTypeId AND WOS.MasterCompanyId = @MasterCompanyId AND WOS.IsDeleted = 0
        ORDER BY WOS.UpdatedDate DESC;

        SET @WarningDays = ISNULL(@WarningDays, 30);
        IF (@WorkOrderPartNoId = 0) SET @WorkOrderPartNoId = NULL;

        IF OBJECT_ID(N'tempdb..#tmpShortageMPN') IS NOT NULL DROP TABLE #tmpShortageMPN;
        IF OBJECT_ID(N'tempdb..#tmpShortageLine') IS NOT NULL DROP TABLE #tmpShortageLine;

        CREATE TABLE #tmpShortageMPN
        (
            [WorkOrderPartNoId] BIGINT NOT NULL,
            [MPNPartNumber]     VARCHAR(200) NULL,
            [EstimatedShipDate] DATE NOT NULL
        );

        CREATE TABLE #tmpShortageLine
        (
            [WorkOrderPartNoId]     BIGINT NOT NULL,
            [MaterialId]            BIGINT NOT NULL,
            [IsKit]                 BIT NOT NULL,
            [ItemMasterId]          BIGINT NOT NULL,
            [ConditionId]           BIGINT NOT NULL,
            [QtyRequested]          DECIMAL(18, 6) NOT NULL,
            [QtyToBeReserved]       DECIMAL(18, 6) NOT NULL,
            [QtyOnOrder]            DECIMAL(18, 6) NULL,
            [PONum]                 VARCHAR(150) NULL,
            [PONextDlvrDate]        DATETIME2 NULL
        );

        IF (ISNULL(@BypassStockShortageWarning, 0) = 0 AND @MasterCompanyId IS NOT NULL)
        BEGIN
            -- MPNs to check, with the Est Ship Date in play
            IF (@EstShipDatesJson IS NULL)
            BEGIN
                INSERT INTO #tmpShortageMPN ([WorkOrderPartNoId], [MPNPartNumber], [EstimatedShipDate])
                SELECT WOP.ID, IM.PartNumber, CAST(WOP.EstimatedShipDate AS DATE)
                FROM [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK)
                LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = WOP.ItemMasterId
                WHERE WOP.WorkOrderId = @WorkOrderId AND WOP.IsDeleted = 0 AND ISNULL(WOP.IsClosed, 0) = 0
                  AND WOP.EstimatedShipDate IS NOT NULL
                  AND (@WorkOrderPartNoId IS NULL OR WOP.ID = @WorkOrderPartNoId);
            END
            ELSE
            BEGIN
                INSERT INTO #tmpShortageMPN ([WorkOrderPartNoId], [MPNPartNumber], [EstimatedShipDate])
                SELECT WOP.ID, IM.PartNumber, J.EstimatedShipDate
                FROM (SELECT [WorkOrderPartNoId], TRY_CONVERT(DATE, [EstimatedShipDate], 101) AS EstimatedShipDate
                      FROM OPENJSON(@EstShipDatesJson)
                      WITH ([WorkOrderPartNoId] BIGINT '$.workOrderPartNoId', [EstimatedShipDate] VARCHAR(20) '$.estimatedShipDate')) J
                JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WOP.ID = J.WorkOrderPartNoId AND WOP.WorkOrderId = @WorkOrderId
                LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = WOP.ItemMasterId
                WHERE WOP.IsDeleted = 0 AND ISNULL(WOP.IsClosed, 0) = 0
                  AND J.EstimatedShipDate IS NOT NULL
                  AND J.EstimatedShipDate <> ISNULL(CAST(WOP.EstimatedShipDate AS DATE), '1900-01-01')
                  AND (@WorkOrderPartNoId IS NULL OR WOP.ID = @WorkOrderPartNoId);
            END

            DELETE FROM #tmpShortageMPN WHERE DATEDIFF(DAY, @Today, [EstimatedShipDate]) > @WarningDays;

            -- Material lines still needing stock (REPLACE / EXCHANGE provisions)
            INSERT INTO #tmpShortageLine ([WorkOrderPartNoId], [MaterialId], [IsKit], [ItemMasterId], [ConditionId], [QtyRequested], [QtyToBeReserved], [QtyOnOrder], [PONum], [PONextDlvrDate])
            SELECT MPN.WorkOrderPartNoId, WOM.WorkOrderMaterialsId, 0, WOM.ItemMasterId, WOM.ConditionCodeId,
                   ISNULL(WOM.Quantity, 0),
                   ISNULL(WOM.Quantity, 0) - ISNULL(MSTL.QtyReserved, 0) - ISNULL(MSTL.QtyIssued, 0),
                   WOM.QtyOnOrder, WOM.PONum, WOM.PONextDlvrDate
            FROM #tmpShortageMPN MPN
            JOIN [dbo].[WorkOrderWorkFlow] WOWF WITH(NOLOCK) ON WOWF.WorkOrderPartNoId = MPN.WorkOrderPartNoId
            JOIN [dbo].[WorkOrderMaterials] WOM WITH(NOLOCK) ON WOM.WorkFlowWorkOrderId = WOWF.WorkFlowWorkOrderId AND WOM.IsDeleted = 0
            JOIN [dbo].[Provision] P WITH(NOLOCK) ON P.ProvisionId = WOM.ProvisionId AND UPPER(P.StatusCode) IN ('REPLACE', 'EXCHANGE')
            OUTER APPLY (SELECT SUM(ISNULL(WOMS.QtyReserved, 0)) AS QtyReserved, SUM(ISNULL(WOMS.QtyIssued, 0)) AS QtyIssued
                         FROM [dbo].[WorkOrderMaterialStockLine] WOMS WITH(NOLOCK)
                         WHERE WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId AND WOMS.IsActive = 1 AND WOMS.IsDeleted = 0) MSTL

            UNION ALL

            SELECT MPN.WorkOrderPartNoId, WOMK.WorkOrderMaterialsKitId, 1, WOMK.ItemMasterId, WOMK.ConditionCodeId,
                   ISNULL(WOMK.Quantity, 0),
                   ISNULL(WOMK.Quantity, 0) - ISNULL(MSTL.QtyReserved, 0) - ISNULL(MSTL.QtyIssued, 0),
                   WOMK.QtyOnOrder, WOMK.PONum, WOMK.PONextDlvrDate
            FROM #tmpShortageMPN MPN
            JOIN [dbo].[WorkOrderMaterialsKitMapping] WOMKIT WITH(NOLOCK) ON WOMKIT.WOPartNoId = MPN.WorkOrderPartNoId AND WOMKIT.IsDeleted = 0
            JOIN [dbo].[WorkOrderMaterialsKit] WOMK WITH(NOLOCK) ON WOMK.WorkOrderMaterialsKitMappingId = WOMKIT.WorkOrderMaterialsKitMappingId AND WOMK.IsDeleted = 0
            JOIN [dbo].[Provision] P WITH(NOLOCK) ON P.ProvisionId = WOMK.ProvisionId AND UPPER(P.StatusCode) IN ('REPLACE', 'EXCHANGE')
            OUTER APPLY (SELECT SUM(ISNULL(WOMS.QtyReserved, 0)) AS QtyReserved, SUM(ISNULL(WOMS.QtyIssued, 0)) AS QtyIssued
                         FROM [dbo].[WorkOrderMaterialStockLineKit] WOMS WITH(NOLOCK)
                         WHERE WOMS.WorkOrderMaterialsKitId = WOMK.WorkOrderMaterialsKitId AND WOMS.IsActive = 1 AND WOMS.IsDeleted = 0) MSTL;

            DELETE FROM #tmpShortageLine WHERE [QtyToBeReserved] <= 0;

            -- Share Qty Available across lines of the same part + condition, then apply PO cover due by the Est Ship Date
            ;WITH Avail AS
            (
                SELECT L.*,
                       ISNULL(STK.QtyAvailable, 0) AS QtyAvailable,
                       SUM(L.QtyToBeReserved) OVER (PARTITION BY L.ItemMasterId, L.ConditionId
                                                    ORDER BY L.WorkOrderPartNoId, L.IsKit, L.MaterialId ROWS UNBOUNDED PRECEDING) AS RunningDemand
                FROM #tmpShortageLine L
                OUTER APPLY (SELECT SUM(ISNULL(SL.QuantityAvailable, 0)) AS QtyAvailable
                             FROM [dbo].[Stockline] SL WITH(NOLOCK)
                             WHERE SL.ItemMasterId = L.ItemMasterId AND SL.ConditionId = L.ConditionId AND SL.IsParent = 1
                               AND SL.MasterCompanyId = @MasterCompanyId AND SL.IsActive = 1 AND SL.IsDeleted = 0
                               AND (SL.IsCustomerStock = 0 OR (SL.IsCustomerStock = 1 AND SL.CustomerId = @CustomerId))) STK
            ),
            Short AS
            (
                SELECT A.*,
                       CASE WHEN A.RunningDemand - A.QtyAvailable <= 0 THEN 0
                            WHEN A.RunningDemand - A.QtyAvailable >= A.QtyToBeReserved THEN A.QtyToBeReserved
                            ELSE A.RunningDemand - A.QtyAvailable END AS QtyShort
                FROM Avail A
            )
            SELECT MPN.WorkOrderPartNoId                              AS workOrderPartNoId,
                   MPN.MPNPartNumber                                  AS mpnPartNumber,
                   MPN.EstimatedShipDate                              AS estimatedShipDate,
                   DATEDIFF(DAY, @Today, MPN.EstimatedShipDate)       AS daysToShip,
                   IM.PartNumber                                      AS partNumber,
                   C.Description                                      AS condition,
                   S.QtyRequested                                     AS qtyRequested,
                   S.QtyToBeReserved                                  AS qtyToBeReserved,
                   S.QtyAvailable                                     AS qtyAvailable,
                   S.QtyShort                                         AS qtyShort,
                   S.PONum                                            AS poNum,
                   S.PONextDlvrDate                                   AS poNextDlvrDate,
                   uomStock.ShortName                                 AS stockUnitOfMeasure,
                   uomConsume.ShortName                               AS consumeUnitOfMeasure
            FROM Short S
            JOIN #tmpShortageMPN MPN ON MPN.WorkOrderPartNoId = S.WorkOrderPartNoId
            JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.ItemMasterId = S.ItemMasterId
            LEFT JOIN [dbo].[Condition] C WITH(NOLOCK) ON C.ConditionId = S.ConditionId
            LEFT JOIN [dbo].[UnitOfMeasure] uomStock WITH(NOLOCK) ON uomStock.UnitOfMeasureId = IM.StockUnitOfMeasureId
            LEFT JOIN [dbo].[UnitOfMeasure] uomConsume WITH(NOLOCK) ON uomConsume.UnitOfMeasureId = IM.ConsumeUnitOfMeasureId
            WHERE S.QtyShort > 0
              AND NOT (ISNULL(S.QtyOnOrder, 0) >= S.QtyShort AND S.PONextDlvrDate IS NOT NULL
                       AND CAST(S.PONextDlvrDate AS DATE) <= MPN.EstimatedShipDate)
            ORDER BY MPN.EstimatedShipDate, MPN.WorkOrderPartNoId, IM.PartNumber;
        END
        ELSE
        BEGIN
            -- Same columns, no rows, so callers can always read the result set
            SELECT CAST(NULL AS BIGINT) AS workOrderPartNoId, CAST(NULL AS VARCHAR(200)) AS mpnPartNumber, CAST(NULL AS DATE) AS estimatedShipDate,
                   CAST(NULL AS INT) AS daysToShip, CAST(NULL AS VARCHAR(200)) AS partNumber, CAST(NULL AS VARCHAR(256)) AS condition,
                   CAST(NULL AS DECIMAL(18, 6)) AS qtyRequested, CAST(NULL AS DECIMAL(18, 6)) AS qtyToBeReserved, CAST(NULL AS DECIMAL(18, 6)) AS qtyAvailable, CAST(NULL AS DECIMAL(18, 6)) AS qtyShort,
                   CAST(NULL AS VARCHAR(150)) AS poNum, CAST(NULL AS DATETIME2) AS poNextDlvrDate,
                   CAST(NULL AS VARCHAR(100)) AS stockUnitOfMeasure, CAST(NULL AS VARCHAR(100)) AS consumeUnitOfMeasure
            WHERE 1 = 0;
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments       VARCHAR(150)  = 'USP_GetWorkOrderMaterialShortageList'
              , @ProcedureParameters VARCHAR(3000) = '@WorkOrderId = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100))
                                                   + ''', @WorkOrderPartNoId = ''' + CAST(ISNULL(@WorkOrderPartNoId, '') AS VARCHAR(100))
                                                   + ''', @EstShipDatesJson = ''' + ISNULL(LEFT(@EstShipDatesJson, 2000), '') + ''''
              , @ApplicationName     VARCHAR(100)  = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException
                 @DatabaseName        = @DatabaseName
               , @AdhocComments       = @AdhocComments
               , @ProcedureParameters = @ProcedureParameters
               , @ApplicationName     = @ApplicationName
               , @ErrorLogID          = @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
        RETURN (1);
    END CATCH
END
