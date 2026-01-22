CREATE TABLE [dbo].[NonPOInvoiceHeaderPaymentMethod] (
    [NonPOInvoiceHeaderPaymentMethodId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Description]                       VARCHAR (256) NOT NULL,
    [MasterCompanyId]                   INT           NOT NULL,
    [CreatedBy]                         VARCHAR (256) NOT NULL,
    [CreatedDate]                       VARCHAR (256) CONSTRAINT [DF_NonPOInvoiceHeaderPaymentMethod_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                         VARCHAR (256) NOT NULL,
    [UpdatedDate]                       VARCHAR (256) CONSTRAINT [DF_NonPOInvoiceHeaderPaymentMethod_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                          BIT           CONSTRAINT [DF_NonPOInvoiceHeaderPaymentMethod_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                         BIT           CONSTRAINT [DF_NonPOInvoiceHeaderPaymentMethod_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_NonPOInvoiceHeaderPaymentMethod] PRIMARY KEY CLUSTERED ([NonPOInvoiceHeaderPaymentMethodId] ASC)
);

