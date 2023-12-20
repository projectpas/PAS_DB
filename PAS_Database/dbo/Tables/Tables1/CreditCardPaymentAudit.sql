CREATE TABLE [dbo].[CreditCardPaymentAudit] (
    [CreditCardPaymentAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CreditCardPaymentId]      BIGINT        NOT NULL,
    [CustomerId]               BIGINT        NOT NULL,
    [CustomerFinancialId]      BIGINT        NOT NULL,
    [PaymentMethodId]          BIGINT        NOT NULL,
    [CardNumber]               VARCHAR (100) NULL,
    [CardHolderName]           VARCHAR (100) NULL,
    [Address]                  VARCHAR (250) NULL,
    [State]                    VARCHAR (100) NULL,
    [PostalCode]               VARCHAR (100) NULL,
    [InActive]                 BIT           NOT NULL,
    [IsDefault]                BIT           NOT NULL,
    [ExpirationDate]           DATETIME2 (7) NOT NULL,
    [MasterCompanyId]          INT           NOT NULL,
    [CreatedBy]                VARCHAR (256) NOT NULL,
    [CreatedDate]              DATETIME2 (7) CONSTRAINT [DF_CreditCardPaymentAudit_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                VARCHAR (256) NOT NULL,
    [UpdatedDate]              DATETIME2 (7) CONSTRAINT [DF_CreditCardPaymentAudit_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                 BIT           CONSTRAINT [DF_CreditCardPaymentAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT           CONSTRAINT [DF_CreditCardPaymentAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CreditCardPaymentAudit] PRIMARY KEY CLUSTERED ([CreditCardPaymentAuditId] ASC)
);

