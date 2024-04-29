CREATE TABLE [dbo].[CustomerInvoiceType] (
    [CustomerInvoiceTypeId] INT           IDENTITY (1, 1) NOT NULL,
    [ModuleName]            VARCHAR (150) NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (50)  NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [DF_CustomerInvoiceType_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]             VARCHAR (50)  NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [DF_CustomerInvoiceType_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [DF__CustomerInvoiceType__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [DF__CustomerInvoiceType__IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CustomerInvoiceType] PRIMARY KEY CLUSTERED ([CustomerInvoiceTypeId] ASC)
);

