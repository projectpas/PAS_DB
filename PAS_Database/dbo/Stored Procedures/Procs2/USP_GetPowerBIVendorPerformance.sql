/*************************************************************             
 ** File:   [USP_GetPowerBIVendorPerformance]             
 ** Author:   SUMIT KUMAR
 ** Description: Retrieve Vendor Performance & Utilization Data for Power BI Reports  
 ** Purpose: Calculates Vendor Delivery, Quality, Cost Scorecard Metrics and returns receipt facts  
 ** Date:   30-SEP-2026        
 **************************************************************             
 ** CHANGE HISTORY:             
 **************************************************************             
 ** S NO   Date         Author           Change Description              
 ** 1      30-SEP-2026  SUMIT KUMAR      Created
 **************************************************************/  
CREATE PROCEDURE [dbo].[USP_GetPowerBIVendorPerformance]   
    @masterCompanyId INT
AS  
BEGIN  
    SET NOCOUNT ON;  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  

    BEGIN TRY
        ----------------------------------------------------------------------------------
        -- 1. Temp Table: #VendorStats
        -- Aggregates raw vendor performance metrics across all valid receipt lines:
        --   - OtdRate: Ratio of receipts delivered on/before PO NeedByDate.
        --   - OtifRate: Ratio of receipts delivered on-time AND in-full quantity.
        --   - RejectionRate: Total rejected quantity divided by total received quantity.
        --   - RmaLineRate: RMA Return-to-Vendor line count divided by total receipt lines.
        --   - InspectionFailRate: Share of inspected receipts having >=1 failed check.
        --   - TotalSpend: Total extended spend ($) based on PO Unit Cost.
        --   - TotalPPV: Total Purchase Price Variance ($) vs Item Standard Purchase Price.
        ----------------------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#VendorStats') IS NOT NULL  
            DROP TABLE #VendorStats;

        SELECT 
            v.VendorId,
            
            -- On-Time Delivery Rate: Receipts received on or before promised NeedByDate
            CAST(SUM(CASE WHEN stl.ReceivedDate <= pop.NeedByDate THEN 1 ELSE 0 END) * 1.0 
                 / NULLIF(COUNT(stl.StockLineId), 0) AS DECIMAL(9,6)) AS OtdRate,
            
            -- On-Time In-Full (OTIF) Rate: Receipts delivered on-time AND with received quantity >= ordered quantity
            CAST(SUM(CASE WHEN stl.ReceivedDate <= pop.NeedByDate 
                               AND ISNULL(stl.QuantityToReceive, stl.QuantityOnHand) >= pop.QuantityOrdered THEN 1 ELSE 0 END) * 1.0 
                 / NULLIF(COUNT(stl.StockLineId), 0) AS DECIMAL(9,6)) AS OtifRate,
            
            -- Rejection Rate: Total quantity rejected divided by total received quantity
            CAST(SUM(ISNULL(stl.QuantityRejected, 0)) * 1.0 
                 / NULLIF(SUM(ISNULL(stl.QuantityToReceive, stl.QuantityOnHand)), 0) AS DECIMAL(9,6)) AS RejectionRate,
            
            -- RMA Return-to-Vendor Line Rate: RMA lines count divided by receipt lines count
            CAST(COUNT(DISTINCT rmad.VendorRMADetailId) * 1.0 
                 / NULLIF(COUNT(stl.StockLineId), 0) AS DECIMAL(9,6)) AS RmaLineRate,
            
            -- Inspection Failure Rate: Proportion of receipts that failed 1 or more of the 12 inspection checklist items
            CAST(SUM(CASE WHEN (
                CASE WHEN ri.ReceivingInspectionId IS NOT NULL THEN
                    (CASE WHEN ri.PartNumber = 0 THEN 1 ELSE 0 END + 
                     CASE WHEN ri.SerialNum = 0 THEN 1 ELSE 0 END + 
                     CASE WHEN ri.Condition = 0 THEN 1 ELSE 0 END + 
                     CASE WHEN ri.Qty = 0 THEN 1 ELSE 0 END + 
                     CASE WHEN ri.ShelfLife = 0 THEN 1 ELSE 0 END + 
                     CASE WHEN ri.LotBatchNum = 0 THEN 1 ELSE 0 END + 
                     CASE WHEN ri.GeneralVisualInspection = 0 THEN 1 ELSE 0 END + 
                     CASE WHEN ri.AppropriatePackaging = 0 THEN 1 ELSE 0 END + 
                     CASE WHEN ri.ESDCapsandPackaging = 0 THEN 1 ELSE 0 END + 
                     CASE WHEN ri.HazardousMaterial = 0 THEN 1 ELSE 0 END + 
                     CASE WHEN ri.MeetsPORequirements = 0 THEN 1 ELSE 0 END + 
                     CASE WHEN ri.CompletePaperwork = 0 THEN 1 ELSE 0 END)
                ELSE 0 END
            ) > 0 THEN 1 ELSE 0 END) * 1.0 
                 / NULLIF(COUNT(ri.ReceivingInspectionId), 0) AS DECIMAL(9,6)) AS InspectionFailRate,
            
            -- Total Spend Amount: Extended cost calculated as (Received Qty * PO Line Unit Cost)
            SUM(ISNULL(stl.QuantityToReceive, stl.QuantityOnHand) * ISNULL(pop.UnitCost, 0)) AS TotalSpend,
            
            -- Purchase Price Variance (PPV): Difference between PO Unit Cost and Item Standard Purchase Price
            SUM((ISNULL(pop.UnitCost, 0) - ISNULL(imps.PP_UnitPurchasePrice, pop.UnitCost)) 
                * ISNULL(stl.QuantityToReceive, stl.QuantityOnHand)) AS TotalPPV
        INTO #VendorStats
        FROM dbo.Stockline stl WITH (NOLOCK)
        INNER JOIN dbo.PurchaseOrderPart pop WITH (NOLOCK) ON stl.PurchaseOrderPartRecordId = pop.PurchaseOrderPartRecordId
        INNER JOIN dbo.PurchaseOrder po WITH (NOLOCK) ON stl.PurchaseOrderId = po.PurchaseOrderId
        INNER JOIN dbo.Vendor v WITH (NOLOCK) ON stl.VendorId = v.VendorId
        LEFT JOIN dbo.ItemMasterPurchaseSale imps WITH (NOLOCK) ON pop.ItemMasterId = imps.ItemMasterId AND stl.ConditionId = imps.ConditionId AND imps.MasterCompanyId = @masterCompanyId
        LEFT JOIN dbo.ReceivingInspection ri WITH (NOLOCK) ON stl.StockLineId = ri.StockLineId
        LEFT JOIN dbo.VendorRMADetail rmad WITH (NOLOCK) ON stl.StockLineId = rmad.StockLineId
        WHERE stl.MasterCompanyId = @masterCompanyId
          AND ISNULL(stl.IsDeleted, 0) = 0
          AND ISNULL(stl.IsParent, 1) = 1
          AND stl.ReceivedDate IS NOT NULL
        GROUP BY v.VendorId;

        ----------------------------------------------------------------------------------
        -- 2. Temp Table: #VendorScores
        -- Computes the three Weighted Scorecard Pillar Segments (Max Total = 100 points):
        --   1. Delivery Score (Max 40 points): 60% OTD + 40% OTIF
        --   2. Quality Score (Max 40 points): 50% Rejection Rate + 30% RMA Rate + 20% Inspection Fail Rate
        --      (Penalties scale linearly up to business ceilings: 5% Rejection, 10% RMA, 15% Inspection Fail)
        --   3. Cost Score (Max 20 points): Evaluated on unfavourable Purchase Price Variance (PPV % of Spend)
        --      (Penalty scales linearly up to a 5% unfavourable variance ceiling)
        ----------------------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#VendorScores') IS NOT NULL  
            DROP TABLE #VendorScores;

        SELECT 
            VendorId,
            
            -- Delivery Score (Weight: 40% / Max 40 pts)
            CAST(40.0 * (0.60 * ISNULL(OtdRate, 0) + 0.40 * ISNULL(OtifRate, 0)) AS DECIMAL(5,2)) AS DeliveryScore,
            
            -- Quality Score (Weight: 40% / Max 40 pts)
            CAST(40.0 * (
                0.50 * (1.0 - CASE WHEN (ISNULL(RejectionRate, 0) / 0.05) > 1.0 THEN 1.0 ELSE (ISNULL(RejectionRate, 0) / 0.05) END) +
                0.30 * (1.0 - CASE WHEN (ISNULL(RmaLineRate, 0) / 0.10) > 1.0 THEN 1.0 ELSE (ISNULL(RmaLineRate, 0) / 0.10) END) +
                0.20 * (1.0 - CASE WHEN (ISNULL(InspectionFailRate, 0) / 0.15) > 1.0 THEN 1.0 ELSE (ISNULL(InspectionFailRate, 0) / 0.15) END)
            ) AS DECIMAL(5,2)) AS QualityScore,
            
            -- Cost Score (Weight: 20% / Max 20 pts)
            CAST(20.0 * (1.0 - CASE WHEN TotalSpend > 0 AND TotalPPV > 0 THEN 
                CASE WHEN ((TotalPPV / TotalSpend) / 0.05) > 1.0 THEN 1.0 ELSE ((TotalPPV / TotalSpend) / 0.05) END
                ELSE 0.0 END) AS DECIMAL(5,2)) AS CostScore
        INTO #VendorScores
        FROM #VendorStats;

        ----------------------------------------------------------------------------------
        -- 3. Temp Table: #VendorScorecard
        -- Combines segment scores into Composite Score (0-100) and assigns Rating Tier:
        --   - Preferred: Composite Score >= 85
        --   - Approved:  Composite Score 70 - 84
        --   - At Risk:   Composite Score < 70
        ----------------------------------------------------------------------------------
        IF OBJECT_ID(N'tempdb..#VendorScorecard') IS NOT NULL  
            DROP TABLE #VendorScorecard;

        SELECT 
            s.VendorId,
            s.DeliveryScore,
            s.QualityScore,
            s.CostScore,
            CAST(s.DeliveryScore + s.QualityScore + s.CostScore AS DECIMAL(5,2)) AS CompositeScore,
            CASE 
                WHEN (s.DeliveryScore + s.QualityScore + s.CostScore) >= 85.0 THEN 'Preferred'
                WHEN (s.DeliveryScore + s.QualityScore + s.CostScore) >= 70.0 THEN 'Approved'
                ELSE 'At Risk'
            END AS RatingTier
        INTO #VendorScorecard
        FROM #VendorScores s;

        ----------------------------------------------------------------------------------
        -- 4. Main Result Set Selection
        -- Selects flattened receipt lines mapped directly to PAS_VendorPerformance_API_Schema.md
        -- Fields categorized for Power BI visual consumption:
        --   - period: Dynamic age classification ('Last 45 days', 'Last 90 days', etc.)
        --   - leadTimeDays: Actual lead time (PO Open Date to Received Date)
        --   - expectedLeadTimeDays: Contracted lead time (PO Open Date to NeedByDate)
        --   - inspectionFailCount & inspectionFailureType: Checklist checks breakdown
        --   - purchasePriceVariance & invoicePriceVariance: PPV and AP Invoice Variances
        --   - deliveryDelayStatus: Early, On time, or Late delivery status
        ----------------------------------------------------------------------------------
        SELECT 
            stl.StockLineId                                            AS [recordId],
            
            -- Dynamic Period Categorization based on age of receipt
            CASE 
                WHEN DATEDIFF(day, stl.ReceivedDate, GETUTCDATE()) <= 45 THEN 'Last 45 days'
                WHEN DATEDIFF(day, stl.ReceivedDate, GETUTCDATE()) <= 90 THEN 'Last 90 days'
                WHEN DATEDIFF(day, stl.ReceivedDate, GETUTCDATE()) <= 180 THEN 'Last 180 days'
                ELSE 'Last 180+ days'
            END                                                        AS [period],
            
            CONVERT(VARCHAR(10), stl.ReceivedDate, 120)                AS [receiptDate],
            FORMAT(stl.ReceivedDate, 'MMM yyyy')                       AS [monthYear],
            ISNULL(v.VendorName, '')                                   AS [vendor],
            ISNULL(s.Name, ISNULL(stl.Site, ''))                       AS [site],
            ISNULL(ms.Name, '')                                        AS [managementStructure],
            ISNULL(po.Requisitioner, '')                               AS [requestedBy],
            ISNULL(ic.Description, ISNULL(im.ItemClassificationName, '')) AS [itemClassification],
            ISNULL(c.Description, ISNULL(stl.Condition, ''))           AS [condition],
            ISNULL(im.PartNumber, ISNULL(pop.PartNumber, ''))          AS [partNumber],
            ISNULL(po.PurchaseOrderNumber, '')                         AS [poNumber],
            
            -- Scorecard Metrics from #VendorScorecard
            CAST(ISNULL(vsc.DeliveryScore, 40.0) AS DECIMAL(5,2))      AS [deliveryScore],
            CAST(ISNULL(vsc.QualityScore, 40.0) AS DECIMAL(5,2))       AS [qualityScore],
            CAST(ISNULL(vsc.CostScore, 20.0) AS DECIMAL(5,2))          AS [costScore],
            CAST(ISNULL(vsc.CompositeScore, 100.0) AS DECIMAL(5,2))    AS [compositeScore],
            ISNULL(vsc.RatingTier, 'Preferred')                        AS [ratingTier],
            
            -- Spend & Delivery Performance Flags
            CAST(ISNULL(stl.QuantityToReceive, stl.QuantityOnHand) * ISNULL(pop.UnitCost, 0) AS DECIMAL(18,2)) AS [spendAmount],
            CAST(CASE WHEN stl.ReceivedDate <= pop.NeedByDate THEN 1 ELSE 0 END AS INT) AS [isOnTime],
            CAST(CASE WHEN stl.ReceivedDate <= pop.NeedByDate AND ISNULL(stl.QuantityToReceive, stl.QuantityOnHand) >= pop.QuantityOrdered THEN 1 ELSE 0 END AS INT) AS [isOTIF],
            
            -- Lead Times in Days
            CAST(DATEDIFF(day, po.OpenDate, stl.ReceivedDate) AS DECIMAL(10,2)) AS [leadTimeDays],
            CAST(DATEDIFF(day, po.OpenDate, pop.NeedByDate) AS DECIMAL(10,2)) AS [expectedLeadTimeDays],
            
            -- Quantities & RMA Returns
            CAST(ISNULL(stl.QuantityToReceive, stl.QuantityOnHand) AS INT) AS [quantityReceived],
            CAST(ISNULL(stl.QuantityRejected, 0) AS INT)              AS [quantityRejected],
            CAST(CASE WHEN rmad.VendorRMADetailId IS NOT NULL THEN 1 ELSE 0 END AS INT) AS [rmaLineCount],
            CAST(ISNULL(rmad.ExtendedCost, 0) AS DECIMAL(18,2))        AS [rmaValue],
            
            -- Inspection Checklist Failure Count (Sum of 12 checklist check failures)
            CAST(CASE WHEN ri.ReceivingInspectionId IS NOT NULL THEN 
                (CASE WHEN ri.PartNumber = 0 THEN 1 ELSE 0 END + 
                 CASE WHEN ri.SerialNum = 0 THEN 1 ELSE 0 END + 
                 CASE WHEN ri.Condition = 0 THEN 1 ELSE 0 END + 
                 CASE WHEN ri.Qty = 0 THEN 1 ELSE 0 END + 
                 CASE WHEN ri.ShelfLife = 0 THEN 1 ELSE 0 END + 
                 CASE WHEN ri.LotBatchNum = 0 THEN 1 ELSE 0 END + 
                 CASE WHEN ri.GeneralVisualInspection = 0 THEN 1 ELSE 0 END + 
                 CASE WHEN ri.AppropriatePackaging = 0 THEN 1 ELSE 0 END + 
                 CASE WHEN ri.ESDCapsandPackaging = 0 THEN 1 ELSE 0 END + 
                 CASE WHEN ri.HazardousMaterial = 0 THEN 1 ELSE 0 END + 
                 CASE WHEN ri.MeetsPORequirements = 0 THEN 1 ELSE 0 END + 
                 CASE WHEN ri.CompletePaperwork = 0 THEN 1 ELSE 0 END)
            ELSE 0 END AS INT)                                         AS [inspectionFailCount],
            
            -- Price Variances: PPV (PO Cost vs Standard Price) and IPV (AP Invoice vs PO Cost)
            CAST((ISNULL(pop.UnitCost, 0) - ISNULL(imps.PP_UnitPurchasePrice, pop.UnitCost)) 
                 * ISNULL(stl.QuantityToReceive, stl.QuantityOnHand) AS DECIMAL(18,2)) AS [purchasePriceVariance],
            CAST(ISNULL(rrd.PriceVariance, 0) AS DECIMAL(18,2))        AS [invoicePriceVariance],
            
            -- Primary Inspection Failure Classification
            CASE WHEN ri.ReceivingInspectionId IS NOT NULL THEN
                CASE 
                    WHEN ri.CompletePaperwork = 0 THEN 'Paperwork'
                    WHEN ri.AppropriatePackaging = 0 OR ri.ESDCapsandPackaging = 0 THEN 'Packaging'
                    WHEN ri.GeneralVisualInspection = 0 THEN 'Visual'
                    WHEN ri.MeetsPORequirements = 0 THEN 'PO Requirements'
                    WHEN ri.PartNumber = 0 OR ri.SerialNum = 0 THEN 'Part/Serial Mismatch'
                    WHEN ri.Condition = 0 THEN 'Condition'
                    WHEN ri.Qty = 0 THEN 'Quantity Mismatch'
                    WHEN ri.ShelfLife = 0 THEN 'Shelf Life'
                    WHEN ri.LotBatchNum = 0 THEN 'Lot/Batch Num'
                    WHEN ri.HazardousMaterial = 0 THEN 'Hazmat Packaging'
                    ELSE 'None'
                END
            ELSE 'None' END                                            AS [inspectionFailureType],
            
            ISNULL(rmar.Reason, 'None')                                AS [returnReason],
            
            -- Delivery Timing Classification
            CASE 
                WHEN DATEDIFF(day, pop.NeedByDate, stl.ReceivedDate) < 0 THEN 'Early'
                WHEN DATEDIFF(day, pop.NeedByDate, stl.ReceivedDate) = 0 THEN 'On time'
                ELSE 'Late'
            END                                                        AS [deliveryDelayStatus]
        FROM dbo.Stockline stl WITH (NOLOCK)
        INNER JOIN dbo.PurchaseOrderPart pop WITH (NOLOCK) ON stl.PurchaseOrderPartRecordId = pop.PurchaseOrderPartRecordId
        INNER JOIN dbo.PurchaseOrder po WITH (NOLOCK) ON stl.PurchaseOrderId = po.PurchaseOrderId
        INNER JOIN dbo.Vendor v WITH (NOLOCK) ON stl.VendorId = v.VendorId
        LEFT JOIN dbo.ItemMaster im WITH (NOLOCK) ON pop.ItemMasterId = im.ItemMasterId
        LEFT JOIN dbo.ItemClassification ic WITH (NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
        LEFT JOIN dbo.Condition c WITH (NOLOCK) ON stl.ConditionId = c.ConditionId
        LEFT JOIN dbo.Site s WITH (NOLOCK) ON stl.SiteId = s.SiteId
        LEFT JOIN dbo.ManagementStructure ms WITH (NOLOCK) ON po.ManagementStructureId = ms.ManagementStructureId
        LEFT JOIN dbo.ItemMasterPurchaseSale imps WITH (NOLOCK) ON pop.ItemMasterId = imps.ItemMasterId AND stl.ConditionId = imps.ConditionId AND imps.MasterCompanyId = @masterCompanyId
        LEFT JOIN dbo.ReceivingInspection ri WITH (NOLOCK) ON stl.StockLineId = ri.StockLineId
        LEFT JOIN dbo.VendorRMADetail rmad WITH (NOLOCK) ON stl.StockLineId = rmad.StockLineId
        LEFT JOIN dbo.VendorRMAReturnReason rmar WITH (NOLOCK) ON rmad.VendorRMAReturnReasonId = rmar.VendorRMAReturnReasonId
        LEFT JOIN dbo.ReceivingReconciliationDetails rrd WITH (NOLOCK) ON stl.StockLineId = rrd.StockLineId
        LEFT JOIN dbo.ReceivingReconciliationHeader rrh WITH (NOLOCK) ON rrd.ReceivingReconciliationId = rrh.ReceivingReconciliationId AND rrh.MasterCompanyId = @masterCompanyId
        LEFT JOIN #VendorScorecard vsc ON v.VendorId = vsc.VendorId
        WHERE stl.MasterCompanyId = @masterCompanyId
          AND ISNULL(stl.IsDeleted, 0) = 0
          AND ISNULL(stl.IsParent, 1) = 1
          AND stl.ReceivedDate IS NOT NULL
        ORDER BY stl.ReceivedDate DESC, stl.StockLineId DESC;

        -- Clean up temp tables
        IF OBJECT_ID(N'tempdb..#VendorStats') IS NOT NULL DROP TABLE #VendorStats;
        IF OBJECT_ID(N'tempdb..#VendorScores') IS NOT NULL DROP TABLE #VendorScores;
        IF OBJECT_ID(N'tempdb..#VendorScorecard') IS NOT NULL DROP TABLE #VendorScorecard;

    END TRY    
    BEGIN CATCH
        DECLARE @ErrorLogID INT
        ,@DatabaseName VARCHAR(100) = db_name()
        ,@AdhocComments VARCHAR(150) = 'USP_GetPowerBIVendorPerformance'
        ,@ProcedureParameters VARCHAR(3000) = '@masterCompanyId = ''' + CAST(ISNULL(@masterCompanyId, '') AS varchar(100))
        ,@ApplicationName VARCHAR(100) = 'PAS';
        
        EXEC spLogException @DatabaseName = @DatabaseName
            ,@AdhocComments = @AdhocComments
            ,@ProcedureParameters = @ProcedureParameters
            ,@ApplicationName = @ApplicationName
            ,@ErrorLogID = @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);
        RETURN (1);           
    END CATCH
END
GO
