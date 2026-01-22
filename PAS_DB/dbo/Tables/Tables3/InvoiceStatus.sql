CREATE TABLE [dbo].[InvoiceStatus] (
    [InvoiceStatusId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Status]          VARCHAR (400) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (50)  NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_InvoiceStatus_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (50)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_InvoiceStatus_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF__InvoiceStatus__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF__InvoiceStatus__IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_InvoiceStatus] PRIMARY KEY CLUSTERED ([InvoiceStatusId] ASC)
);

