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
            ) AS QuoteDays  
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
            IM.partnumber AS MPNPart,  
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
              
            WOPN.ReceivedDate,  
            WOS.ShipDate,  
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
            CAST(IsRework AS BIT) AS IsRework  
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