
/*************************************************************
 ** File:   [USP_PublicApi_GetWorkOrderParts]
 ** Author: Moin Bloch
 ** Description: 4.14 Part lines (MPNs being worked on) of the WOs on one page (@WorkOrderIds = comma separated ids,
 **              max one page). Management structure is per part (WorkOrderManagementStructureDetails ModuleID 12).
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/workorders (parts)
 ** Date:   12/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    12/11/2026   Moin Bloch    Created

  EXEC [dbo].[USP_PublicApi_GetWorkOrderParts] @MasterCompanyId = 1, @WorkOrderIds = '690'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetWorkOrderParts]
    @MasterCompanyId INT,
    @WorkOrderIds    VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @MSModuleId INT = 12; -- WorkOrderMPN (ManagementStructureModuleEnum)

    SELECT
        -- Ids are used by the API to group parts per WO and attach materials, labor and charges; not returned to clients.
        P.[WorkOrderId],
        P.[ID] AS [WorkOrderPartNumberId],
        ISNULL(NULLIF(P.[PartNumber], ''), IM.[partnumber]) AS [PartNumber],
        ISNULL(NULLIF(P.[PartDescription], ''), IM.[PartDescription]) AS [PartDescription],
        ISNULL(NULLIF(P.[ManufacturerName], ''), IM.[ManufacturerName]) AS [Manufacturer],
        P.[RevisedPartNumber],
        P.[CurrentSerialNumber] AS [SerialNumber],
        P.[RevisedSerialNumber],
        CD.[Description] AS [Condition],
        RCD.[Description] AS [RevisedCondition],
        P.[WorkScope],
        ISNULL(P.[Quantity], 0) AS [Quantity],
        ISNULL(WS.[Description], P.[WorkOrderStatus]) AS [Status],
        LTRIM(RTRIM(P.[WorkOrderStage])) AS [Stage],
        P.[Priority],
        P.[CustomerReference],
        STL.[StockLineNumber],
        WF.[WorkFlowWorkOrderNo] AS [WorkflowNumber],
        P.[ReceivedDate],
        P.[CustomerRequestDate],
        P.[PromisedDate],
        P.[EstimatedShipDate],
        P.[EstimatedCompletionDate],
        P.[ShipDate],
        CAST(ISNULL(P.[IsClosed], 0) AS BIT) AS [IsClosed],
        P.[ClosedDate],
        P.[TechName] AS [Technician],
        P.[EmployeeStation] AS [TechStation],
        P.[TATDaysStandard] AS [TatDaysStandard],
        P.[TATDaysCurrent] AS [TatDaysCurrent],
        P.[NTE] AS [Nte],
        P.[ContractNo] AS [ContractNumber],
        MSD.[Level1Name] AS [LegalEntity],
        MSD.[Level2Name] AS [BusinessUnit],
        MSD.[Level3Name] AS [Division],
        MSD.[Level4Name] AS [Department]
    FROM [dbo].[WorkOrderPartNumber] P WITH (NOLOCK)
    INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK)
        ON WO.[WorkOrderId] = P.[WorkOrderId] AND WO.[MasterCompanyId] = @MasterCompanyId AND WO.[IsDeleted] = 0
    LEFT JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = P.[ItemMasterId]
    LEFT JOIN [dbo].[Condition] CD WITH (NOLOCK) ON CD.[ConditionId] = P.[ConditionId]
    LEFT JOIN [dbo].[Condition] RCD WITH (NOLOCK) ON RCD.[ConditionId] = P.[RevisedConditionId]
    LEFT JOIN [dbo].[WorkOrderStatus] WS WITH (NOLOCK) ON WS.[Id] = P.[WorkOrderStatusId]
    LEFT JOIN [dbo].[Stockline] STL WITH (NOLOCK) ON STL.[StockLineId] = P.[StockLineId]
    OUTER APPLY (SELECT TOP (1) F.[WorkFlowWorkOrderNo] FROM [dbo].[WorkOrderWorkFlow] F WITH (NOLOCK)
                 WHERE F.[WorkOrderPartNoId] = P.[ID] AND F.[IsDeleted] = 0 ORDER BY F.[WorkFlowWorkOrderId]) WF
    -- Plain level names (AllMSlevels is HTML for the PAS screen).
    OUTER APPLY (SELECT TOP (1) M.[Level1Name], M.[Level2Name], M.[Level3Name], M.[Level4Name]
                 FROM [dbo].[WorkOrderManagementStructureDetails] M WITH (NOLOCK)
                 WHERE M.[ModuleID] = @MSModuleId AND M.[ReferenceID] = P.[ID]) MSD
    WHERE P.[WorkOrderId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@WorkOrderIds, ','))
      AND P.[IsDeleted] = 0
    ORDER BY P.[WorkOrderId], P.[ID];
END