CREATE TABLE [dbo].[NonPOInvoiceHeaderStatus] (
    [NonPOInvoiceHeaderStatusId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Description]                VARCHAR (256) NOT NULL,
    [MasterCompanyId]            INT           NOT NULL,
    [CreatedBy]                  VARCHAR (256) NOT NULL,
    [CreatedDate]                VARCHAR (256) NOT NULL,
    [UpdatedBy]                  VARCHAR (256) NOT NULL,
    [UpdatedDate]                VARCHAR (256) NOT NULL,
    [IsActive]                   BIT           CONSTRAINT [NonPOInvoiceHeaderStatus_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT           CONSTRAINT [DF_NonPOInvoiceHeaderStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_PurchaseOrderPartReference] PRIMARY KEY CLUSTERED ([NonPOInvoiceHeaderStatusId] ASC)
);

