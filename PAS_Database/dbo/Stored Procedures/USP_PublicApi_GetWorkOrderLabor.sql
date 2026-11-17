
/*************************************************************
 ** File:   [USP_PublicApi_GetWorkOrderLabor]
 ** Author: Moin Bloch
 ** Description: 4.17 Labor task lines of the parts of the WOs on one page, as on the PAS Labor tab
 **              (sp_GetWorkOrderLaborHeader / sp_GetWorkOrderLaborTaskList). Clock in / out labor (HoursorClockorScan = 2)
 **              returns the tracked hours (FN_GetCurrentLaborHours), like PAS.
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/workorders (parts[].labor)
 ** Date:   12/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    12/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_GetWorkOrderLabor] @MasterCompanyId = 1, @WorkOrderIds = '690'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetWorkOrderLabor]
    @MasterCompanyId INT,
    @WorkOrderIds    VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LaborClockInOutTypeId INT = 2;

    -- Labor lines of the page.
    SELECT L.[WorkOrderLaborId], CAST(CASE WHEN ISNULL(H.[HoursorClockorScan], 0) = @LaborClockInOutTypeId THEN 1 ELSE 0 END AS BIT) AS [IsClock]
    INTO #Labor
    FROM [dbo].[WorkOrderLabor] L WITH (NOLOCK)
    INNER JOIN [dbo].[WorkOrderLaborHeader] H WITH (NOLOCK) ON H.[WorkOrderLaborHeaderId] = L.[WorkOrderLaborHeaderId] AND H.[IsDeleted] = 0
    WHERE H.[WorkOrderId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@WorkOrderIds, ','))
      AND L.[IsDeleted] = 0;

    -- Clock in / out hours: same result as PAS dbo.FN_GetCurrentLaborHours(@WorkOrderLaborId, 0), computed for the
    -- whole page with one read of WorkOrderLaborTracking (the function scans that table three times per labor line).
    -- Result is hours.minutes (1.30 = 1 h 30 min): the running session (latest open row) plus the completed sessions.
    SELECT T.[WorkOrderLaborId], T.[WorkOrderLaborTrackingId], T.[StartTime], ISNULL(T.[IsCompleted], 0) AS [IsCompleted], T.[TotalHours], T.[TotalMinutes]
    INTO #Tracking
    FROM [dbo].[WorkOrderLaborTracking] T WITH (NOLOCK)
    WHERE T.[WorkOrderLaborId] IN (SELECT [WorkOrderLaborId] FROM #Labor WHERE [IsClock] = 1);

    SELECT X.[WorkOrderLaborId],
           TRY_CONVERT(DECIMAL(10, 2), CONCAT(M.[TotalHours] + M.[TotalMinutes] / 60, '.',
                       FORMAT(CASE WHEN M.[TotalMinutes] > 60 THEN M.[TotalMinutes] % 60 ELSE M.[TotalMinutes] END, '00'))) AS [Hours]
    INTO #ClockHours
    FROM #Labor X
    OUTER APPLY (SELECT TOP (1) DATEDIFF(MINUTE, R.[StartTime], GETUTCDATE()) AS [OpenMinutes]
                 FROM #Tracking R WHERE R.[WorkOrderLaborId] = X.[WorkOrderLaborId] AND R.[IsCompleted] = 0
                 ORDER BY R.[WorkOrderLaborTrackingId] DESC) O
    OUTER APPLY (SELECT COUNT(1) AS [Sessions], SUM(ISNULL(R.[TotalHours], 0)) AS [Hours], SUM(ISNULL(R.[TotalMinutes], 0)) AS [Minutes]
                 FROM #Tracking R WHERE R.[WorkOrderLaborId] = X.[WorkOrderLaborId] AND R.[IsCompleted] = 1) C
    CROSS APPLY (SELECT ISNULL(O.[OpenMinutes] / 60, 0) + CASE WHEN C.[Sessions] > 0 THEN C.[Hours] ELSE 0 END AS [TotalHours],
                        ISNULL(O.[OpenMinutes] % 60, 0) + CASE WHEN C.[Sessions] > 0 THEN C.[Minutes] ELSE 0 END AS [TotalMinutes]) M
    WHERE X.[IsClock] = 1;

    SELECT
        -- Id is used by the API to attach the labor line to its part; not returned to clients.
        WF.[WorkOrderPartNoId] AS [WorkOrderPartNumberId],
        CASE WHEN ISNULL(WO.[WorkOrderFormTypeId], 0) = 1 THEN WOT.[TaskName] ELSE T.[Description] END AS [Task],
        EX.[Description] AS [Expertise],
        CONCAT_WS(' ', NULLIF(LTRIM(RTRIM(EMP.[FirstName])), ''), NULLIF(LTRIM(RTRIM(EMP.[LastName])), '')) AS [Employee],
        TS.[Description] AS [Status],
        CASE L.[BillableId] WHEN 1 THEN 'Billable' WHEN 2 THEN 'Non-Billable' END AS [Billable],
        L.[StartDate],
        L.[EndDate],
        CASE WHEN ISNULL(H.[HoursorClockorScan], 0) = @LaborClockInOutTypeId THEN ISNULL(CH.[Hours], 0) ELSE L.[Hours] END AS [Hours],
        L.[Adjustments],
        L.[AdjustedHours],
        L.[StandardHours],
        L.[StandardMinute],
        L.[DirectLaborOHCost] AS [DirectLaborCost],
        L.[BurdenRateAmount],
        L.[TotalCostPerHour],
        L.[TotalCost],
        CAST(ISNULL(L.[IsAdjustmentTask], 0) AS BIT) AS [IsAdjustmentTask]
    FROM [dbo].[WorkOrderLabor] L WITH (NOLOCK)
    INNER JOIN [dbo].[WorkOrderLaborHeader] H WITH (NOLOCK) ON H.[WorkOrderLaborHeaderId] = L.[WorkOrderLaborHeaderId] AND H.[IsDeleted] = 0
    INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK)
        ON WO.[WorkOrderId] = H.[WorkOrderId] AND WO.[MasterCompanyId] = @MasterCompanyId AND WO.[IsDeleted] = 0
    INNER JOIN [dbo].[WorkOrderWorkFlow] WF WITH (NOLOCK) ON WF.[WorkFlowWorkOrderId] = H.[WorkFlowWorkOrderId]
    LEFT JOIN [dbo].[Task] T WITH (NOLOCK) ON T.[TaskId] = L.[TaskId]
    LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.[WorkOrderTaskId] = L.[TaskId]
    LEFT JOIN [dbo].[ExpertiseType] EX WITH (NOLOCK) ON EX.[ExpertiseTypeId] = L.[ExpertiseId]
    LEFT JOIN [dbo].[Employee] EMP WITH (NOLOCK) ON EMP.[EmployeeId] = L.[EmployeeId]
    LEFT JOIN [dbo].[TaskStatus] TS WITH (NOLOCK) ON TS.[TaskStatusId] = L.[TaskStatusId]
    LEFT JOIN #ClockHours CH ON CH.[WorkOrderLaborId] = L.[WorkOrderLaborId]
    WHERE L.[WorkOrderLaborId] IN (SELECT [WorkOrderLaborId] FROM #Labor)
    ORDER BY WF.[WorkOrderPartNoId], CASE WHEN L.[IsAdjustmentTask] = 1 THEN 1 ELSE 0 END, TRY_CAST(WOT.[SequenceNumber] AS INT), L.[WorkOrderLaborId];
END