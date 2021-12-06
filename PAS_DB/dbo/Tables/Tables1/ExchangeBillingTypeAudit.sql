CREATE TABLE [dbo].[ExchangeBillingTypeAudit] (
    [AuditExchangeBillingTypeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ExchangeBillingTypeId]      BIGINT         NOT NULL,
    [Description]                VARCHAR (100)  NOT NULL,
    [Memo]                       NVARCHAR (MAX) NULL,
    [MasterCompanyId]            INT            NOT NULL,
    [CreatedBy]                  VARCHAR (256)  NOT NULL,
    [UpdatedBy]                  VARCHAR (256)  NOT NULL,
    [CreatedDate]                DATETIME2 (7)  CONSTRAINT [DF_ExchangeBillingTypeAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                DATETIME2 (7)  CONSTRAINT [DF_ExchangeBillingTypeAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                   BIT            CONSTRAINT [DF_ExchangeBillingTypeAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT            CONSTRAINT [DF_ExchangeBillingTypeAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ExchangeBillingTypeAudit] PRIMARY KEY CLUSTERED ([AuditExchangeBillingTypeId] ASC),
    CONSTRAINT [FK_ExchangeBillingTypeAudit_ExchangeBillingType] FOREIGN KEY ([ExchangeBillingTypeId]) REFERENCES [dbo].[ExchangeBillingType] ([ExchangeBillingTypeId])
);

