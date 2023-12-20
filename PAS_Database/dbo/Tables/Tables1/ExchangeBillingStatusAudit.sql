CREATE TABLE [dbo].[ExchangeBillingStatusAudit] (
    [AuditExchangeBillingStatusId] INT          IDENTITY (1, 1) NOT NULL,
    [ExchangeBillingStatusId]      INT          NOT NULL,
    [Name]                         VARCHAR (50) NOT NULL,
    [MasterCompanyId]              INT          NOT NULL,
    [CreatedBy]                    VARCHAR (50) NOT NULL,
    [CreatedOn]                    DATETIME     CONSTRAINT [DF_ExchangeBillingStatusAudit_CreatedOn] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                    VARCHAR (50) NULL,
    [UpdatedOn]                    DATETIME     CONSTRAINT [DF_ExchangeBillingStatusAudit_UpdatedOn] DEFAULT (getdate()) NULL,
    [IsActive]                     BIT          CONSTRAINT [DF_ExchangeBillingStatusAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                    BIT          CONSTRAINT [DF_ExchangeBillingStatusAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ExchangeBillingStatusAudit] PRIMARY KEY CLUSTERED ([AuditExchangeBillingStatusId] ASC),
    CONSTRAINT [FK_ExchangeBillingStatusAudit_ExchangeBillingStatus] FOREIGN KEY ([ExchangeBillingStatusId]) REFERENCES [dbo].[ExchangeBillingStatus] ([ExchangeBillingStatusId])
);

