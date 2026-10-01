/*************************************************************             
 ** File:   [USP_GetPowerBIPartsAvailabilityAndStockout]             
 ** Author:   SUMIT KUMAR
 ** Description: Retrieve Parts Availability & Stockout Metrics for Power BI Reports  
 ** Purpose:           
 ** Date:   25-SEP-2026        
 **************************************************************             
 ** CHANGE HISTORY:             
 **************************************************************             
 ** S NO   Date         Author           Change Description              
 ** 1      25-SEP-2026  SUMIT KUMAR      Created
 **************************************************************/  
CREATE PROCEDURE [dbo].[USP_GetPowerBIPartsAvailabilityAndStockout]   
    @masterCompanyId INT
AS  
BEGIN  
    SET NOCOUNT ON;  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  

    BEGIN TRY
        -- 1. Temp Table for Stockline Inventory
        IF OBJECT_ID(N'tempdb..#StocklineInv') IS NOT NULL  
            DROP TABLE #StocklineInv;

        SELECT 
            stl.ItemMasterId,
            stl.SiteId,
            stl.ConditionId,
            stl.VendorId,
            SUM(ISNULL(stl.QuantityOnHand, 0)) AS OnHandQty,
            SUM(ISNULL(stl.QuantityReserved, 0)) AS AllocatedQty,
            SUM(CASE WHEN UPPER(c.Code) = 'AR' OR UPPER(c.Description) LIKE '%QUARANTINE%' OR UPPER(c.Description) LIKE '%AS-REMOVED%' THEN ISNULL(stl.QuantityOnHand, 0) ELSE 0 END) AS QtyOnAR,
            SUM(ISNULL(stl.QuantityAvailable, 0)) AS AvailableQty,
            MAX(stl.Site) AS SiteName,
            MAX(stl.Condition) AS ConditionName,
            MAX(v.VendorName) AS VendorName
        INTO #StocklineInv
        FROM dbo.Stockline stl WITH (NOLOCK)
        LEFT JOIN dbo.Condition c WITH (NOLOCK) ON stl.ConditionId = c.ConditionId
        LEFT JOIN dbo.Vendor v WITH (NOLOCK) ON stl.VendorId = v.VendorId
        WHERE stl.MasterCompanyId = @masterCompanyId
          AND ISNULL(stl.IsDeleted, 0) = 0
          AND ISNULL(stl.IsParent, 1) = 1
        GROUP BY stl.ItemMasterId, stl.SiteId, stl.ConditionId, stl.VendorId;

        -- 2. Temp Table for 90-day Daily Burn Rate
        IF OBJECT_ID(N'tempdb..#DailyBurn') IS NOT NULL  
            DROP TABLE #DailyBurn;

        SELECT 
            stl.ItemMasterId,
            CAST(SUM(ISNULL(stl.QuantityIssued, 0)) / 90.0 AS FLOAT) AS DailyBurnRate
        INTO #DailyBurn
        FROM dbo.Stockline stl WITH (NOLOCK)
        WHERE stl.MasterCompanyId = @masterCompanyId
          AND ISNULL(stl.IsDeleted, 0) = 0
          AND stl.CreatedDate >= DATEADD(day, -90, GETUTCDATE())
        GROUP BY stl.ItemMasterId;

        -- 3. Temp Table for Open Demand & AOG Status
        IF OBJECT_ID(N'tempdb..#OpenDemand') IS NOT NULL  
            DROP TABLE #OpenDemand;

        SELECT 
            wom.ItemMasterId,
            SUM(ISNULL(wom.UnIssuedQty, 0)) AS OpenDemandQty,
            MAX(CASE WHEN UPPER(p.Description) = 'AOG' OR UPPER(wop.Priority) = 'AOG' THEN 1 ELSE 0 END) AS IsAOG
        INTO #OpenDemand
        FROM dbo.WorkOrderMaterials wom WITH (NOLOCK)
        INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) ON wom.WorkOrderId = wo.WorkOrderId
        LEFT JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) ON wom.WorkOrderId = wop.WorkOrderId AND wom.ItemMasterId = wop.ItemMasterId
        LEFT JOIN dbo.Priority p WITH (NOLOCK) ON wop.WorkOrderPriorityId = p.PriorityId
        LEFT JOIN dbo.WorkOrderStatus wos WITH (NOLOCK) ON wo.WorkOrderStatusId = wos.Id
        WHERE wom.MasterCompanyId = @masterCompanyId
          AND ISNULL(wom.IsDeleted, 0) = 0
          AND ISNULL(wom.IsActive, 1) = 1
          AND ISNULL(wop.IsClosed, 0) = 0
          AND UPPER(ISNULL(wos.StatusCode, '')) <> 'CLOSED'
        GROUP BY wom.ItemMasterId;

        -- 4. Temp Table for Open Purchase Orders / Backorders
        IF OBJECT_ID(N'tempdb..#OpenPO') IS NOT NULL  
            DROP TABLE #OpenPO;

        SELECT 
            pop.ItemMasterId,
            COUNT(pop.PurchaseOrderPartRecordId) AS BackorderLineCount,
            SUM((ISNULL(pop.QuantityOrdered, 0) - ISNULL(pop.QuantityReceived, 0)) * ISNULL(pop.UnitCost, 0)) AS BackorderValue,
            MAX(DATEDIFF(day, pop.EstDeliveryDate, GETUTCDATE())) AS MaxOverdueDays,
            AVG(CAST(DATEDIFF(day, po.OpenDate, pop.EstDeliveryDate) AS FLOAT)) AS AvgPromisedLeadTime
        INTO #OpenPO
        FROM dbo.PurchaseOrderPart pop WITH (NOLOCK)
        INNER JOIN dbo.PurchaseOrder po WITH (NOLOCK) ON pop.PurchaseOrderId = po.PurchaseOrderId
        WHERE po.MasterCompanyId = @masterCompanyId
          AND ISNULL(pop.IsDeleted, 0) = 0
          AND ISNULL(po.IsDeleted, 0) = 0
          AND UPPER(ISNULL(po.Status, '')) <> 'CLOSED'
        AND pop.QuantityOrdered > ISNULL(pop.QuantityReceived, 0)
        GROUP BY pop.ItemMasterId;

        -- 5. Temp Table for Vendor Scorecard (Rolling 90-day OTD & Lead Time)
        IF OBJECT_ID(N'tempdb..#VendorScorecard') IS NOT NULL  
            DROP TABLE #VendorScorecard;

        SELECT 
            stl.VendorId,
            AVG(CAST(DATEDIFF(day, po.OpenDate, stl.ReceivedDate) AS FLOAT)) AS ActualLeadTimeDays,
            CAST(SUM(CASE WHEN stl.ReceivedDate <= pop.EstDeliveryDate THEN 1 ELSE 0 END) AS FLOAT) / NULLIF(COUNT(stl.StockLineId), 0) AS VendorOTD
        INTO #VendorScorecard
        FROM dbo.Stockline stl WITH (NOLOCK)
        INNER JOIN dbo.PurchaseOrderPart pop WITH (NOLOCK) ON stl.PurchaseOrderPartRecordId = pop.PurchaseOrderPartRecordId
        INNER JOIN dbo.PurchaseOrder po WITH (NOLOCK) ON stl.PurchaseOrderId = po.PurchaseOrderId
        WHERE stl.MasterCompanyId = @masterCompanyId
          AND stl.VendorId IS NOT NULL
          AND stl.ReceivedDate >= DATEADD(day, -90, GETUTCDATE())
          AND ISNULL(stl.IsDeleted, 0) = 0
        GROUP BY stl.VendorId;

        -- Main Result Set Selection
        SELECT 
            im.partnumber                                              AS [partNumber],
            im.PartDescription                                         AS [partDescription],
            ISNULL(ic.Description, im.ItemClassificationName)          AS [itemClassification],
            ISNULL(s.Name, ISNULL(w.Name, ISNULL(inv.SiteName, 'MIA'))) AS [siteCode],
            ISNULL(s.Name, ISNULL(w.Name, ISNULL(inv.SiteName, 'Miami Facility'))) AS [siteName],
            ISNULL(v.VendorName, ISNULL(inv.VendorName, 'Standard Vendor')) AS [vendorName],
            ISNULL(ms.Name, 'Commercial Fleet')                        AS [managementStructure],
            ISNULL(c.Description, ISNULL(inv.ConditionName, 'Overhauled (OH)')) AS [conditionName],
            ISNULL(c.Code, 'OH')                                       AS [conditionCode],
            CAST(ISNULL(dem.IsAOG, 0) AS BIT)                          AS [isAOG],
            CAST(CASE 
                WHEN ISNULL(inv.AvailableQty, 0) <= 0 THEN 0.0
                WHEN ISNULL(burn.DailyBurnRate, 0) <= 0 THEN 999.0
                ELSE ISNULL(inv.AvailableQty, 0) / burn.DailyBurnRate
            END AS FLOAT)                                              AS [daysOfCover],
            CAST(ISNULL(inv.OnHandQty, 0) AS INT)                      AS [onHandQuantity],
            CAST(ISNULL(inv.AllocatedQty, 0) AS INT)                   AS [allocatedQuantity],
            CAST(ISNULL(inv.QtyOnAR, 0) AS INT)                        AS [quantityOnAR],
            CAST(ISNULL(inv.AvailableQty, 0) AS INT)                   AS [availableQuantity],
            CAST(ISNULL(dem.OpenDemandQty, 0) AS INT)                  AS [openDemandQuantity],
            CAST(ISNULL(im.ReorderPoint, 0) AS INT)                    AS [reorderPointQuantity],
            CAST(ISNULL(im.UnitCost, 0.0) AS FLOAT)                    AS [unitCost],
            CAST(ISNULL(dem.OpenDemandQty * im.UnitCost, 0.0) AS FLOAT) AS [shortageExposureValue],
            CAST(ISNULL(po.BackorderLineCount, 0) AS INT)              AS [backorderLineCount],
            CAST(ISNULL(po.BackorderValue, 0.0) AS FLOAT)              AS [backorderValue],
            CAST(CASE WHEN ISNULL(po.MaxOverdueDays, 0) > 0 THEN 1 ELSE 0 END AS BIT) AS [isPastPromisedDate],
            CAST(CASE WHEN ISNULL(po.MaxOverdueDays, 0) > 0 THEN po.MaxOverdueDays ELSE 0 END AS INT) AS [overdueDays],
            CASE 
                WHEN ISNULL(po.MaxOverdueDays, 0) <= 0 THEN 'On Schedule'
                WHEN po.MaxOverdueDays BETWEEN 1 AND 7 THEN '1-7 d'
                WHEN po.MaxOverdueDays BETWEEN 8 AND 14 THEN '8-14 d'
                WHEN po.MaxOverdueDays BETWEEN 15 AND 30 THEN '15-30 d'
                ELSE '30+ d'
            END                                                        AS [overdueAgeingCategory],
            CAST(ISNULL(po.AvgPromisedLeadTime, ISNULL(im.LeadTimeDays, 14.0)) AS FLOAT) AS [promisedLeadTimeDays],
            CAST(ISNULL(im.LeadTimeDays, 14.0) AS FLOAT)               AS [expectedLeadTimeDays],
            CAST(ISNULL(vsc.ActualLeadTimeDays, ISNULL(im.LeadTimeDays, 14.0)) AS FLOAT) AS [actualLeadTimeDays],
            CAST(ISNULL(vsc.VendorOTD, 0.95) AS FLOAT)                 AS [vendorOTD]
        FROM dbo.ItemMaster im WITH (NOLOCK)
        LEFT JOIN dbo.ItemClassification ic WITH (NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
        LEFT JOIN dbo.Site s WITH (NOLOCK) ON im.SiteId = s.SiteId
        LEFT JOIN dbo.Warehouse w WITH (NOLOCK) ON im.WarehouseId = w.WarehouseId
        LEFT JOIN dbo.ManagementStructure ms WITH (NOLOCK) ON im.ManagementStructureId = ms.ManagementStructureId
        LEFT JOIN #StocklineInv inv ON im.ItemMasterId = inv.ItemMasterId
        LEFT JOIN dbo.Condition c WITH (NOLOCK) ON inv.ConditionId = c.ConditionId
        LEFT JOIN dbo.Vendor v WITH (NOLOCK) ON inv.VendorId = v.VendorId
        LEFT JOIN #DailyBurn burn ON im.ItemMasterId = burn.ItemMasterId
        LEFT JOIN #OpenDemand dem ON im.ItemMasterId = dem.ItemMasterId
        LEFT JOIN #OpenPO po ON im.ItemMasterId = po.ItemMasterId
        LEFT JOIN #VendorScorecard vsc ON inv.VendorId = vsc.VendorId
        WHERE im.MasterCompanyId = @masterCompanyId
          AND ISNULL(im.IsDeleted, 0) = 0
          AND ISNULL(im.IsActive, 1) = 1
        ORDER BY im.partnumber ASC;

        -- Clean up temp tables
        IF OBJECT_ID(N'tempdb..#StocklineInv') IS NOT NULL DROP TABLE #StocklineInv;
        IF OBJECT_ID(N'tempdb..#DailyBurn') IS NOT NULL DROP TABLE #DailyBurn;
        IF OBJECT_ID(N'tempdb..#OpenDemand') IS NOT NULL DROP TABLE #OpenDemand;
        IF OBJECT_ID(N'tempdb..#OpenPO') IS NOT NULL DROP TABLE #OpenPO;
        IF OBJECT_ID(N'tempdb..#VendorScorecard') IS NOT NULL DROP TABLE #VendorScorecard;

    END TRY    
    BEGIN CATCH
        DECLARE @ErrorLogID INT
        ,@DatabaseName VARCHAR(100) = db_name()
        ,@AdhocComments VARCHAR(150) = 'USP_GetPowerBIPartsAvailabilityAndStockout'
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