CREATE TABLE [dbo].[LegalEntityDomesticWireBanking] (
    [LegalEntityDomesticWireBankingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [LegalEntityId]                    BIGINT        NOT NULL,
    [DomesticWirePaymentId]            BIGINT        NOT NULL,
    [MasterCompanyId]                  INT           NOT NULL,
    [CreatedBy]                        VARCHAR (256) NOT NULL,
    [UpdatedBy]                        VARCHAR (256) NOT NULL,
    [CreatedDate]                      DATETIME2 (7) CONSTRAINT [LegalEntityDomesticWireBanking_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                      DATETIME2 (7) CONSTRAINT [LegalEntityDomesticWireBanking_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                         BIT           CONSTRAINT [DF_LegalEntityDomesticWireBanking_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                        BIT           CONSTRAINT [LegalEntityDomesticWireBanking_DC_Delete] DEFAULT ((0)) NOT NULL,
    [AccountName]                      VARCHAR (256) NULL,
    CONSTRAINT [PK_LegalEntityDomesticWireBanking] PRIMARY KEY CLUSTERED ([LegalEntityDomesticWireBankingId] ASC),
    CONSTRAINT [FK_LegalEntityDomesticWireBanking_InternationalWirePayment] FOREIGN KEY ([DomesticWirePaymentId]) REFERENCES [dbo].[DomesticWirePayment] ([DomesticWirePaymentId]),
    CONSTRAINT [FK_LegalEntityDomesticWireBanking_LegalEntity] FOREIGN KEY ([LegalEntityId]) REFERENCES [dbo].[LegalEntity] ([LegalEntityId]),
    CONSTRAINT [FK_LegalEntityDomesticWireBanking_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO








CREATE TRIGGER [dbo].[Trg_LegalEntityDomesticWireBankingAudit]

   ON  [dbo].[LegalEntityDomesticWireBanking]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[LegalEntityDomesticWireBankingAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END