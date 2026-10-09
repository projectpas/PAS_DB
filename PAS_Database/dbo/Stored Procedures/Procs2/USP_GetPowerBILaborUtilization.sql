/*************************************************************             
 ** File:   [USP_GetPowerBILaborUtilization]             
 ** Author:  SUMIT KUMAR
 ** Description: Retrieve Labor Utilization & Efficiency Data for Power BI Reports  
 ** Purpose: Aggregates technician labor hours, efficiency, overtime, and capacity metrics
 ** Date:   07-OCT-2026        
 **************************************************************             
 ** CHANGE HISTORY:             
 **************************************************************             
 ** S NO   Date         Author           Change Description              
 ** 1      07-OCT-2026  SUMIT KUMAR     Created
 **************************************************************/  
CREATE PROCEDURE [dbo].[USP_GetPowerBILaborUtilization]   
    @masterCompanyId INT
AS  
BEGIN  
    SET NOCOUNT ON;  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  

    BEGIN TRY
        DECLARE @ModuleID INT = 12; -- Work Order Module ID for Management Structure Details

        -- 1. Combine tracked labor entries and manual labor adjustments
        WITH RawLabor AS (
            -- Logged time entries via timer / tracking
            SELECT 
                CAST(ISNULL(WOT.StartTime, WOL.StartDate) AS DATE) AS TaskDate,
                WO.WorkOrderId,
                WO.WorkOrderNum AS WorkOrderNo,
                EMP.EmployeeId,
                EMP.EmployeeCode,
                UPPER(CONCAT(EMP.FirstName, ' ', EMP.LastName)) AS Employee,
                UPPER(CONCAT(SUP.FirstName, ' ', SUP.LastName)) AS Supervisor,
                UPPER(ISNULL(EXP.[Description], '')) AS Expertise,
                UPPER(ISNULL(SITE.[Name], ISNULL(EMP.SiteId, ''))) AS Site,
                UPPER(ISNULL(ST.[StationName], '')) AS Station,
                UPPER(ISNULL(SH.[Description], 'Day')) AS Shift,
                UPPER(ISNULL(MSD.Level1Name, '')) AS ManagementStructure,
                UPPER(ISNULL(CUST.[Name], 'Internal / Stock')) AS Customer,
                UPPER(ISNULL(WPN.WorkScope, ISNULL(WS.WorkScopeCode, ISNULL(WS.[Description], '')))) AS WorkScope,
                CASE WHEN ISNULL(WO.WorkOrderFormTypeId, 0) > 0 THEN WT.TaskName ELSE UPPER(T.[Description]) END AS Task,
                CAST(CASE WHEN TS.[Description] IN ('Closed', 'Complete') OR WOL.TaskStatusId = 3 THEN 1 ELSE 0 END AS BIT) AS IsTaskClosed,
                CAST(CASE WHEN WOL.BillableId = 1 THEN 1 ELSE 0 END AS BIT) AS IsBillable,
                CAST(ISNULL(EMP.AllowOvertime, 0) AS BIT) AS AllowOvertime,
                CAST(ISNULL(EMP.AllowDoubleTime, 0) AS BIT) AS AllowDoubleTime,
                CAST(ISNULL(WOT.TotalHours, 0) + (ISNULL(WOT.TotalMinutes, 0) / 60.0) AS DECIMAL(10,2)) AS LaborHours,
                CAST(ISNULL(WOL.StandardHours, 0) + (ISNULL(WOL.StandardMinute, 0) / 60.0) AS DECIMAL(10,2)) AS StandardHours,
                CAST(8.0 AS DECIMAL(10,2)) AS ScheduledHours, -- Baseline shift daily capacity
                ISNULL(EMP.HourlyPay, 0.0) AS HourlyPay,
                ISNULL(WOL.TotalCost, 0.0) AS WOLTotalCost
            FROM dbo.WorkOrderLaborTracking WOT WITH (NOLOCK) 
            INNER JOIN dbo.WorkOrderLabor WOL WITH (NOLOCK) ON WOT.WorkOrderLaborId = WOL.WorkOrderLaborId
            INNER JOIN dbo.WorkOrderLaborHeader LH WITH (NOLOCK) ON WOL.WorkOrderLaborHeaderId = LH.WorkOrderLaborHeaderId
            INNER JOIN dbo.WorkOrder WO WITH (NOLOCK) ON LH.WorkOrderId = WO.WorkOrderId
            INNER JOIN dbo.WorkOrderWorkFlow WOF WITH (NOLOCK) ON LH.WorkFlowWorkOrderId = WOF.WorkFlowWorkOrderId
            INNER JOIN dbo.WorkOrderPartNumber WPN WITH (NOLOCK) ON WOF.WorkOrderPartNoId = WPN.ID  
            INNER JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WPN.ItemMasterId
            INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WPN.ID
            LEFT JOIN dbo.Employee EMP WITH (NOLOCK) ON EMP.EmployeeId = WOT.EmployeeId
            LEFT JOIN dbo.Employee SUP WITH (NOLOCK) ON SUP.EmployeeId = EMP.SupervisorId
            LEFT JOIN dbo.EmployeeExpertise EXP WITH (NOLOCK) ON EXP.EmployeeExpertiseId = WOL.ExpertiseId
            LEFT JOIN dbo.EmployeeStation ST WITH (NOLOCK) ON ST.EmployeeStationId = EMP.StationId
            LEFT JOIN dbo.Site SITE WITH (NOLOCK) ON SITE.SiteId = EMP.SiteId
            LEFT JOIN dbo.Shift SH WITH (NOLOCK) ON SH.ShiftId = EMP.JobTitleId
            LEFT JOIN dbo.Customer CUST WITH (NOLOCK) ON CUST.CustomerId = WO.CustomerId
            LEFT JOIN dbo.WorkScope WS WITH (NOLOCK) ON WS.WorkScopeId = WPN.WorkOrderScopeId
            LEFT JOIN dbo.Task T WITH (NOLOCK) ON WOL.TaskId = T.TaskId
            LEFT JOIN dbo.WorkOrderTask WT WITH (NOLOCK) ON WOL.TaskId = WT.WorkOrderTaskId
            LEFT JOIN dbo.TaskStatus TS WITH (NOLOCK) ON WOL.TaskStatusId = TS.TaskStatusId
            WHERE WO.MasterCompanyId = @masterCompanyId
              AND ISNULL(WO.IsActive, 1) = 1 AND ISNULL(WO.IsDeleted, 0) = 0
              AND ISNULL(IM.IsNonStock, 0) = 0
              AND WOT.StartTime IS NOT NULL

            UNION ALL

            -- Direct adjustments (manual labor entries)
            SELECT 
                CAST(ISNULL(WOL.StatusChangedDate, WOL.StartDate) AS DATE) AS TaskDate,
                WO.WorkOrderId,
                WO.WorkOrderNum AS WorkOrderNo,
                EMP.EmployeeId,
                EMP.EmployeeCode,
                UPPER(CONCAT(EMP.FirstName, ' ', EMP.LastName)) AS Employee,
                UPPER(CONCAT(SUP.FirstName, ' ', SUP.LastName)) AS Supervisor,
                UPPER(ISNULL(EXP.[Description], '')) AS Expertise,
                UPPER(ISNULL(SITE.[Name], ISNULL(EMP.SiteId, ''))) AS Site,
                UPPER(ISNULL(ST.[StationName], '')) AS Station,
                UPPER(ISNULL(SH.[Description], 'Day')) AS Shift,
                UPPER(ISNULL(MSD.Level1Name, '')) AS ManagementStructure,
                UPPER(ISNULL(CUST.[Name], 'Internal / Stock')) AS Customer,
                UPPER(ISNULL(WPN.WorkScope, ISNULL(WS.WorkScopeCode, ISNULL(WS.[Description], '')))) AS WorkScope,
                CASE WHEN ISNULL(WO.WorkOrderFormTypeId, 0) > 0 THEN WT.TaskName ELSE UPPER(T.[Description]) END AS Task,
                CAST(CASE WHEN TS.[Description] IN ('Closed', 'Complete') OR WOL.TaskStatusId = 3 THEN 1 ELSE 0 END AS BIT) AS IsTaskClosed,
                CAST(CASE WHEN WOL.BillableId = 1 THEN 1 ELSE 0 END AS BIT) AS IsBillable,
                CAST(ISNULL(EMP.AllowOvertime, 0) AS BIT) AS AllowOvertime,
                CAST(ISNULL(EMP.AllowDoubleTime, 0) AS BIT) AS AllowDoubleTime,
                CAST(ISNULL(WOL.Adjustments, WOL.Hours) AS DECIMAL(10,2)) AS LaborHours,
                CAST(ISNULL(WOL.StandardHours, 0) + (ISNULL(WOL.StandardMinute, 0) / 60.0) AS DECIMAL(10,2)) AS StandardHours,
                CAST(8.0 AS DECIMAL(10,2)) AS ScheduledHours,
                ISNULL(EMP.HourlyPay, 0.0) AS HourlyPay,
                ISNULL(WOL.TotalCost, 0.0) AS WOLTotalCost
            FROM dbo.WorkOrderLabor WOL WITH (NOLOCK)
            INNER JOIN dbo.WorkOrderLaborHeader LH WITH (NOLOCK) ON WOL.WorkOrderLaborHeaderId = LH.WorkOrderLaborHeaderId
            INNER JOIN dbo.WorkOrder WO WITH (NOLOCK) ON LH.WorkOrderId = WO.WorkOrderId
            INNER JOIN dbo.WorkOrderWorkFlow WOF WITH (NOLOCK) ON LH.WorkFlowWorkOrderId = WOF.WorkFlowWorkOrderId
            INNER JOIN dbo.WorkOrderPartNumber WPN WITH (NOLOCK) ON WOF.WorkOrderPartNoId = WPN.ID  
            INNER JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WPN.ItemMasterId
            INNER JOIN dbo.WorkOrderManagementStructureDetails MSD WITH (NOLOCK) ON MSD.ModuleID = @ModuleID AND MSD.ReferenceID = WPN.ID
            LEFT JOIN dbo.Employee EMP WITH (NOLOCK) ON EMP.EmployeeId = WOL.EmployeeId
            LEFT JOIN dbo.Employee SUP WITH (NOLOCK) ON SUP.EmployeeId = EMP.SupervisorId
            LEFT JOIN dbo.EmployeeExpertise EXP WITH (NOLOCK) ON EXP.EmployeeExpertiseId = WOL.ExpertiseId
            LEFT JOIN dbo.EmployeeStation ST WITH (NOLOCK) ON ST.EmployeeStationId = EMP.StationId
            LEFT JOIN dbo.Site SITE WITH (NOLOCK) ON SITE.SiteId = EMP.SiteId
            LEFT JOIN dbo.Shift SH WITH (NOLOCK) ON SH.ShiftId = EMP.JobTitleId
            LEFT JOIN dbo.Customer CUST WITH (NOLOCK) ON CUST.CustomerId = WO.CustomerId
            LEFT JOIN dbo.WorkScope WS WITH (NOLOCK) ON WS.WorkScopeId = WPN.WorkOrderScopeId
            LEFT JOIN dbo.Task T WITH (NOLOCK) ON WOL.TaskId = T.TaskId
            LEFT JOIN dbo.WorkOrderTask WT WITH (NOLOCK) ON WOL.TaskId = WT.WorkOrderTaskId
            LEFT JOIN dbo.TaskStatus TS WITH (NOLOCK) ON WOL.TaskStatusId = TS.TaskStatusId
            WHERE WO.MasterCompanyId = @masterCompanyId
              AND ISNULL(WO.IsActive, 1) = 1 AND ISNULL(WO.IsDeleted, 0) = 0
              AND ISNULL(IM.IsNonStock, 0) = 0
              AND WOL.Adjustments > 0
        )
        SELECT 
            CONVERT(VARCHAR(10), r.TaskDate, 120) AS TaskDate,
            r.WorkOrderId,
            r.WorkOrderNo,
            r.EmployeeCode,
            r.Employee,
            r.Supervisor,
            r.Expertise,
            r.Site,
            r.Station,
            r.Shift,
            r.ManagementStructure,
            r.Customer,
            r.WorkScope,
            r.Task,
            r.IsTaskClosed,
            r.IsBillable,
            r.AllowOvertime,
            r.AllowDoubleTime,
            r.LaborHours,
            r.StandardHours,
            r.ScheduledHours,
            -- Overtime calculation: Daily hours > ScheduledHours (8.0) when AllowOvertime = 1
            CAST(CASE 
                WHEN r.AllowOvertime = 1 AND r.LaborHours > r.ScheduledHours 
                THEN r.LaborHours - r.ScheduledHours 
                ELSE 0.0 
            END AS DECIMAL(10,2)) AS OvertimeHours,
            -- Labor Cost: Logged TotalCost or (LaborHours * HourlyPay)
            CAST(CASE 
                WHEN r.WOLTotalCost > 0 THEN r.WOLTotalCost 
                ELSE (r.LaborHours * r.HourlyPay) 
            END AS DECIMAL(18,2)) AS LaborCost,
            -- Overtime Cost: OvertimeHours * (HourlyPay * 1.5)
            CAST(CASE 
                WHEN r.AllowOvertime = 1 AND r.LaborHours > r.ScheduledHours 
                THEN (r.LaborHours - r.ScheduledHours) * (r.HourlyPay * 1.5)
                ELSE 0.0 
            END AS DECIMAL(18,2)) AS OvertimeCost
        FROM RawLabor r
        ORDER BY r.TaskDate DESC, r.Employee, r.WorkOrderNo;

    END TRY    
    BEGIN CATCH
        DECLARE @ErrorLogID INT
        ,@DatabaseName VARCHAR(100) = DB_NAME()
        ,@AdhocComments VARCHAR(150) = 'USP_GetPowerBILaborUtilization'
        ,@ProcedureParameters VARCHAR(3000) = '@masterCompanyId = ''' + CAST(ISNULL(@masterCompanyId, '') AS VARCHAR(100))
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
