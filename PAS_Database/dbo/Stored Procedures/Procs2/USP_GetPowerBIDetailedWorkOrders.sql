/*************************************************************             
 ** File:   [USP_GetPowerBIDetailedWorkOrders]             
 ** Author:   SUMIT KUMAR
 ** Description: Retrieve Detailed Work Orders with Turnaround Time (TAT) Metrics for Power BI  
 ** Purpose:           
 ** Date:   12-AUG-2026        
            
 **************************************************************             
 ** CHANGE HISTORY:             
 **************************************************************             
 ** S NO   Date         Author           Change Description              
 ** 1      12-AUG-2026  SUMIT KUMAR      Created
 ** 2      08-OCT-2026  SUMIT KUMAR      Aligned QuoteTAT / ActualTAT with usprpt_GetWorkOrderTATReport (application TAT report):
 **                                      removed date-based fallback (< 1 day now returns 0) and truncated to whole days.
 **                                      [Date] now returns WOS.ShipDate (the From/To date filter field of the application TAT report).
 ** 3      22-OCT-2026  BHARGAV SALIYA   Live TAT for open stages: added TatClosedDays / TatOpenStageStartUtc and QuoteClosedDays /
 **                                      QuoteOpenStageStartUtc so a Power BI measure adds the running stage time at view time
 **                                      (ActualTAT / QuoteTAT are only correct as of the last dataset refresh).
 **                                      MPN details as per the application TAT report: MPNPart uses the revised PN when present,
 **                                      added PartDescription, Quantity, Condition, ReceivedDate and OpenDate.
 **************************************************************/
CREATE PROCEDURE [dbo].[USP_GetPowerBIDetailedWorkOrders]   
    @mastercompanyid INT
