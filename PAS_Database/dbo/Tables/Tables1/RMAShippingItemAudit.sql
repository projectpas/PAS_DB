CREATE TABLE [dbo].[RMAShippingItemAudit] (
    [AuditRMAShippingItemId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [RMAShippingId]          BIGINT         NOT NULL,
    [VendorRMADetailId]      BIGINT         NOT NULL,
    [QtyShipped]             INT            NULL,
    [RMAPickTicketId]        BIGINT         NOT NULL,
    [MasterCompanyId]        INT            NOT NULL,
    [CreatedBy]              VARCHAR (256)  NOT NULL,
    [UpdatedBy]              VARCHAR (256)  NOT NULL,
    [CreatedDate]            DATETIME2 (7)  CONSTRAINT [DF_RMAShippingItemAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  CONSTRAINT [DF_RMAShippingItemAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT            CONSTRAINT [DF_RMAAI_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT            CONSTRAINT [DF_RMAAI_IsDeleted] DEFAULT ((0)) NOT NULL,
    [PDFPath]                NVARCHAR (MAX) NULL,
    [FedexPdfPath]           VARCHAR (MAX)  NULL,
    CONSTRAINT [PK_RMAShippingItemAudit] PRIMARY KEY CLUSTERED ([AuditRMAShippingItemId] ASC),
    CONSTRAINT [FK_RMAShippingItemAudit_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_RMAShippingItemAudit_RMAPickTicket] FOREIGN KEY ([RMAPickTicketId]) REFERENCES [dbo].[RMAPickTicket] ([RMAPickTicketId])
);

