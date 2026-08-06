/*************************************************************             
 ** File:   [USP_GetPowerBIWorkOrderTATReport]             
 ** Author:   SUMIT KUMAR
 ** Description: Retrieve Work Order Turnaround Time (TAT) Report Data for Power BI  
 ** Purpose:           
 ** Date:   06-AUG-2026        
            
 **************************************************************             
 ** CHANGE HISTORY:             
 **************************************************************             
 ** S NO   Date         Author           Change Description              
 ** 1      06-AUG-2026  SUMIT KUMAR      Created
 **************************************************************/  
CREATE PROCEDURE [dbo].[USP_GetPowerBIWorkOrderTATReport]   
    @mastercompanyid INT,
    @GraphDataKey VARCHAR(50) = NULL
AS  
BEGIN  
    SET NOCOUNT ON;  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
  
    -- For calculations requiring TAT, run raw sums and base queries
    IF OBJECT_ID(N'tempdb..#StageDays') IS NOT NULL  
        DROP TABLE #StageDays;  
  
    SELECT   
        WT.WorkOrderPartNoId,  
        SUM(
            CASE 
                WHEN WS.IncludeInTAT = 1 THEN 
                    CASE 
                        WHEN WT.StatusChangedEndDate IS NOT NULL THEN ISNULL(WT.[Days], 0) + (ISNULL(WT.[Hours], 0) / 24.0) + (ISNULL(WT.[Mins], 0) / 1440.0)
                        ELSE ISNULL(DATEDIFF(minute, WT.StatusChangedDate, GETUTCDATE()), 0) / 1440.0
                    END
                ELSE 0 
            END
        ) AS TatDays,  
        SUM(
            CASE 
                WHEN WS.QuoteDays = 1 THEN 
                    CASE 
                        WHEN WT.StatusChangedEndDate IS NOT NULL THEN ISNULL(WT.[Days], 0) + (ISNULL(WT.[Hours], 0) / 24.0) + (ISNULL(WT.[Mins], 0) / 1440.0)
                        ELSE ISNULL(DATEDIFF(minute, WT.StatusChangedDate, GETUTCDATE()), 0) / 1440.0
                    END
                ELSE 0 
            END
        ) AS QuoteDays  
    INTO #StageDays  
    FROM dbo.WorkOrderTurnArroundTime WT WITH (NOLOCK)  
    INNER JOIN dbo.WorkOrderStage WS WITH (NOLOCK) ON WT.CurrentStageId = WS.WorkOrderStageId  
    GROUP BY WT.WorkOrderPartNoId;  
  
    IF OBJECT_ID(N'tempdb..#AllParts') IS NOT NULL  
        DROP TABLE #AllParts;  
  
    SELECT   
        WO.WorkOrderId,  
        WOPN.ID AS WorkOrderPartNoId,  
        WO.WorkOrderNum AS WorkOrderNo,  
        C.Name AS Customer,  
        WOPN.WorkScope AS Workspace,  
        ISNULL(NULLIF(MSD.Level4Name, ''), MSD.Level3Name) AS Station,  
        CASE WHEN WOPN.IsClosed = 1 THEN 'Closed' ELSE 'Open' END AS Status,  
          
        -- Quoted TAT  
        CASE   
            WHEN ISNULL(SD.QuoteDays, 0) >= 1 THEN SD.QuoteDays  
            ELSE ISNULL(DATEDIFF(day, WOPN.ReceivedDate, WOQ.SentDate), 0)  
        END AS QuotedTat,  
          
        -- Actual TAT  
        CASE   
            WHEN ISNULL(SD.TatDays, 0) >= 1 THEN SD.TatDays  
            ELSE   
                CASE   
                    WHEN WOPN.IsClosed = 1 THEN   
                        ISNULL(DATEDIFF(day, WOPN.ReceivedDate, WOPN.closeddate),   
                        ISNULL(DATEDIFF(day, WOPN.ReceivedDate, WOBI.InvoiceDate),   
                        ISNULL(DATEDIFF(day, WOPN.ReceivedDate, WOS.ShipDate), 0)))  
                    ELSE   
                        DATEDIFF(day, WOPN.ReceivedDate, GETUTCDATE())  
                END  
        END AS ActualTat,  
          
        WOPN.ReceivedDate,  
        CASE WHEN WOPN.IsClosed = 1 THEN ISNULL(WOPN.closeddate, ISNULL(WOBI.InvoiceDate, WOS.ShipDate)) ELSE NULL END AS CompletedDate,  
        WOPN.EstimatedShipDate,  
        WOPN.IsClosed,  
        CN.Description AS Condition,  
        CASE   
            WHEN WOPN.WorkScope LIKE '%REWORK%' OR CN.Description LIKE '%REWORK%' THEN 1  
            ELSE 0  
        END AS IsRework,  
          
        -- Dynamic Target TAT from WorkOrderPartNumber  
        ISNULL(NULLIF(WOPN.TATDaysStandard, 0), 7.0) AS TargetTat  
    INTO #AllParts  
    FROM dbo.WorkOrderPartNumber WOPN WITH (NOLOCK)  
        INNER JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WOPN.WorkOrderId = WO.WorkOrderId  
        INNER JOIN dbo.Customer C WITH (NOLOCK) ON WO.CustomerId = C.CustomerId  
        INNER JOIN dbo.ItemMaster IM WITH (NOLOCK) ON WOPN.ItemMasterId = IM.ItemMasterId  
        LEFT JOIN dbo.Condition CN WITH (NOLOCK) ON WOPN.ConditionId = CN.ConditionId  
        LEFT JOIN dbo.WorkOrderQuote WOQ WITH (NOLOCK) ON WO.WorkOrderId = WOQ.WorkOrderId AND WOQ.IsVersionIncrease = 0  
        LEFT JOIN #StageDays SD ON WOPN.ID = SD.WorkOrderPartNoId  
          
        -- Shipping details  
        LEFT JOIN dbo.WorkOrderShippingItem WOSI WITH (NOLOCK) ON WOSI.WorkOrderPartNumId = WOPN.ID  
        LEFT JOIN dbo.WorkOrderShipping WOS WITH (NOLOCK) ON WOS.WorkOrderShippingId = WOSI.WorkOrderShippingId  
          
        -- Invoicing details  
        LEFT JOIN dbo.BillingInvoicingItems WBII WITH (NOLOCK) ON WBII.SubReferenceId = WOPN.ID AND WBII.ModuleId = 12 AND ISNULL(WBII.IsVersionIncrease, 0) = 0  
        LEFT JOIN dbo.BillingInvoicing WOBI WITH (NOLOCK) ON WBII.BillingInvoicingId = WOBI.BillingInvoicingId AND ISNULL(WOBI.IsVersionIncrease, 0) = 0 AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0 AND WOBI.ModuleId = 12  
          
        -- Management Structure for Station  
        LEFT JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = 12 AND MSD.ReferenceID = WOPN.ID  
    WHERE   
        WO.mastercompanyid = @mastercompanyid  
        AND WO.IsDeleted = 0   
        AND WO.IsActive = 1  
        AND WOPN.IsDeleted = 0  
        AND WOPN.IsActive = 1;  

    -- Conditionally run and return result sets based on @GraphDataKey
    
    -- WIDGET: KPIs
    IF @GraphDataKey = 'kpis'
    BEGIN
        DECLARE @AvgTatVal DECIMAL(18,2) = 0.0;  
        DECLARE @AvgTatTarget DECIMAL(18,2) = 7.0;  
        DECLARE @TatVariance DECIMAL(18,2) = 0.0;  
        DECLARE @AvgQuotedDays DECIMAL(18,2) = 0.0;  
        DECLARE @QuotedVarianceVal DECIMAL(18,2) = 0.0;  
        DECLARE @QuotedVariancePercent INT = 0;  
        DECLARE @OverdueCount INT = 0;  
        DECLARE @OpenCount INT = 0;  
        DECLARE @NonOverdueOpenCount INT = 0;  
        DECLARE @MtdClosed INT = 0;  
        DECLARE @VsLastMonthPercent INT = 0;  
  
        SELECT   
            @AvgTatVal = ISNULL(AVG(ActualTat), 0.0),  
            @AvgTatTarget = ISNULL(AVG(TargetTat), 7.0),  
            @AvgQuotedDays = ISNULL(AVG(QuotedTat), 0.0)  
        FROM #AllParts  
        WHERE IsClosed = 1;  
  
        SET @TatVariance = @AvgTatVal - @AvgTatTarget;  
        SET @QuotedVarianceVal = @AvgTatVal - @AvgQuotedDays;  
        IF @AvgQuotedDays > 0  
            SET @QuotedVariancePercent = ROUND((@QuotedVarianceVal / @AvgQuotedDays) * 100, 0);  
  
        SELECT   
            @OpenCount = COUNT(*),  
            @OverdueCount = SUM(CASE WHEN ActualTat > QuotedTat OR (EstimatedShipDate IS NOT NULL AND CAST(EstimatedShipDate AS DATE) < CAST(GETUTCDATE() AS DATE)) THEN 1 ELSE 0 END)  
        FROM #AllParts  
        WHERE IsClosed = 0;  
  
        SET @NonOverdueOpenCount = CASE WHEN @OpenCount - @OverdueCount > 0 THEN @OpenCount - @OverdueCount ELSE 0 END;  
  
        -- MTD Throughput  
        DECLARE @LatestClosedDate DATETIME;  
        SELECT @LatestClosedDate = MAX(CompletedDate) FROM #AllParts WHERE IsClosed = 1;  
  
        IF @LatestClosedDate IS NOT NULL  
        BEGIN  
            DECLARE @CurMonth INT = MONTH(@LatestClosedDate);  
            DECLARE @CurYear INT = YEAR(@LatestClosedDate);  
          
            DECLARE @PrevMonthDate DATETIME = DATEADD(month, -1, @LatestClosedDate);  
            DECLARE @PrevMonth INT = MONTH(@PrevMonthDate);  
            DECLARE @PrevYear INT = YEAR(@PrevMonthDate);  
          
            SELECT @MtdClosed = COUNT(*) FROM #AllParts WHERE IsClosed = 1 AND MONTH(CompletedDate) = @CurMonth AND YEAR(CompletedDate) = @CurYear;  
          
            DECLARE @PrevClosed INT = 0;  
            SELECT @PrevClosed = COUNT(*) FROM #AllParts WHERE IsClosed = 1 AND MONTH(CompletedDate) = @PrevMonth AND YEAR(CompletedDate) = @PrevYear;  
          
            IF @PrevClosed > 0  
                SET @VsLastMonthPercent = ROUND(((CAST(@MtdClosed AS DECIMAL(18,2)) - @PrevClosed) / @PrevClosed) * 100, 0);  
        END  
  
        SELECT   
            @AvgTatVal AS AvgTatVal,  
            @AvgTatTarget AS AvgTatTarget,  
            @TatVariance AS TatVariance,  
            @QuotedVarianceVal AS QuotedVarianceVal,  
            @QuotedVariancePercent AS QuotedVariancePercent,  
            @OverdueCount AS OverdueCount,  
            @NonOverdueOpenCount AS NonOverdueOpenCount,  
            @OpenCount AS TotalOpenCount,  
            @MtdClosed AS MtdClosed,  
            @VsLastMonthPercent AS VsLastMonthPercent;  

        DROP TABLE #StageDays;  
        DROP TABLE #AllParts;  
        RETURN;
    END

    -- WIDGET: tatTrend
    IF @GraphDataKey = 'tatTrend'
    BEGIN
        SELECT   
            CONVERT(VARCHAR(7), CompletedDate, 120) AS Month,  
            ROUND(AVG(ActualTat), 1) AS ActualAvgTat,  
            ROUND(AVG(TargetTat), 1) AS Target  
        FROM #AllParts  
        WHERE IsClosed = 1 AND CompletedDate IS NOT NULL  
        GROUP BY CONVERT(VARCHAR(7), CompletedDate, 120)  
        ORDER BY Month;  

        DROP TABLE #StageDays;  
        DROP TABLE #AllParts;  
        RETURN;
    END

    -- WIDGET: openWoAging
    IF @GraphDataKey = 'openWoAging'
    BEGIN
        SELECT '0-3d' AS Bucket, COUNT(CASE WHEN ActualTat <= 3 THEN 1 END) AS [Count] FROM #AllParts WHERE IsClosed = 0  
        UNION ALL  
        SELECT '4-7d' AS Bucket, COUNT(CASE WHEN ActualTat >= 4 AND ActualTat <= 7 THEN 1 END) AS [Count] FROM #AllParts WHERE IsClosed = 0  
        UNION ALL  
        SELECT '8-14d' AS Bucket, COUNT(CASE WHEN ActualTat >= 8 AND ActualTat <= 14 THEN 1 END) AS [Count] FROM #AllParts WHERE IsClosed = 0  
        UNION ALL  
        SELECT '15-21d' AS Bucket, COUNT(CASE WHEN ActualTat >= 15 AND ActualTat <= 21 THEN 1 END) AS [Count] FROM #AllParts WHERE IsClosed = 0  
        UNION ALL  
        SELECT '>21d' AS Bucket, COUNT(CASE WHEN ActualTat > 21 THEN 1 END) AS [Count] FROM #AllParts WHERE IsClosed = 0;  

        DROP TABLE #StageDays;  
        DROP TABLE #AllParts;  
        RETURN;
    END

    -- WIDGET: workscopeTat
    IF @GraphDataKey = 'workscopeTat'
    BEGIN
        SELECT   
            Workspace AS Workscope,  
            ROUND(AVG(ActualTat), 1) AS Actual,  
            ROUND(AVG(TargetTat), 1) AS Target,  
            ROUND(AVG(ActualTat) - AVG(TargetTat), 1) AS Variance  
        FROM #AllParts  
        WHERE IsClosed = 1 AND Workspace IS NOT NULL  
        GROUP BY Workspace  
        ORDER BY Workspace;  

        DROP TABLE #StageDays;  
        DROP TABLE #AllParts;  
        RETURN;
    END

    -- WIDGET: tatDistribution
    IF @GraphDataKey = 'tatDistribution'
    BEGIN
        SELECT DISTINCT  
            Workspace AS Workscope,  
            PERCENTILE_CONT(0.0) WITHIN GROUP (ORDER BY ActualTat) OVER (PARTITION BY Workspace) AS MinVal,  
            PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY ActualTat) OVER (PARTITION BY Workspace) AS Q1Val,  
            PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY ActualTat) OVER (PARTITION BY Workspace) AS MedianVal,  
            PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY ActualTat) OVER (PARTITION BY Workspace) AS Q3Val,  
            PERCENTILE_CONT(1.0) WITHIN GROUP (ORDER BY ActualTat) OVER (PARTITION BY Workspace) AS MaxVal  
        FROM #AllParts  
        WHERE IsClosed = 1 AND Workspace IS NOT NULL;  

        DROP TABLE #StageDays;  
        DROP TABLE #AllParts;  
        RETURN;
    END

    -- WIDGET: deliveryStatus
    IF @GraphDataKey = 'deliveryStatus'
    BEGIN
        DECLARE @DelClosedThisPeriod INT = 0;  
        SELECT @DelClosedThisPeriod = COUNT(*) FROM #AllParts WHERE IsClosed = 1;  
  
        DECLARE @DelOnTimeCount INT = 0;  
        DECLARE @DelLateUnder3 INT = 0;  
        DECLARE @DelLateOver3 INT = 0;  
        DECLARE @DelReworkCount INT = 0;  
  
        SELECT @DelReworkCount = COUNT(*) FROM #AllParts WHERE IsClosed = 1 AND IsRework = 1;  
        SELECT @DelOnTimeCount = COUNT(*) FROM #AllParts WHERE IsClosed = 1 AND IsRework = 0 AND (ActualTat - QuotedTat) <= 0;  
        SELECT @DelLateUnder3 = COUNT(*) FROM #AllParts WHERE IsClosed = 1 AND IsRework = 0 AND (ActualTat - QuotedTat) > 0 AND (ActualTat - QuotedTat) < 3;  
        SELECT @DelLateOver3 = COUNT(*) FROM #AllParts WHERE IsClosed = 1 AND IsRework = 0 AND (ActualTat - QuotedTat) >= 3;  
  
        DECLARE @DelOnTimePercent INT = 0;  
        IF @DelClosedThisPeriod > 0  
            SET @DelOnTimePercent = ROUND((CAST(@DelOnTimeCount AS DECIMAL(18,2)) / @DelClosedThisPeriod) * 100, 0);  
  
        SELECT   
            @DelClosedThisPeriod AS ClosedThisPeriod,  
            @DelOnTimePercent AS OnTimePercent,  
            'On-time' AS Status,  
            @DelOnTimeCount AS [Count]  
        UNION ALL  
        SELECT   
            @DelClosedThisPeriod AS ClosedThisPeriod,  
            @DelOnTimePercent AS OnTimePercent,  
            'Late (< 3d)' AS Status,  
            @DelLateUnder3 AS [Count]  
        UNION ALL  
        SELECT   
            @DelClosedThisPeriod AS ClosedThisPeriod,  
            @DelOnTimePercent AS OnTimePercent,  
            'Late (≥ 3d)' AS Status,  
            @DelLateOver3 AS [Count]  
        UNION ALL  
        SELECT   
            @DelClosedThisPeriod AS ClosedThisPeriod,  
            @DelOnTimePercent AS OnTimePercent,  
            'Rework' AS Status,  
            @DelReworkCount AS [Count];  

        DROP TABLE #StageDays;  
        DROP TABLE #AllParts;  
        RETURN;
    END

    -- WIDGET: workOrders
    IF @GraphDataKey = 'workOrders'
    BEGIN
        SELECT   
            WorkOrderPartNoId AS WorkOrderId,  
            WorkOrderNo,  
            Customer,  
            Workspace,  
            Station,  
            Status,  
            CAST(QuotedTat AS INT) AS QuotedTat,  
            CAST(ActualTat AS INT) AS ActualTat,  
            CONVERT(VARCHAR(10), ReceivedDate, 120) AS ReceivedDate,  
            CONVERT(VARCHAR(10), CompletedDate, 120) AS CompletedDate  
        FROM #AllParts  
        ORDER BY ReceivedDate DESC;  

        DROP TABLE #StageDays;  
        DROP TABLE #AllParts;  
        RETURN;
    END

    -- DEFAULT CASE: Return all tables (GraphDataKey is null or empty)
    IF @GraphDataKey IS NULL OR @GraphDataKey = ''
    BEGIN
        -- TABLE 0: KPIs / Summary  
        DECLARE @DefAvgTatVal DECIMAL(18,2) = 0.0;  
        DECLARE @DefAvgTatTarget DECIMAL(18,2) = 7.0;  
        DECLARE @DefTatVariance DECIMAL(18,2) = 0.0;  
        DECLARE @DefAvgQuotedDays DECIMAL(18,2) = 0.0;  
        DECLARE @DefQuotedVarianceVal DECIMAL(18,2) = 0.0;  
        DECLARE @DefQuotedVariancePercent INT = 0;  
        DECLARE @DefOverdueCount INT = 0;  
        DECLARE @DefOpenCount INT = 0;  
        DECLARE @DefNonOverdueOpenCount INT = 0;  
        DECLARE @DefMtdClosed INT = 0;  
        DECLARE @DefVsLastMonthPercent INT = 0;  
  
        SELECT   
            @DefAvgTatVal = ISNULL(AVG(ActualTat), 0.0),  
            @DefAvgTatTarget = ISNULL(AVG(TargetTat), 7.0),  
            @DefAvgQuotedDays = ISNULL(AVG(QuotedTat), 0.0)  
        FROM #AllParts  
        WHERE IsClosed = 1;  
  
        SET @DefTatVariance = @DefAvgTatVal - @DefAvgTatTarget;  
        SET @DefQuotedVarianceVal = @DefAvgTatVal - @DefAvgQuotedDays;  
        IF @DefAvgQuotedDays > 0  
            SET @DefQuotedVariancePercent = ROUND((@DefQuotedVarianceVal / @DefAvgQuotedDays) * 100, 0);  
  
        SELECT   
            @DefOpenCount = COUNT(*),  
            @DefOverdueCount = SUM(CASE WHEN ActualTat > QuotedTat OR (EstimatedShipDate IS NOT NULL AND CAST(EstimatedShipDate AS DATE) < CAST(GETUTCDATE() AS DATE)) THEN 1 ELSE 0 END)  
        FROM #AllParts  
        WHERE IsClosed = 0;  
  
        SET @DefNonOverdueOpenCount = CASE WHEN @DefOpenCount - @DefOverdueCount > 0 THEN @DefOpenCount - @DefOverdueCount ELSE 0 END;  
  
        -- MTD Throughput  
        DECLARE @DefLatestClosedDate DATETIME;  
        SELECT @DefLatestClosedDate = MAX(CompletedDate) FROM #AllParts WHERE IsClosed = 1;  
  
        IF @DefLatestClosedDate IS NOT NULL  
        BEGIN  
            DECLARE @DefCurMonth INT = MONTH(@DefLatestClosedDate);  
            DECLARE @DefCurYear INT = YEAR(@DefLatestClosedDate);  
          
            DECLARE @DefPrevMonthDate DATETIME = DATEADD(month, -1, @DefLatestClosedDate);  
            DECLARE @DefPrevMonth INT = MONTH(@DefPrevMonthDate);  
            DECLARE @DefPrevYear INT = YEAR(@DefPrevMonthDate);  
          
            SELECT @DefMtdClosed = COUNT(*) FROM #AllParts WHERE IsClosed = 1 AND MONTH(CompletedDate) = @DefCurMonth AND YEAR(CompletedDate) = @DefCurYear;  
          
            DECLARE @DefPrevClosed INT = 0;  
            SELECT @DefPrevClosed = COUNT(*) FROM #AllParts WHERE IsClosed = 1 AND MONTH(CompletedDate) = @DefPrevMonth AND YEAR(CompletedDate) = @DefPrevYear;  
          
            IF @DefPrevClosed > 0  
                SET @DefVsLastMonthPercent = ROUND(((CAST(@DefMtdClosed AS DECIMAL(18,2)) - @DefPrevClosed) / @DefPrevClosed) * 100, 0);  
        END  
  
        SELECT   
            @DefAvgTatVal AS AvgTatVal,  
            @DefAvgTatTarget AS AvgTatTarget,  
            @DefTatVariance AS TatVariance,  
            @DefQuotedVarianceVal AS QuotedVarianceVal,  
            @DefQuotedVariancePercent AS QuotedVariancePercent,  
            @DefOverdueCount AS OverdueCount,  
            @DefNonOverdueOpenCount AS NonOverdueOpenCount,  
            @DefOpenCount AS TotalOpenCount,  
            @DefMtdClosed AS MtdClosed,  
            @DefVsLastMonthPercent AS VsLastMonthPercent;  
  
        -- TABLE 1: Monthly TAT Trend  
        SELECT   
            CONVERT(VARCHAR(7), CompletedDate, 120) AS Month,  
            ROUND(AVG(ActualTat), 1) AS ActualAvgTat,  
            ROUND(AVG(TargetTat), 1) AS Target  
        FROM #AllParts  
        WHERE IsClosed = 1 AND CompletedDate IS NOT NULL  
        GROUP BY CONVERT(VARCHAR(7), CompletedDate, 120)  
        ORDER BY Month;  
  
        -- TABLE 2: Open WO Aging  
        SELECT '0-3d' AS Bucket, COUNT(CASE WHEN ActualTat <= 3 THEN 1 END) AS [Count] FROM #AllParts WHERE IsClosed = 0  
        UNION ALL  
        SELECT '4-7d' AS Bucket, COUNT(CASE WHEN ActualTat >= 4 AND ActualTat <= 7 THEN 1 END) AS [Count] FROM #AllParts WHERE IsClosed = 0  
        UNION ALL  
        SELECT '8-14d' AS Bucket, COUNT(CASE WHEN ActualTat >= 8 AND ActualTat <= 14 THEN 1 END) AS [Count] FROM #AllParts WHERE IsClosed = 0  
        UNION ALL  
        SELECT '15-21d' AS Bucket, COUNT(CASE WHEN ActualTat >= 15 AND ActualTat <= 21 THEN 1 END) AS [Count] FROM #AllParts WHERE IsClosed = 0  
        UNION ALL  
        SELECT '>21d' AS Bucket, COUNT(CASE WHEN ActualTat > 21 THEN 1 END) AS [Count] FROM #AllParts WHERE IsClosed = 0;  
  
        -- TABLE 3: Workscope TAT  
        SELECT   
            Workspace AS Workscope,  
            ROUND(AVG(ActualTat), 1) AS Actual,  
            ROUND(AVG(TargetTat), 1) AS Target,  
            ROUND(AVG(ActualTat) - AVG(TargetTat), 1) AS Variance  
        FROM #AllParts  
        WHERE IsClosed = 1 AND Workspace IS NOT NULL  
        GROUP BY Workspace  
        ORDER BY Workspace;  
  
        -- TABLE 4: TAT Distribution (Quartiles)  
        SELECT DISTINCT  
            Workspace AS Workscope,  
            PERCENTILE_CONT(0.0) WITHIN GROUP (ORDER BY ActualTat) OVER (PARTITION BY Workspace) AS MinVal,  
            PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY ActualTat) OVER (PARTITION BY Workspace) AS Q1Val,  
            PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY ActualTat) OVER (PARTITION BY Workspace) AS MedianVal,  
            PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY ActualTat) OVER (PARTITION BY Workspace) AS Q3Val,  
            PERCENTILE_CONT(1.0) WITHIN GROUP (ORDER BY ActualTat) OVER (PARTITION BY Workspace) AS MaxVal  
        FROM #AllParts  
        WHERE IsClosed = 1 AND Workspace IS NOT NULL;  
  
        -- TABLE 5: Delivery Status Breakdown  
        DECLARE @AllClosedThisPeriod INT = 0;  
        SELECT @AllClosedThisPeriod = COUNT(*) FROM #AllParts WHERE IsClosed = 1;  
  
        DECLARE @AllOnTimeCount INT = 0;  
        DECLARE @AllLateUnder3 INT = 0;  
        DECLARE @AllLateOver3 INT = 0;  
        DECLARE @AllReworkCount INT = 0;  
  
        SELECT @AllReworkCount = COUNT(*) FROM #AllParts WHERE IsClosed = 1 AND IsRework = 1;  
        SELECT @AllOnTimeCount = COUNT(*) FROM #AllParts WHERE IsClosed = 1 AND IsRework = 0 AND (ActualTat - QuotedTat) <= 0;  
        SELECT @AllLateUnder3 = COUNT(*) FROM #AllParts WHERE IsClosed = 1 AND IsRework = 0 AND (ActualTat - QuotedTat) > 0 AND (ActualTat - QuotedTat) < 3;  
        SELECT @AllLateOver3 = COUNT(*) FROM #AllParts WHERE IsClosed = 1 AND IsRework = 0 AND (ActualTat - QuotedTat) >= 3;  
  
        DECLARE @AllOnTimePercent INT = 0;  
        IF @AllClosedThisPeriod > 0  
            SET @AllOnTimePercent = ROUND((CAST(@AllOnTimeCount AS DECIMAL(18,2)) / @AllClosedThisPeriod) * 100, 0);  
  
        SELECT   
            @AllClosedThisPeriod AS ClosedThisPeriod,  
            @AllOnTimePercent AS OnTimePercent,  
            'On-time' AS Status,  
            @AllOnTimeCount AS [Count]  
        UNION ALL  
        SELECT   
            @AllClosedThisPeriod AS ClosedThisPeriod,  
            @AllOnTimePercent AS OnTimePercent,  
            'Late (< 3d)' AS Status,  
            @AllLateUnder3 AS [Count]  
        UNION ALL  
        SELECT   
            @AllClosedThisPeriod AS ClosedThisPeriod,  
            @AllOnTimePercent AS OnTimePercent,  
            'Late (≥ 3d)' AS Status,  
            @AllLateOver3 AS [Count]  
        UNION ALL  
        SELECT   
            @AllClosedThisPeriod AS ClosedThisPeriod,  
            @AllOnTimePercent AS OnTimePercent,  
            'Rework' AS Status,  
            @AllReworkCount AS [Count];  
  
        -- TABLE 6: Work Orders Details List  
        SELECT   
            WorkOrderPartNoId AS WorkOrderId,  
            WorkOrderNo,  
            Customer,  
            Workspace,  
            Station,  
            Status,  
            CAST(QuotedTat AS INT) AS QuotedTat,  
            CAST(ActualTat AS INT) AS ActualTat,  
            CONVERT(VARCHAR(10), ReceivedDate, 120) AS ReceivedDate,  
            CONVERT(VARCHAR(10), CompletedDate, 120) AS CompletedDate  
        FROM #AllParts  
        ORDER BY ReceivedDate DESC;  

        DROP TABLE #StageDays;  
        DROP TABLE #AllParts;  
    END  
END  
GO
