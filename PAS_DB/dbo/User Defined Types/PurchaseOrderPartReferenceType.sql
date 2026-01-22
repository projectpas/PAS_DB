CREATE TYPE [dbo].[PurchaseOrderPartReferenceType] AS TABLE (
    [PurchaseOrderPartReferenceId] BIGINT        NULL,
    [PurchaseOrderId]              BIGINT        NULL,
    [PurchaseOrderPartId]          BIGINT        NULL,
    [ModuleId]                     INT           NULL,
    [ReferenceId]                  BIGINT        NULL,
    [Qty]                          INT           NULL,
    [RequestedQty]                 INT           NULL,
    [ReservedQty]                  INT           NULL,
    [MasterCompanyId]              INT           NULL,
    [CreatedBy]                    VARCHAR (256) NULL,
    [UpdatedBy]                    VARCHAR (256) NULL,
    [CreatedDate]                  DATETIME2 (7) NULL,
    [UpdatedDate]                  DATETIME2 (7) NULL,
    [IsActive]                     BIT           NULL,
    [IsDeleted]                    BIT           NULL,
    [IssuedQty]                    INT           NULL);

