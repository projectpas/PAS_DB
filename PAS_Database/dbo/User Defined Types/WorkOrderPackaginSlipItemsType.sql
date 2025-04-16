CREATE TYPE [dbo].[WorkOrderPackaginSlipItemsType] AS TABLE (
    [PackagingSlipItemId] BIGINT         NULL,
    [PackagingSlipId]     BIGINT         NULL,
    [WOPickTicketId]      BIGINT         NULL,
    [WOPartNoId]          BIGINT         NULL,
    [MasterCompanyId]     INT            NULL,
    [CreatedBy]           VARCHAR (256)  NULL,
    [UpdatedBy]           VARCHAR (256)  NULL,
    [CreatedDate]         DATETIME2 (7)  NULL,
    [UpdatedDate]         DATETIME2 (7)  NULL,
    [IsActive]            BIT            NULL,
    [IsDeleted]           BIT            NULL,
    [PDFPath]             NVARCHAR (MAX) NULL);

