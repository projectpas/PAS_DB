/*************************************************************
 ** File:   [USP_SyncWorksheetStatusByWorkOrder]
 ** Author:   Kishor Makwana
 ** Description: Keeps WorksheetHeader.WorkSheetStatusId in sync with the linked Work Order status.
 **              Until now "Closed" was only CALCULATED in USP_GetWorksheetList from the WO status and never
 **              stored, so the audit trigger never logged it and the worksheet history (WO > Worksheet and
 **              Worksheet module) never showed the CLOSED event.
 **              - WO Closed      : Open/In Process -> Closed (3)
 **              - WO re-opened   : Closed -> In Process (2) if worksheet has parts, else Open (1)
 **              Idempotent: only rows whose status actually changes are updated (one audit event each).
 ** dbo.WorkOrderStatus: 2 = Closed.  dbo.WorkSheetStatus: 1 = Open, 2 = In Process, 3 = Closed.
 ** Date:   19/10/2026
 **************************************************************
 ** Change History
 ** PR   Date         Author            Change Description
 ** --   --------     -------           --------------------------------
 ** 1    19/10/2026   Kishor Makwana    [PN-18355] - Created
 EXEC [dbo].[USP_SyncWorksheetStatusByWorkOrder] @WorkOrderId = 2077, @UpdatedBy = 'ADMIN'
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SyncWorksheetStatusByWorkOrder]
    @WorkOrderId BIGINT,
    @UpdatedBy   VARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @WOStatusClosed    INT = 2,
            @WSStatusOpen      INT = 1,
            @WSStatusInProcess INT = 2,
            @WSStatusClosed    INT = 3;

    IF (ISNULL(@WorkOrderId, 0) = 0) RETURN;

    DECLARE @IsWOClosed BIT = CASE WHEN EXISTS (SELECT 1 FROM [dbo].[WorkOrder] WITH (NOLOCK)
                                                WHERE [WorkOrderId] = @WorkOrderId AND [WorkOrderStatusId] = @WOStatusClosed)
                                   THEN 1 ELSE 0 END;

    IF (@IsWOClosed = 1)
    BEGIN
        UPDATE WH
           SET WH.[WorkSheetStatusId] = @WSStatusClosed,
               WH.[UpdatedBy]         = ISNULL(@UpdatedBy, WH.[UpdatedBy]),
               WH.[UpdatedDate]       = GETUTCDATE()
          FROM [dbo].[WorksheetHeader] WH
         WHERE WH.[WorkOrderId] = @WorkOrderId
           AND WH.[IsDeleted] = 0
           AND ISNULL(WH.[WorkSheetStatusId], @WSStatusOpen) <> @WSStatusClosed;
    END
    ELSE
    BEGIN
        UPDATE WH
           SET WH.[WorkSheetStatusId] = CASE WHEN EXISTS (SELECT 1 FROM [dbo].[WorksheetPart] WP WITH (NOLOCK)
                                                          WHERE WP.[WorksheetHeaderId] = WH.[WorksheetHeaderId] AND WP.[IsDeleted] = 0)
                                             THEN @WSStatusInProcess ELSE @WSStatusOpen END,
               WH.[UpdatedBy]         = ISNULL(@UpdatedBy, WH.[UpdatedBy]),
               WH.[UpdatedDate]       = GETUTCDATE()
          FROM [dbo].[WorksheetHeader] WH
         WHERE WH.[WorkOrderId] = @WorkOrderId
           AND WH.[IsDeleted] = 0
           AND WH.[WorkSheetStatusId] = @WSStatusClosed;
    END
END