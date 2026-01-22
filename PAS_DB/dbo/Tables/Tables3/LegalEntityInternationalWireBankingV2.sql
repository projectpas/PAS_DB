CREATE TABLE [dbo].[LegalEntityInternationalWireBankingV2] (
    [LegalEntityInternationalWireBankingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [LegalEntityId]                         BIGINT        NOT NULL,
    [InternationalWirePaymentId]            BIGINT        NOT NULL,
    [MasterCompanyId]                       INT           NOT NULL,
    [CreatedBy]                             VARCHAR (256) NOT NULL,
    [UpdatedBy]                             VARCHAR (256) NOT NULL,
    [CreatedDate]                           DATETIME2 (7) CONSTRAINT [LegalEntityInternationalWireBankingV2_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                           DATETIME2 (7) CONSTRAINT [LegalEntityInternationalWireBankingV2_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                              BIT           CONSTRAINT [DF_LegalEntityInternationalWireBankingV2_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                             BIT           CONSTRAINT [LegalEntityInternationalWireBankingV2_DC_Delete] DEFAULT ((0)) NOT NULL,
    [IsPrimay]                              BIT           NULL,
    CONSTRAINT [PK_LegalEntityInternationalWireBankingV2] PRIMARY KEY CLUSTERED ([LegalEntityInternationalWireBankingId] ASC),
    CONSTRAINT [FK_LegalEntityInternationalWireBankingV2_InternationalWirePaymentV2] FOREIGN KEY ([InternationalWirePaymentId]) REFERENCES [dbo].[InternationalWirePaymentV2] ([InternationalWirePaymentId]),
    CONSTRAINT [FK_LegalEntityInternationalWireBankingV2_LegalEntity] FOREIGN KEY ([LegalEntityId]) REFERENCES [dbo].[LegalEntity] ([LegalEntityId]),
    CONSTRAINT [FK_LegalEntityInternationalWireBankingV2_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

