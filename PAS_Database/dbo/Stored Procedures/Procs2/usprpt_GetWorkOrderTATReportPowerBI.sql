/*************************************************************             
 ** File:   [usprpt_GetWorkOrderTATReportPowerBI]             
 ** Author:   AI pair programming assistant
 ** Description: Retrieve raw Work Order TAT data (actual versus quoted/target)
                 for Power BI dashboard.
 ** Date:   24-July-2026 
 ** Purpose: Fetches both Open and Closed Work Order details for a company
             without date constraints and formats column names with business aliases.
             Excludes database primary/foreign keys for security and data minimisation.
 **************************************************************/
 /** Change History           
 **************************************************************           
 ** PR   Date			Author				Change Description            
 ** --   --------		-------				--------------------------------          
    1    24-July-2026   Sumit Kumar		    Created
	
**************************************************************/        
 
CREATE OR ALTER PROCEDURE [dbo].[usprpt_GetWorkOrderTATReportPowerBI]
    @mastercompanyid INT
AS
BEGIN
    -- SET NOCOUNT ON prevents sending extra messages to the client for performance
    SET NOCOUNT ON;
    -- READ UNCOMMITTED prevents read locks on tables during high-volume report executions
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    BEGIN TRY
        DECLARE @ModuleID INT = 12; -- MS Module ID
        DECLARE @WoModuleID AS BIGINT = (SELECT ModuleId FROM DBO.Module WITH (NOLOCK) WHERE ModuleName = 'WorkOrder');

        -- Clear any existing temp tables in current session context
        IF OBJECT_ID(N'tempdb..#tmpTop10TATData') IS NOT NULL DROP TABLE #tmpTop10TATData;
        IF OBJECT_ID(N'tempdb..#Result') IS NOT NULL DROP TABLE #Result;
        IF OBJECT_ID(N'tempdb..#finalSumData') IS NOT NULL DROP TABLE #finalSumData;

        -- CTE to sum up days/hours/minutes spent in each stage for each Work Order Part Number
        WITH TimeSums AS (
            -- 1. Get durations for stages that have already completed
            SELECT 
                SUM(WT.Days) AS TotalDays, 
                SUM(WT.Hours) AS TotalHours, 
                SUM(WT.Mins) AS TotalMinutes,
                WOP.ID,
                WT.CurrentStageId
            FROM dbo.[WorkOrderPartNumber] WOP WITH(NOLOCK)
                INNER JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
                INNER JOIN dbo.WorkOrderTurnArroundTime WT WITH (NOLOCK) ON WT.WorkOrderPartNoId = WOP.ID 
            WHERE WO.mastercompanyid = @mastercompanyid  
                AND WO.IsDeleted = 0 AND WO.IsActive = 1
                AND ISNULL(WT.StatusChangedEndDate, 0) != 0
            GROUP BY WOP.ID, WT.CurrentStageId
            
            UNION ALL

            -- 2. Get running duration for the current active stage that hasn't completed yet
            SELECT 
                0 AS TotalDays, 
                0 AS TotalHours, 
                SUM(DATEDIFF(MINUTE, WT.StatusChangedDate, GETUTCDATE())) AS TotalMinutes,
                WOP.ID,
                WT.CurrentStageId
            FROM dbo.[WorkOrderPartNumber] WOP WITH(NOLOCK)
                INNER JOIN dbo.WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId = WOP.WorkOrderId
                INNER JOIN dbo.WorkOrderTurnArroundTime WT WITH (NOLOCK) ON WT.WorkOrderPartNoId = WOP.ID 
            WHERE WO.mastercompanyid = @mastercompanyid  
                AND WO.IsDeleted = 0 AND WO.IsActive = 1
                AND ISNULL(WT.StatusChangedEndDate, 0) = 0
            GROUP BY WOP.ID, WT.CurrentStageId
        ),
        timeSumData AS (
            -- Get stage metadata flags like QuoteDays, ApprovedDays, IncludeInTAT, etc.
            SELECT 
                WT.TotalDays, WT.TotalHours, WT.TotalMinutes, WT.ID, WT.CurrentStageId,
                WS.QuoteDays, WS.ApprovedDays, WS.ShippedDays, WS.IncludeInTAT, 0 AS TotalRecDays
            FROM TimeSums WT
                LEFT JOIN dbo.WorkOrderStage WS WITH (NOLOCK) ON WS.WorkOrderStageId = WT.CurrentStageId
        )
        -- Select into temporary table for update queries later
        SELECT * INTO #tmpTop10TATData FROM timeSumData;

        -- Group and calculate total days spent in each stage per Work Order Part Number
        SELECT SUM(TotalDays + (TotalHours / 24.0) + (TotalMinutes / 1440.0)) AS totaldays, ID, CurrentStageId
        INTO #finalSumData
        FROM #tmpTop10TATData
        GROUP BY CurrentStageId, ID;

        -- Retrieve raw records matching mastercompanyid
        SELECT 
            UPPER(C.Name) AS 'CustomerName',  
            UPPER(C.CustomerCode) AS 'CustomerCode',  
            CASE WHEN ISNULL(WOPN.RevisedPartNumber, '') = '' THEN UPPER(IM.partnumber) ELSE UPPER(WOPN.RevisedPartNumber) END AS 'PartNumber',  
            CASE WHEN ISNULL(WOPN.RevisedPartDescription, '') = '' THEN UPPER(IM.PartDescription) ELSE UPPER(WOPN.RevisedPartDescription) END AS 'PartDescription',  
            WOPN.Quantity AS 'Quantity',  
            UPPER(WOPN.WorkScope) AS 'WorkScope',  
            CASE WHEN ISNULL(RCN.Description, '') = '' THEN UPPER(CN.Description) ELSE UPPER(RCN.Description) END AS 'Condition',  
            UPPER(WO.WorkOrderNum) AS 'WorkOrderNumber',  
            WOBI.InvoiceNo AS 'InvoiceNumber',  
            DATEDIFF(DAY, WOPN.ReceivedDate, WOQ.sentDate) AS 'QuoteDays',
            DATEDIFF(DAY, WOQ.sentDate, WOQ.approveddate) AS 'ApprovedDays',  
            DATEDIFF(DAY, WOQ.approveddate, WOPN.EstimatedShipDate) AS 'EstShipDays', 
            DATEDIFF(DAY, WOQ.approveddate, WOPN.EstimatedShipDate) + DATEDIFF(DAY, WOPN.ReceivedDate, WOQ.sentDate) AS 'ActualTAT',  
            ISNULL(WOPN.TATDaysStandard, 0) AS 'TargetTAT',
            UPPER(ESST.StationName) AS 'StationName',
            WOPN.ReceivedDate AS 'ReceivedDate',   
            (SELECT DATEADD(SECOND, TZ.BaseUtcOffsetSec, WO.OpenDate)) AS 'OpenDate',   
            WOQ.SentDate AS 'QuoteDate',   
            (SELECT DATEADD(SECOND, TZ.BaseUtcOffsetSec, WOQ.approveddate)) AS 'ApprovedDate',   
            WOPN.EstimatedShipDate AS 'EstShipDate',   
            (SELECT DATEADD(SECOND, TZ.BaseUtcOffsetSec, WOBI.InvoiceDate)) AS 'InvoiceDate',   
            (SELECT DATEADD(SECOND, TZ.BaseUtcOffsetSec, WOS.ShipDate)) AS 'ShipDate',
            UPPER(E.FirstName + ' ' + E.LastName) AS 'TechName',  
            UPPER(MSD.Level1Name) AS 'Level1', UPPER(MSD.Level2Name) AS 'Level2', UPPER(MSD.Level3Name) AS 'Level3', UPPER(MSD.Level4Name) AS 'Level4', UPPER(MSD.Level5Name) AS 'Level5', UPPER(MSD.Level6Name) AS 'Level6', UPPER(MSD.Level7Name) AS 'Level7', UPPER(MSD.Level8Name) AS 'Level8', UPPER(MSD.Level9Name) AS 'Level9', UPPER(MSD.Level10Name) AS 'Level10',
            TZ.TimeZoneName AS 'TimeZoneName',
            WOPN.WorkOrderStage AS 'WorkOrderStage',
            WOST.Description AS 'WorkOrderStatus',
            WOPN.ID AS 'ID'
        INTO #Result
        FROM DBO.WorkOrder WO WITH (NOLOCK)  
            INNER JOIN DBO.WorkOrderWorkFlow WOWF WITH (NOLOCK) ON WOWF.WorkOrderId = WO.WorkOrderId   
            INNER JOIN DBO.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOWF.WorkOrderPartNoId = WOPN.ID 
            INNER JOIN DBO.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WOPN.ID  
            LEFT JOIN DBO.EntityStructureSetup ES ON ES.EntityStructureId=MSD.EntityMSID  
            LEFT JOIN DBO.BillingInvoicingItems WBII ON WBII.SubReferenceId = WOPN.ID AND WBII.ModuleId = @WoModuleID AND ISNULL(WBII.IsVersionIncrease,0)=0
            LEFT JOIN DBO.BillingInvoicing AS WOBI WITH (NOLOCK) ON WBII.BillingInvoicingId = WOBI.BillingInvoicingId AND ISNULL(WOBI.IsVersionIncrease,0)=0 AND ISNULL(WOBI.IsPerformaInvoice, 0) = 0 AND WOBI.ModuleId = @WoModuleID
            LEFT JOIN DBO.Condition CN WITH (NOLOCK) ON WOPN.ConditionId = CN.ConditionId  
            LEFT JOIN DBO.WorkOrderQuote woq WITH (NOLOCK) ON WO.WorkOrderId = woq.WorkOrderId AND woq.IsVersionIncrease=0  
            LEFT JOIN DBO.WorkOrderStatus WOST WITH (NOLOCK) ON WOPN.WorkOrderStatusId = WOST.Id
            LEFT JOIN DBO.Customer C WITH (NOLOCK) ON WO.CustomerId = C.CustomerId  
            LEFT JOIN DBO.ItemMaster IM WITH (NOLOCK) ON WOPN.ItemMasterId = IM.ItemMasterId AND ISNULL(IM.IsNonStock,0) = 0
            LEFT JOIN DBO.WorkOrderShippingItem AS WOSI WITH (NOLOCK) ON WOSI.WorkOrderPartNumId = WOPN.ID  
            LEFT JOIN DBO.WorkOrderShipping AS WOS WITH (NOLOCK) ON WOS.WorkOrderShippingId = WOSI.WorkOrderShippingId  
            LEFT JOIN DBO.Employee AS E WITH (NOLOCK) ON WOPN.TechnicianId = E.EmployeeId  
            LEFT JOIN DBO.EmployeeStation AS ESST WITH (NOLOCK) ON WOPN.TechStationId = ESST.EmployeeStationId
            LEFT JOIN [dbo].ManagementStructureLevel MSL WITH(NOLOCK) ON ES.Level1Id = MSL.ID
            LEFT JOIN [dbo].LegalEntity le WITH(NOLOCK) ON MSL.LegalEntityId = le.LegalEntityId
            LEFT JOIN [dbo].TimeZone TZ WITH(NOLOCK) ON le.TimeZoneId = TZ.TimeZoneId
            LEFT JOIN [dbo].[Condition] RCN WITH (NOLOCK) ON WOPN.RevisedConditionId = RCN.ConditionId
        WHERE WO.mastercompanyid = @mastercompanyid  
            AND WO.IsDeleted = 0 AND WO.IsActive = 1;

        -- Update stage-based Actual TAT
        UPDATE TP 
        SET TP.ActualTAT = CASE WHEN ISNULL(daysResult.totaldays, 0) >= 1 THEN ISNULL(daysResult.totaldays, 0) ELSE 0 END   
        FROM #Result TP
        OUTER APPLY (
            SELECT SUM(tm1.totaldays) AS totaldays 
            FROM #finalSumData tm1
                LEFT JOIN #tmpTop10TATData tm2 ON tm2.CurrentStageId = tm1.CurrentStageId AND tm1.ID = tm2.ID
            WHERE ISNULL(IncludeInTAT, 0) = 1 AND TP.ID = tm1.ID
        ) daysResult;

        -- Final projection: return only the requested aliased business columns (no ID/key columns)
        SELECT 
            CustomerName,  
            CustomerCode,  
            PartNumber,  
            PartDescription,  
            Quantity,  
            WorkScope,  
            Condition,  
            WorkOrderNumber,  
            InvoiceNumber,  
            OpenDate,  
            ReceivedDate,  
            QuoteDate,  
            ApprovedDate,  
            EstShipDate,  
            InvoiceDate,   
            ShipDate,
            TechName,  
            Level1, Level2, Level3, Level4, Level5, Level6, Level7, Level8, Level9, Level10,
            TimeZoneName,
            WorkOrderStage,
            WorkOrderStatus,
            ActualTAT,
            TargetTAT,
            StationName
        FROM #Result
        ORDER BY OpenDate;

    END TRY
    BEGIN CATCH
        -- Log exceptions into global DB log for auditing
        DECLARE @ErrorLogID INT,  
                @DatabaseName VARCHAR(100) = DB_NAME(),  
                @AdhocComments VARCHAR(150) = '[usprpt_GetWorkOrderTATReportPowerBI]',  
                @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@mastercompanyid, '') AS VARCHAR(100)),  
                @ApplicationName VARCHAR(100) = 'PAS';  
      
        EXEC Splogexception @DatabaseName = @DatabaseName,  
                            @AdhocComments = @AdhocComments,  
                            @ProcedureParameters = @ProcedureParameters,  
                            @ApplicationName = @ApplicationName,  
                            @ErrorLogID = @ErrorLogID OUTPUT;  
      
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID);  
        RETURN (1);  
    END CATCH
END