AS  
BEGIN  
    SET NOCOUNT ON;  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
  
    BEGIN TRY
        -- 1. Temp table to hold raw stage-based days sum  
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
            ) AS QuoteDays,
            -- Completed stage time + start of the still-open stage, so Power BI can add (now - start) at view time
            SUM(CASE WHEN WS.IncludeInTAT = 1 AND WT.StatusChangedEndDate IS NOT NULL
                     THEN ISNULL(WT.[Days], 0) + (ISNULL(WT.[Hours], 0) / 24.0) + (ISNULL(WT.[Mins], 0) / 1440.0) ELSE 0 END) AS TatClosedDays,
            MIN(CASE WHEN WS.IncludeInTAT = 1 AND WT.StatusChangedEndDate IS NULL THEN WT.StatusChangedDate END) AS TatOpenStageStartUtc,
            SUM(CASE WHEN WS.QuoteDays = 1 AND WT.StatusChangedEndDate IS NOT NULL
                     THEN ISNULL(WT.[Days], 0) + (ISNULL(WT.[Hours], 0) / 24.0) + (ISNULL(WT.[Mins], 0) / 1440.0) ELSE 0 END) AS QuoteClosedDays,
            MIN(CASE WHEN WS.QuoteDays = 1 AND WT.StatusChangedEndDate IS NULL THEN WT.StatusChangedDate END) AS QuoteOpenStageStartUtc
        INTO #StageDays
        FROM dbo.WorkOrderTurnArroundTime WT WITH (NOLOCK)  
        INNER JOIN dbo.WorkOrderStage WS WITH (NOLOCK) ON WT.CurrentStageId = WS.WorkOrderStageId  
        GROUP BY WT.WorkOrderPartNoId;  
  
        -- 2. Temp table to hold raw part data with calculated TAT  
        IF OBJECT_ID(N'tempdb..#AllParts') IS NOT NULL  
            DROP TABLE #AllParts;  
  
        SELECT   
            WO.WorkOrderId,  
            WOPN.ID AS WorkOrderPartNoId,  
            WO.WorkOrderNum AS WorkOrderNo,  
            CASE WHEN ISNULL(WOPN.RevisedPartNumber, '') = '' THEN IM.partnumber ELSE WOPN.RevisedPartNumber END AS MPNPart,
            CASE WHEN ISNULL(WOPN.RevisedPartDescription, '') = '' THEN IM.PartDescription ELSE WOPN.RevisedPartDescription END AS PartDescription,
            WOPN.Quantity,
            WO.OpenDate,
            C.Name AS Customer,  
            WOPN.WorkScope AS Workspace,  
            ISNULL(NULLIF(MSD.Level4Name, ''), MSD.Level3Name) AS Station,  
            CASE WHEN WOPN.IsClosed = 1 THEN 'Closed' ELSE 'Open' END AS Status,  
              
            -- Quoted TAT (same as usprpt_GetWorkOrderTATReport 'quotedays'):
            -- sum of time in stages flagged QuoteDays; < 1 day => 0; whole days only (app stores it as INT)
            CASE WHEN ISNULL(SD.QuoteDays, 0) >= 1 THEN FLOOR(SD.QuoteDays) ELSE 0 END AS QuotedTat,

            -- Actual TAT (same as usprpt_GetWorkOrderTATReport 'tat'):
            -- sum of time in stages flagged IncludeInTAT; < 1 day => 0; whole days only (app stores it as INT)
            CASE WHEN ISNULL(SD.TatDays, 0) >= 1 THEN FLOOR(SD.TatDays) ELSE 0 END AS ActualTat,

            ISNULL(SD.TatClosedDays, 0) AS TatClosedDays,
            SD.TatOpenStageStartUtc,
            ISNULL(SD.QuoteClosedDays, 0) AS QuoteClosedDays,
            SD.QuoteOpenStageStartUtc,

            WOPN.ReceivedDate,  
            WOS.ShipDate,  
            CASE WHEN WOPN.IsClosed = 1 THEN ISNULL(WOPN.closeddate, ISNULL(WOBI.InvoiceDate, WOS.ShipDate)) ELSE NULL END AS CompletedDate,  
            WOPN.EstimatedShipDate,  
            WOPN.IsClosed,  
            CASE WHEN ISNULL(RCN.Description, '') = '' THEN CN.Description ELSE RCN.Description END AS Condition,
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
            LEFT JOIN dbo.Condition RCN WITH (NOLOCK) ON WOPN.RevisedConditionId = RCN.ConditionId
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
  
        SELECT   
            WorkOrderPartNoId AS WorkOrderID,  
            WorkOrderNo AS WorkOrderNumber,  
            MPNPart,  
            Customer,  
            Station,  
            Workspace AS Workscope,  
            Status,  
            -- [Date] = actual Ship Date, same date usprpt_GetWorkOrderTATReport applies @Fromdate/@Todate on (WOS.ShipDate)
            CASE WHEN ShipDate IS NOT NULL THEN CONVERT(VARCHAR(30), ShipDate, 127) + 'Z' ELSE NULL END AS [Date],  
            CASE WHEN CompletedDate IS NOT NULL THEN CONVERT(VARCHAR(30), CompletedDate, 127) + 'Z' ELSE NULL END AS ClosedDate,  
            CAST(ActualTat AS DECIMAL(18,1)) AS ActualTAT,  
            CAST(TargetTat AS DECIMAL(18,1)) AS TargetTAT,  
            CAST(QuotedTat AS DECIMAL(18,1)) AS QuoteTAT,  
            CAST(IsRework AS BIT) AS IsRework,
            PartDescription,
            Quantity,
            Condition,
            CASE WHEN ReceivedDate IS NOT NULL THEN CONVERT(VARCHAR(30), ReceivedDate, 126) ELSE NULL END AS ReceivedDate,
            CASE WHEN OpenDate IS NOT NULL THEN CONVERT(VARCHAR(30), OpenDate, 126) ELSE NULL END AS OpenDate,
            -- Live TAT inputs (UTC, no 'Z' so Power BI types them as plain Date/Time and compares with UTCNOW())
            CAST(TatClosedDays AS DECIMAL(18,4)) AS TatClosedDays,
            CASE WHEN TatOpenStageStartUtc IS NOT NULL THEN CONVERT(VARCHAR(30), TatOpenStageStartUtc, 126) ELSE NULL END AS TatOpenStageStartUtc,
            CAST(QuoteClosedDays AS DECIMAL(18,4)) AS QuoteClosedDays,
            CASE WHEN QuoteOpenStageStartUtc IS NOT NULL THEN CONVERT(VARCHAR(30), QuoteOpenStageStartUtc, 126) ELSE NULL END AS QuoteOpenStageStartUtc
        FROM #AllParts
        ORDER BY ReceivedDate DESC;  
  
        DROP TABLE #StageDays;  
        DROP TABLE #AllParts;  
    END TRY    
    BEGIN CATCH
        DECLARE @ErrorLogID INT
        ,@DatabaseName VARCHAR(100) = db_name()
        -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        ,@AdhocComments VARCHAR(150) = 'USP_GetPowerBIDetailedWorkOrders'
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@mastercompanyid, '') AS varchar(100))
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