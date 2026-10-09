CREATE TABLE [dbo].[LeaseShippingItemAudit] (
    [LeaseShippingItemAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [LeaseShippingItemId]      BIGINT          NULL,
    [LeaseShippingId]          BIGINT          NULL,
    [LeaseHeaderId]            BIGINT          NULL,
    [LeaseStocklineId]         BIGINT          NULL,
    [StocklineId]              BIGINT          NULL,
    [QtyShipped]               DECIMAL (18, 6) NULL,
    [LeasePickTicketId]        BIGINT          NULL,
    [MasterCompanyId]          INT             NULL,
    [CreatedBy]                VARCHAR (256)   NULL,
    [UpdatedBy]                VARCHAR (256)   NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_LeaseShippingItemAudit_CreatedDate] DEFAULT (getdate()) NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_LeaseShippingItemAudit_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]                 BIT             CONSTRAINT [DF_LeaseShippingItemAudit_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF_LeaseShippingItemAudit_IsDeleted] DEFAULT ((0)) NULL,
    [PDFPath]                  NVARCHAR (MAX)  NULL,
    [FedexPdfPath]             VARCHAR (MAX)   NULL,
    [UPSPdfPath]               VARCHAR (MAX)   NULL,
    CONSTRAINT [PK_LeaseShippingItemAudit] PRIMARY KEY CLUSTERED ([LeaseShippingItemAuditId] ASC)
);

