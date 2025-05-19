CREATE TABLE [dbo].[RepairOrderShippingItemAudit] (
    [AuditRepairOrderShippingItemId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [RepairOrderShippingItemId]      BIGINT         NOT NULL,
    [RepairOrderShippingId]          BIGINT         NOT NULL,
    [RepairOrderPartId]              BIGINT         NOT NULL,
    [QtyShipped]                     INT            NULL,
    [ROPickTicketId]                 BIGINT         NOT NULL,
    [MasterCompanyId]                INT            NOT NULL,
    [CreatedBy]                      VARCHAR (256)  NOT NULL,
    [UpdatedBy]                      VARCHAR (256)  NOT NULL,
    [CreatedDate]                    DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                    DATETIME2 (7)  NOT NULL,
    [IsActive]                       BIT            NOT NULL,
    [IsDeleted]                      BIT            NOT NULL,
    [PDFPath]                        NVARCHAR (MAX) NULL,
    [FedexPdfPath]                   VARCHAR (MAX)  NULL,
    CONSTRAINT [PK_RepairOrderShippingItemAudit] PRIMARY KEY CLUSTERED ([AuditRepairOrderShippingItemId] ASC),
    CONSTRAINT [FK_RepairOrderShippingItemAudit_RepairOrderShippingItem] FOREIGN KEY ([RepairOrderShippingItemId]) REFERENCES [dbo].[RepairOrderShippingItem] ([RepairOrderShippingItemId])
);

