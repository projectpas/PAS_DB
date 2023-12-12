CREATE TABLE [dbo].[DomesticWirePaymentAudit] (
    [DomesticWirePaymentAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [DomesticWirePaymentId]      BIGINT        NOT NULL,
    [ABA]                        VARCHAR (50)  NOT NULL,
    [AccountNumber]              VARCHAR (50)  NOT NULL,
    [BankName]                   VARCHAR (100) NOT NULL,
    [BenificiaryBankName]        VARCHAR (100) NULL,
    [IntermediaryBankName]       VARCHAR (100) NULL,
    [BankAddressId]              BIGINT        NULL,
    [MasterCompanyId]            INT           NOT NULL,
    [CreatedBy]                  VARCHAR (256) NOT NULL,
    [UpdatedBy]                  VARCHAR (256) NOT NULL,
    [CreatedDate]                DATETIME2 (7) NOT NULL,
    [UpdatedDate]                DATETIME2 (7) NOT NULL,
    [IsActive]                   BIT           NOT NULL,
    [IsDeleted]                  BIT           NOT NULL,
    [AccountNameId]              BIGINT        NULL,
    [VendorBankAccountTypeId]    INT           NULL,
    CONSTRAINT [PK_DomesticWirePaymentAuditId] PRIMARY KEY CLUSTERED ([DomesticWirePaymentAuditId] ASC),
    CONSTRAINT [FK_DomesticWirePaymentAudit_DomesticWirePayment] FOREIGN KEY ([DomesticWirePaymentId]) REFERENCES [dbo].[DomesticWirePayment] ([DomesticWirePaymentId])
);

