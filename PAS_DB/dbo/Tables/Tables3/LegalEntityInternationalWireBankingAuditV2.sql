CREATE TABLE [dbo].[LegalEntityInternationalWireBankingAuditV2] (
    [LegalEntityInternationalWireBankingAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [LegalEntityInternationalWireBankingId]      BIGINT        NOT NULL,
    [LegalEntityId]                              BIGINT        NOT NULL,
    [InternationalWirePaymentId]                 BIGINT        NOT NULL,
    [MasterCompanyId]                            INT           NOT NULL,
    [CreatedBy]                                  VARCHAR (256) NOT NULL,
    [UpdatedBy]                                  VARCHAR (256) NOT NULL,
    [CreatedDate]                                DATETIME2 (7) CONSTRAINT [DF_LegalEntityInternationalWireBankingAuditV2_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                                DATETIME2 (7) CONSTRAINT [DF_LegalEntityInternationalWireBankingAuditV2_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                                   BIT           CONSTRAINT [DF_LegalEntityInternationalWireBankingAuditV2_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                                  BIT           CONSTRAINT [DF_LegalEntityInternationalWireBankingAuditV2_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsPrimay]                                   BIT           NULL,
    CONSTRAINT [PK_LegalEntityInternationalWireBankingAuditV2] PRIMARY KEY CLUSTERED ([LegalEntityInternationalWireBankingAuditId] ASC)
);

