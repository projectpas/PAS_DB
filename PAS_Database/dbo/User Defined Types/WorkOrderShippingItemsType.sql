CREATE TYPE [dbo].[WorkOrderShippingItemsType] AS TABLE (
    [WorkOrderShippingItemId] BIGINT        NULL,
    [WorkOrderShippingId]     BIGINT        NULL,
    [WorkOrderPartNumId]      BIGINT        NULL,
    [QtyShipped]              INT           NULL,
    [WOPickTicketId]          BIGINT        NULL,
    [PDFPath]                 VARCHAR (255) NULL,
    [FedexPdfPath]            VARCHAR (255) NULL,
    [MasterCompanyId]         INT           NULL,
    [CreatedBy]               VARCHAR (100) NULL,
    [CreatedDate]             DATETIME2 (7) NULL,
    [UpdatedBy]               VARCHAR (100) NULL,
    [UpdatedDate]             DATETIME2 (7) NULL,
    [IsActive]                BIT           NULL,
    [IsDeleted]               BIT           NULL);

