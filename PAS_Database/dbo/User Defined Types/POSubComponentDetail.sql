/*************************************************************
 ** File:   [POSubComponentDetail]
 ** Description: PO Receiving - Condition / Qty Received / Unit Cost entered on the Sub Component grid of a PO part (table type).
                 One row per PO part + sub component part number + original (configured) condition. Read by
                 USP_CreateStocklineForReceivingPO -> USP_CreateSubComponentStocklinesForReceiving, which
                   - creates the sub component stocklines with the entered Condition / Qty Received / Unit Cost
                   - validates : total sub component cost (Qty Received x Unit Cost) of a PO part <= Main Part Cost
 ** Date:   12-NOV-2026
 ** Author:  Kishor Makwana
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    12-NOV-2026  Kishor Makwana    [PN-18526] Created
************************************************************************/
CREATE TYPE [dbo].[POSubComponentDetail] AS TABLE (
    [PurchaseOrderPartRecordId] BIGINT          NULL,
    [SubItemMasterId]           BIGINT          NULL,
    [OriginalConditionId]       BIGINT          NULL,
    [ConditionId]               BIGINT          NULL,
    [QtyReceived]               DECIMAL (18, 6) NULL,
    [UnitCost]                  DECIMAL (18, 6) NULL);
