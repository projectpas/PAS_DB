CREATE TABLE [dbo].[LegalEntityDomesticWireBankingAudit] (
    [LegalEntityDomesticWireBankingAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [LegalEntityDomesticWireBankingId]      BIGINT        NOT NULL,
    [LegalEntityId]                         BIGINT        NOT NULL,
    [DomesticWirePaymentId]                 BIGINT        NOT NULL,
    [MasterCompanyId]                       INT           NOT NULL,
    [CreatedBy]                             VARCHAR (256) NOT NULL,
    [UpdatedBy]                             VARCHAR (256) NOT NULL,
    [CreatedDate]                           DATETIME2 (7) CONSTRAINT [DF_LegalEntityDomesticWireBankingAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                           DATETIME2 (7) CONSTRAINT [DF_LegalEntityDomesticWireBankingAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                              BIT           CONSTRAINT [DF_LegalEntityDomesticWireBankingAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                             BIT           CONSTRAINT [DF_LegalEntityDomesticWireBankingAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [AccountName]                           VARCHAR (256) NULL,
    CONSTRAINT [PK_LegalEntityDomesticWireBankingAudit] PRIMARY KEY CLUSTERED ([LegalEntityDomesticWireBankingAuditId] ASC)
);

