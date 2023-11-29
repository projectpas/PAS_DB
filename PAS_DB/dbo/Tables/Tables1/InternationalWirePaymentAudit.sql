﻿CREATE TABLE [dbo].[InternationalWirePaymentAudit] (
    [InternationalWirePaymentAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [InternationalWirePaymentId]      BIGINT        NOT NULL,
    [SwiftCode]                       VARCHAR (50)  NULL,
    [BeneficiaryBankAccount]          VARCHAR (50)  NULL,
    [BeneficiaryBank]                 VARCHAR (100) NULL,
    [BankName]                        VARCHAR (100) NULL,
    [IntermediaryBank]                VARCHAR (100) NULL,
    [BankAddressId]                   BIGINT        NULL,
    [BeneficiaryCustomer]             VARCHAR (100) NULL,
    [MasterCompanyId]                 INT           NOT NULL,
    [CreatedBy]                       VARCHAR (256) NOT NULL,
    [UpdatedBy]                       VARCHAR (256) NOT NULL,
    [CreatedDate]                     DATETIME2 (7) NOT NULL,
    [UpdatedDate]                     DATETIME2 (7) NOT NULL,
    [IsActive]                        BIT           NOT NULL,
    [IsDeleted]                       BIT           NOT NULL,
    [ABA]                             VARCHAR (256) NULL,
    [BeneficiaryCustomerId]           BIGINT        NULL,
    [BankLocation1]                   VARCHAR (250) NULL,
    [BankLocation2]                   VARCHAR (250) NULL,
    [GLAccountId]                     BIGINT        NULL,
    [VendorBankAccountTypeId]         INT           NULL,
    CONSTRAINT [PK_InternationalWirePaymentAudit] PRIMARY KEY CLUSTERED ([InternationalWirePaymentAuditId] ASC),
    CONSTRAINT [FK_InternationalWirePaymentAudit_InternationalWirePayment] FOREIGN KEY ([InternationalWirePaymentId]) REFERENCES [dbo].[InternationalWirePayment] ([InternationalWirePaymentId])
);



