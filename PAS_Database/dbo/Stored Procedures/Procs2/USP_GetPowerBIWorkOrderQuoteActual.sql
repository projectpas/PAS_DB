/*************************************************************
 ** File:   [USP_GetPowerBIWorkOrderQuoteActual]
 ** Author:   SUMIT KUMAR
 ** Description: Retrieve Work Order Quote vs. Actual Cost Variance data for Power BI
 ** Purpose: Multi-Work-Order version of the application screen
 **          Work Order > Analysis > Actual vs. Quote Summary.
 **          Cost derivations are ported verbatim from usp_GetWorkOrderAndQuoteCostDetails
 **          (which is scalar / single-line); this proc is the set-based equivalent.
 ** Date:   12-OCT-2026
 **************************************************************
 ** CHANGE HISTORY:
 **************************************************************
 ** S NO   Date         Author           Change Description
 ** 1      12-OCT-2026  SUMIT KUMAR      Created
 ** 2      27-OCT-2026  BHARGAV SALIYA   Work Scope / WO Status names from the masters by Id; IsWorkScopeActive
 **                                      added so the slicer can hide inactive/deleted scopes; lines with no
 **                                      quote return Quote Method 'No Quote' instead of 'T&M'
 **************************************************************/
CREATE PROCEDURE [dbo].[USP_GetPowerBIWorkOrderQuoteActual]
    @masterCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY

        DECLARE @WOModuleId INT;

        SELECT @WOModuleId = [ModuleId]
        FROM [dbo].[Module] WITH (NOLOCK)
        WHERE [ModuleName] = 'WorkOrder';

        ----------------------------------------------------------------------
        -- 1. Line spine: one row per MPN line (WorkFlowWorkOrderId).
        --    Tenant is anchored here on WorkOrder.MasterCompanyId; every
        --    aggregate below INNER JOINs back to #Lines, so no downstream
        --    table can leak another tenant's rows.
        ----------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#Lines') IS NOT NULL DROP TABLE #Lines;

        SELECT
            wwf.[WorkFlowWorkOrderId],
            wwf.[WorkOrderId],
            wwf.[WorkOrderPartNoId],
            wo.[WorkOrderNum],
            wo.[CustomerName],
            wo.[OpenDate],
            wo.[MasterCompanyId],
            wop.[PartNumber],
            -- Names come from the masters by Id: the text copies on
            -- WorkOrderPartNumber go stale when a scope/status is renamed or changed.
            ISNULL(ws.[WorkScopeCode], wop.[WorkScope])              AS [WorkScope],
            CAST(CASE WHEN ISNULL(ws.[IsActive], 0) = 1 AND ISNULL(ws.[IsDeleted], 0) = 0
                      THEN 1 ELSE 0 END AS BIT)                        AS [IsWorkScopeActive],
            ISNULL(wos.[Description], wop.[WorkOrderStatus])         AS [WorkOrderStatus],
            wop.[EmployeeStation],
            wop.[Level1],
            wop.[ItemMasterId],
            wop.[ConditionId],
            wop.[RepairOrderId]
        INTO #Lines
        FROM [dbo].[WorkOrderWorkFlow] wwf WITH (NOLOCK)
        INNER JOIN [dbo].[WorkOrder] wo WITH (NOLOCK)
            ON wwf.[WorkOrderId] = wo.[WorkOrderId]
        LEFT JOIN [dbo].[WorkOrderPartNumber] wop WITH (NOLOCK)
            ON wwf.[WorkOrderPartNoId] = wop.[ID]
           AND wop.[MasterCompanyId] = wo.[MasterCompanyId]
        LEFT JOIN [dbo].[WorkScope] ws WITH (NOLOCK)
            ON ws.[WorkScopeId] = wop.[WorkOrderScopeId]
        LEFT JOIN [dbo].[WorkOrderStatus] wos WITH (NOLOCK)
            ON wos.[Id] = wop.[WorkOrderStatusId]
        WHERE wo.[MasterCompanyId] = @masterCompanyId
          AND ISNULL(wo.[IsDeleted], 0) = 0
          AND ISNULL(wo.[IsActive], 1) = 1;

        CREATE CLUSTERED INDEX IX_Lines_WFWO ON #Lines ([WorkFlowWorkOrderId]);

        ----------------------------------------------------------------------
        -- 2. Actual Parts cost = WorkOrderMaterials + WorkOrderMaterialsKit
        --    (UnitCost * QtyIssued), per usp_GetWorkOrderAndQuoteCostDetails.
        ----------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#PartsCost') IS NOT NULL DROP TABLE #PartsCost;

        SELECT
            x.[WorkFlowWorkOrderId],
            SUM(x.[PartsCost]) AS [PartsCost]
        INTO #PartsCost
        FROM (
            SELECT
                wom.[WorkFlowWorkOrderId],
                ISNULL(SUM(ISNULL(woms.[UnitCost], 0) * ISNULL(woms.[QtyIssued], 0)), 0) AS [PartsCost]
            FROM [dbo].[WorkOrderMaterials] wom WITH (NOLOCK)
            INNER JOIN #Lines l ON l.[WorkFlowWorkOrderId] = wom.[WorkFlowWorkOrderId]
            INNER JOIN [dbo].[WorkOrderMaterialStockLine] woms WITH (NOLOCK)
                ON wom.[WorkOrderMaterialsId] = woms.[WorkOrderMaterialsId]
            WHERE ISNULL(wom.[IsDeleted], 0) = 0
              AND ISNULL(wom.[IsActive], 0) = 1
            GROUP BY wom.[WorkFlowWorkOrderId]

            UNION ALL

            SELECT
                womk.[WorkFlowWorkOrderId],
                ISNULL(SUM(ISNULL(womsk.[UnitCost], 0) * ISNULL(womsk.[QtyIssued], 0)), 0) AS [PartsCost]
            FROM [dbo].[WorkOrderMaterialsKit] womk WITH (NOLOCK)
            INNER JOIN #Lines l ON l.[WorkFlowWorkOrderId] = womk.[WorkFlowWorkOrderId]
            INNER JOIN [dbo].[WorkOrderMaterialStockLineKit] womsk WITH (NOLOCK)
                ON womk.[WorkOrderMaterialsKitId] = womsk.[WorkOrderMaterialsKitId]
            WHERE ISNULL(womk.[IsDeleted], 0) = 0
              AND ISNULL(womk.[IsActive], 0) = 1
            GROUP BY womk.[WorkFlowWorkOrderId]
        ) x
        GROUP BY x.[WorkFlowWorkOrderId];

        ----------------------------------------------------------------------
        -- 3. Actual Other / Misc charges. Freight is deliberately NOT included
        --    in Total Cost, matching the application screen.
        ----------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#Charges') IS NOT NULL DROP TABLE #Charges;

        SELECT
            woc.[WorkFlowWorkOrderId],
            ISNULL(SUM(ISNULL(woc.[ExtendedCost], 0)), 0) AS [OtherCost]
        INTO #Charges
        FROM [dbo].[WorkOrderCharges] woc WITH (NOLOCK)
        INNER JOIN #Lines l ON l.[WorkFlowWorkOrderId] = woc.[WorkFlowWorkOrderId]
        WHERE ISNULL(woc.[IsActive], 0) = 1
          AND ISNULL(woc.[IsDeleted], 0) = 0
        GROUP BY woc.[WorkFlowWorkOrderId];

        ----------------------------------------------------------------------
        -- 4. Actual Labor cost — billable lines only (BillableId = 1).
        ----------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#LaborCost') IS NOT NULL DROP TABLE #LaborCost;

        SELECT
            lh.[WorkFlowWorkOrderId],
            ISNULL(SUM(ISNULL(l.[TotalCost], 0)), 0) AS [LaborCost]
        INTO #LaborCost
        FROM [dbo].[WorkOrderLaborHeader] lh WITH (NOLOCK)
        INNER JOIN #Lines ln ON ln.[WorkFlowWorkOrderId] = lh.[WorkFlowWorkOrderId]
        INNER JOIN [dbo].[WorkOrderLabor] l WITH (NOLOCK)
            ON lh.[WorkOrderLaborHeaderId] = l.[WorkOrderLaborHeaderId]
           AND l.[MasterCompanyId] = ln.[MasterCompanyId]
        WHERE ISNULL(l.[BillableId], 0) = 1
          AND ISNULL(l.[IsActive], 0) = 1
          AND ISNULL(l.[IsDeleted], 0) = 0
        GROUP BY lh.[WorkFlowWorkOrderId];

        ----------------------------------------------------------------------
        -- 5. Quote side — current version only (IsVersionIncrease = 0).
        --    BuildMethod = 3 means Flat Rate for that bucket.
        ----------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#Quote') IS NOT NULL DROP TABLE #Quote;

        SELECT
            l.[WorkFlowWorkOrderId],
            ISNULL(q.[HasQuote], 0) AS [HasQuote],
            q.[QuoteMethod],
            q.[QuoteVersion],
            q.[MaterialCost],
            q.[LaborCost],
            q.[ChargesCost],
            q.[CommonFlatRate],
            q.[LaborBuildMethod],
            q.[MaterialFlatBillingAmount],
            q.[LaborFlatBillingAmount],
            q.[ChargesFlatBillingAmount]
        INTO #Quote
        FROM #Lines l
        OUTER APPLY (
            SELECT TOP 1
                CAST(1 AS BIT)                                                AS [HasQuote],
                ISNULL(qd.[QuoteMethod], 0)                                   AS [QuoteMethod],
                TRY_CAST(woq.[VersionNo] AS INT)                              AS [QuoteVersion],
                ISNULL(qd.[MaterialCost], 0)                                  AS [MaterialCost],
                ISNULL(qd.[LaborCost], 0)                                     AS [LaborCost],
                ISNULL(qd.[ChargesCost], 0)                                   AS [ChargesCost],
                ISNULL(qd.[CommonFlatRate], 0)                                AS [CommonFlatRate],
                qd.[LaborBuildMethod]                                         AS [LaborBuildMethod],
                CASE WHEN qd.[MaterialBuildMethod] = 3
                     THEN ISNULL(qd.[MaterialFlatBillingAmount], 0)
                     ELSE ISNULL(qd.[MaterialBilling], 0) END                 AS [MaterialFlatBillingAmount],
                CASE WHEN qd.[LaborBuildMethod] = 3
                     THEN ISNULL(qd.[LaborFlatBillingAmount], 0)
                     ELSE ISNULL(qd.[LaborBilling], 0) END                    AS [LaborFlatBillingAmount],
                CASE WHEN qd.[ChargesBuildMethod] = 3
                     THEN ISNULL(qd.[ChargesFlatBillingAmount], 0)
                     ELSE ISNULL(qd.[ChargesBilling], 0) END                  AS [ChargesFlatBillingAmount]
            FROM [dbo].[WorkOrderQuote] woq WITH (NOLOCK)
            INNER JOIN [dbo].[WorkOrderQuoteDetails] qd WITH (NOLOCK)
                ON qd.[WorkOrderQuoteId] = woq.[WorkOrderQuoteId]
            WHERE woq.[WorkOrderId] = l.[WorkOrderId]
              AND woq.[MasterCompanyId] = l.[MasterCompanyId]
              AND woq.[IsVersionIncrease] = 0
              AND qd.[WorkFlowWorkOrderId] = l.[WorkFlowWorkOrderId]
              AND ISNULL(qd.[IsVersionIncrease], 0) = 0
            ORDER BY qd.[WorkOrderQuoteDetailsId] DESC
        ) q;

        CREATE CLUSTERED INDEX IX_Quote_WFWO ON #Quote ([WorkFlowWorkOrderId]);

        ----------------------------------------------------------------------
        -- 6. Revenue. If a non-proforma invoice exists for the Work Order the
        --    revenue comes from WorkOrderMPNCostDetails; otherwise it falls
        --    back to the quote and IsRevenueFromQuote = 1.
        ----------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#Revenue') IS NOT NULL DROP TABLE #Revenue;

        SELECT
            l.[WorkFlowWorkOrderId],
            CAST(CASE WHEN inv.[WorkOrderId] IS NULL THEN 0 ELSE 1 END AS BIT) AS [IsInvoiced],
            ISNULL(mpn.[Revenue], 0)                                            AS [InvoicedRevenue]
        INTO #Revenue
        FROM #Lines l
        OUTER APPLY (
            SELECT TOP 1 bi.[ReferenceId] AS [WorkOrderId]
            FROM [dbo].[BillingInvoicing] bi WITH (NOLOCK)
            WHERE bi.[ReferenceId] = l.[WorkOrderId]
              AND bi.[ModuleId] = @WOModuleId
              AND bi.[MasterCompanyId] = l.[MasterCompanyId]
              AND ISNULL(bi.[IsVersionIncrease], 0) = 0
              AND ISNULL(bi.[IsPerformaInvoice], 0) = 0
        ) inv
        OUTER APPLY (
            SELECT TOP 1 cd.[Revenue]
            FROM [dbo].[WorkOrderMPNCostDetails] cd WITH (NOLOCK)
            WHERE cd.[WOPartNoId] = l.[WorkOrderPartNoId]
        ) mpn;

        CREATE CLUSTERED INDEX IX_Revenue_WFWO ON #Revenue ([WorkFlowWorkOrderId]);

        ----------------------------------------------------------------------
        -- 7. Shape the payload. Column names match the Power BI contract
        --    exactly; the repository maps them 1:1.
        ----------------------------------------------------------------------
        ;WITH Costed AS
        (
            SELECT
                l.[WorkFlowWorkOrderId],
                l.[WorkOrderId],
                l.[WorkOrderNum],
                l.[PartNumber],
                l.[CustomerName],
                l.[OpenDate],
                l.[WorkScope],
                l.[IsWorkScopeActive],
                l.[WorkOrderStatus],
                l.[EmployeeStation],
                l.[Level1],
                l.[ItemMasterId],
                l.[ConditionId],
                l.[RepairOrderId],

                ISNULL(q.[HasQuote], 0)      AS [HasQuote],
                ISNULL(q.[QuoteMethod], 0)   AS [QuoteMethodBit],
                ISNULL(q.[QuoteVersion], 1)  AS [QuoteVersion],

                -- Per Quote, per cost category. Flat Rate carries no breakdown.
                CASE WHEN ISNULL(q.[QuoteMethod], 0) = 1 THEN 0
                     ELSE ISNULL(q.[MaterialCost], 0) END                       AS [QuotePartsCost],
                CASE WHEN ISNULL(q.[QuoteMethod], 0) = 1 THEN 0
                     WHEN q.[LaborBuildMethod] = 3 THEN ISNULL(q.[LaborFlatBillingAmount], 0)
                     ELSE ISNULL(q.[LaborCost], 0) END                          AS [QuoteLaborCost],
                CASE WHEN ISNULL(q.[QuoteMethod], 0) = 1 THEN 0
                     ELSE ISNULL(q.[ChargesCost], 0) END                        AS [QuoteOtherCost],

                -- Quoted revenue (WOQRevenue in the application proc).
                CASE WHEN ISNULL(q.[QuoteMethod], 0) = 1
                     THEN ISNULL(q.[CommonFlatRate], 0)
                     ELSE ISNULL(q.[MaterialFlatBillingAmount], 0)
                        + ISNULL(q.[LaborFlatBillingAmount], 0)
                        + ISNULL(q.[ChargesFlatBillingAmount], 0) END           AS [QuoteRevenue],

                ISNULL(pc.[PartsCost], 0)    AS [ActualPartsCost],
                ISNULL(lc.[LaborCost], 0)    AS [ActualLaborCost],
                ISNULL(ch.[OtherCost], 0)    AS [ActualOtherCost],

                rev.[IsInvoiced],
                rev.[InvoicedRevenue]
            FROM #Lines l
            LEFT JOIN #Quote     q  ON q.[WorkFlowWorkOrderId]  = l.[WorkFlowWorkOrderId]
            LEFT JOIN #PartsCost pc ON pc.[WorkFlowWorkOrderId] = l.[WorkFlowWorkOrderId]
            LEFT JOIN #LaborCost lc ON lc.[WorkFlowWorkOrderId] = l.[WorkFlowWorkOrderId]
            LEFT JOIN #Charges   ch ON ch.[WorkFlowWorkOrderId] = l.[WorkFlowWorkOrderId]
            LEFT JOIN #Revenue   rev ON rev.[WorkFlowWorkOrderId] = l.[WorkFlowWorkOrderId]
        ),
        Totalled AS
        (
            SELECT
                c.*,
                -- Flat Rate: only CommonFlatRate is meaningful, carried on QuoteRevenue.
                CASE WHEN c.[QuoteMethodBit] = 1
                     THEN c.[QuoteRevenue]
                     ELSE c.[QuotePartsCost] + c.[QuoteLaborCost] + c.[QuoteOtherCost] END AS [QuoteTotalCost],
                c.[ActualPartsCost] + c.[ActualLaborCost] + c.[ActualOtherCost]            AS [ActualTotalCost]
            FROM Costed c
        ),
        Banded AS
        (
            SELECT
                t.*,
                (t.[ActualTotalCost] - t.[QuoteTotalCost]) / NULLIF(t.[QuoteTotalCost], 0) AS [VarPct]
            FROM Totalled t
        )
        SELECT
            CAST(b.[WorkFlowWorkOrderId] AS BIGINT)                 AS [WorkflowWorkOrderId],
            CAST(b.[WorkOrderId] AS BIGINT)                         AS [WorkOrderId],
            CAST(b.[WorkOrderNum] AS VARCHAR(50))                   AS [WorkOrderNum],
            CAST(b.[PartNumber] AS VARCHAR(100))                    AS [MPN],
            CAST(b.[CustomerName] AS VARCHAR(150))                  AS [Customer],
            CONVERT(VARCHAR(10), b.[OpenDate], 23)                  AS [OpenDate],
            CAST(b.[WorkScope] AS VARCHAR(100))                     AS [WorkScope],
            CAST(b.[IsWorkScopeActive] AS INT)                      AS [IsWorkScopeActive],
            -- Same labels as Work Order > Analysis > Actual vs. Quote, which shows
            -- no method when the line has no quote.
            CAST(CASE WHEN b.[HasQuote] = 0 THEN 'No Quote'
                      WHEN b.[QuoteMethodBit] = 1 THEN 'Flat Rate'
                      ELSE 'T&M' END AS VARCHAR(50))                AS [QuoteMethod],
            CAST(b.[WorkOrderStatus] AS VARCHAR(50))                AS [WorkOrderStatus],
            CAST(b.[QuoteVersion] AS INT)                           AS [QuoteVersion],
            CAST(0 AS INT)                                          AS [IsVersionIncrease],
            CAST(CASE WHEN b.[IsInvoiced] = 1 THEN 0 ELSE 1 END AS INT) AS [IsRevenueFromQuote],

            CAST(b.[QuotePartsCost]  AS DECIMAL(18,2))              AS [QuotePartsCost],
            CAST(b.[QuoteLaborCost]  AS DECIMAL(18,2))              AS [QuoteLaborCost],
            CAST(b.[QuoteOtherCost]  AS DECIMAL(18,2))              AS [QuoteOtherCost],
            CAST(b.[QuoteTotalCost]  AS DECIMAL(18,2))              AS [QuoteTotalCost],
            CAST(b.[QuoteRevenue]    AS DECIMAL(18,2))              AS [QuoteRevenue],

            CAST(b.[ActualPartsCost] AS DECIMAL(18,2))              AS [ActualPartsCost],
            CAST(b.[ActualLaborCost] AS DECIMAL(18,2))              AS [ActualLaborCost],
            CAST(b.[ActualOtherCost] AS DECIMAL(18,2))              AS [ActualOtherCost],
            CAST(b.[ActualTotalCost] AS DECIMAL(18,2))              AS [ActualTotalCost],
            CAST(CASE WHEN b.[IsInvoiced] = 1 THEN b.[InvoicedRevenue]
                      ELSE b.[QuoteRevenue] END AS DECIMAL(18,2))   AS [ActualRevenue],

            -- NOTE: PAS has no operating-site column on WorkOrder or
            -- WorkOrderPartNumber. Station is the closest equivalent.
            CAST(b.[EmployeeStation] AS VARCHAR(100))               AS [Site],
            CAST(ic.[Description] AS VARCHAR(100))                  AS [ItemClassification],
            CAST(cn.[Description] AS VARCHAR(50))                   AS [Condition],
            -- Management Structure is a 4-level hierarchy; Level1 is returned.
            CAST(b.[Level1] AS VARCHAR(150))                        AS [ManagementStructure],
            CAST(ro.[VendorName] AS VARCHAR(150))                   AS [Vendor],

            CAST(CASE
                WHEN b.[VarPct] IS NULL      THEN 'Within ' + NCHAR(177) + '5%'
                WHEN b.[VarPct] <  -0.20     THEN '> 20% Under'
                WHEN b.[VarPct] <  -0.05     THEN '5% - 20% Under'
                WHEN b.[VarPct] <=  0.05     THEN 'Within ' + NCHAR(177) + '5%'
                WHEN b.[VarPct] <=  0.20     THEN '5% - 20% Over'
                ELSE '> 20% Over'
            END AS VARCHAR(50))                                     AS [VarianceBand],
            CAST(CASE
                WHEN b.[VarPct] IS NULL      THEN 3
                WHEN b.[VarPct] <  -0.20     THEN 1
                WHEN b.[VarPct] <  -0.05     THEN 2
                WHEN b.[VarPct] <=  0.05     THEN 3
                WHEN b.[VarPct] <=  0.20     THEN 4
                ELSE 5
            END AS INT)                                             AS [VarianceBandSort]
        FROM Banded b
        LEFT JOIN [dbo].[ItemMaster] im WITH (NOLOCK)
            ON im.[ItemMasterId] = b.[ItemMasterId]
        LEFT JOIN [dbo].[ItemClassification] ic WITH (NOLOCK)
            ON ic.[ItemClassificationId] = im.[ItemClassificationId]
        LEFT JOIN [dbo].[Condition] cn WITH (NOLOCK)
            ON cn.[ConditionId] = b.[ConditionId]
        LEFT JOIN [dbo].[RepairOrder] ro WITH (NOLOCK)
            ON ro.[RepairOrderId] = b.[RepairOrderId]
        ORDER BY b.[OpenDate] DESC, b.[WorkOrderNum];

        DROP TABLE #Lines;
        DROP TABLE #PartsCost;
        DROP TABLE #Charges;
        DROP TABLE #LaborCost;
        DROP TABLE #Quote;
        DROP TABLE #Revenue;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT
        ,@DatabaseName VARCHAR(100) = db_name()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        ,@AdhocComments VARCHAR(150) = 'USP_GetPowerBIWorkOrderQuoteActual'
        ,@ProcedureParameters VARCHAR(3000) = '@masterCompanyId = ''' + CAST(ISNULL(@masterCompanyId, '') AS varchar(100))
        ,@ApplicationName VARCHAR(100) = 'PAS'
        -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException @DatabaseName = @DatabaseName
            ,@AdhocComments = @AdhocComments
            ,@ProcedureParameters = @ProcedureParameters
            ,@ApplicationName = @ApplicationName
            ,@ErrorLogID = @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
        RETURN (1);
    END CATCH
END
