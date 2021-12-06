CREATE TABLE [dbo].[LegalEntityInternationalWireBanking] (
    [LegalEntityInternationalWireBankingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [LegalEntityId]                         BIGINT        NOT NULL,
    [InternationalWirePaymentId]            BIGINT        NOT NULL,
    [MasterCompanyId]                       INT           NOT NULL,
    [CreatedBy]                             VARCHAR (256) NOT NULL,
    [UpdatedBy]                             VARCHAR (256) NOT NULL,
    [CreatedDate]                           DATETIME2 (7) CONSTRAINT [LegalEntityInternationalWireBanking_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                           DATETIME2 (7) CONSTRAINT [LegalEntityInternationalWireBanking_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                              BIT           CONSTRAINT [DF_LegalEntityInternationalWireBanking_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                             BIT           CONSTRAINT [LegalEntityInternationalWireBanking_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LegalEntityInternationalWireBanking] PRIMARY KEY CLUSTERED ([LegalEntityInternationalWireBankingId] ASC),
    CONSTRAINT [FK_LegalEntityInternationalWireBanking_InternationalWirePayment] FOREIGN KEY ([InternationalWirePaymentId]) REFERENCES [dbo].[InternationalWirePayment] ([InternationalWirePaymentId]),
    CONSTRAINT [FK_LegalEntityInternationalWireBanking_LegalEntity] FOREIGN KEY ([LegalEntityId]) REFERENCES [dbo].[LegalEntity] ([LegalEntityId]),
    CONSTRAINT [FK_LegalEntityInternationalWireBanking_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO








CREATE TRIGGER [dbo].[Trg_LegalEntityInternationalWireBankingAudit]

   ON  [dbo].[LegalEntityInternationalWireBanking]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[LegalEntityInternationalWireBankingAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END