-- =============================================
-- Author:		Abhishek Jirawala
-- Create date: 26 Aug 2026
-- Description:	TVP used to pass the set of PurchaseOrderPartReference rows
--              selected for unlink from the Unlink PO / Unlink All PO popups
--              into USP_UnlinkPurchaseOrderPartReference.
-- =============================================
CREATE TYPE [dbo].[POPartReferenceUnlinkType] AS TABLE (
    [PurchaseOrderPartReferenceId] BIGINT NULL,
    [PurchaseOrderId]              BIGINT NULL,
    [PurchaseOrderPartId]          BIGINT NULL,
    [ModuleId]                     INT    NULL,
    [ReferenceId]                  BIGINT NULL,
    [ReferencePartId]              BIGINT NULL,
    [IsKit]                        BIT    NULL);
