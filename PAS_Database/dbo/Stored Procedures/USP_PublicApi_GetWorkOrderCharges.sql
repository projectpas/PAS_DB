
/*************************************************************
 ** File:   [USP_PublicApi_GetWorkOrderCharges]
 ** Author: Moin Bloch
 ** Description: 4.18 Charges of the parts of the WOs on one page, as on the PAS Charges tab (GetWorkFlowWorkOrderChargesList).
 ** Purpose: PAS_PUBLIC_API - GET /api/v1/workorders (parts[].charges)
 ** Date:   12/11/2026

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    12/11/2026   Moin Bloch    Created
    2    19/11/2026   Moin Bloch    Added TRY/CATCH (errors logged with spLogException)

  EXEC [dbo].[USP_PublicApi_GetWorkOrderCharges] @MasterCompanyId = 1, @WorkOrderIds = '690'
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_PublicApi_GetWorkOrderCharges]
    @MasterCompanyId INT,
    @WorkOrderIds    VARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT
            -- Id is used by the API to attach the charge to its part; not returned to clients.
            WF.[WorkOrderPartNoId] AS [WorkOrderPartNumberId],
            CASE WHEN ISNULL(WO.[WorkOrderFormTypeId], 0) = 1 THEN
                     CASE WHEN ISNULL(DUP.[TaskCount], 0) > 1 AND ISNULL(WOT.[SequenceNumber], '') <> '' THEN WOT.[SequenceNumber] + ' - ' + WOT.[TaskName] ELSE WOT.[TaskName] END
                 ELSE T.[Description] END AS [Task],
            CT.[ChargeType],
            C.[Description],
            V.[VendorName] AS [Vendor],
            C.[ReferenceNo] AS [ReferenceNumber],
            UOM.[ShortName] AS [UnitOfMeasure],
            ISNULL(C.[Quantity], 0) AS [Quantity],
            C.[UnitCost],
            C.[ExtendedCost],
            GL.[AccountName] AS [GlAccount]
        FROM [dbo].[WorkOrderCharges] C WITH (NOLOCK)
        INNER JOIN [dbo].[WorkOrder] WO WITH (NOLOCK)
            ON WO.[WorkOrderId] = C.[WorkOrderId] AND WO.[MasterCompanyId] = @MasterCompanyId AND WO.[IsDeleted] = 0
        INNER JOIN [dbo].[WorkOrderWorkFlow] WF WITH (NOLOCK) ON WF.[WorkFlowWorkOrderId] = C.[WorkFlowWorkOrderId]
        LEFT JOIN [dbo].[Charge] CT WITH (NOLOCK) ON CT.[ChargeId] = C.[ChargesTypeId]
        LEFT JOIN [dbo].[Vendor] V WITH (NOLOCK) ON V.[VendorId] = C.[VendorId]
        LEFT JOIN [dbo].[Task] T WITH (NOLOCK) ON T.[TaskId] = C.[TaskId]
        LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.[WorkOrderTaskId] = C.[TaskId]
        -- Same task as more than once on the part: prefix the sequence number (as PAS).
        OUTER APPLY (SELECT COUNT(1) AS [TaskCount] FROM [dbo].[WorkOrderTask] D WITH (NOLOCK)
                     WHERE D.[TaskId] = WOT.[TaskId] AND D.[WorkOrderId] = WOT.[WorkOrderId] AND D.[WorkOrderPartNumberId] = WOT.[WorkOrderPartNumberId]
                       AND D.[IsActive] = 1 AND D.[IsDeleted] = 0) DUP
        LEFT JOIN [dbo].[GLAccount] GL WITH (NOLOCK) ON GL.[GLAccountId] = CT.[GLAccountId]
        LEFT JOIN [dbo].[UnitOfMeasure] UOM WITH (NOLOCK) ON UOM.[UnitOfMeasureId] = C.[UOMId]
        WHERE C.[WorkOrderId] IN (SELECT TRY_CAST([value] AS BIGINT) FROM STRING_SPLIT(@WorkOrderIds, ','))
          AND C.[IsDeleted] = 0
          AND C.[MasterCompanyId] = @MasterCompanyId
        ORDER BY WF.[WorkOrderPartNoId], C.[WorkOrderChargesId];
    END TRY
    BEGIN CATCH
        IF @@trancount > 0
            PRINT 'ROLLBACK'
        DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_PublicApi_GetWorkOrderCharges'
              , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
                                                   + '@Parameter2 = ''' + CAST(ISNULL(@WorkOrderIds, '') AS VARCHAR(100))
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
    END CATCH
END