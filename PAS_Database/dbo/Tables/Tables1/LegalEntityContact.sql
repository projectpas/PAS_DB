CREATE TABLE [dbo].[LegalEntityContact] (
    [LegalEntityContactId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [LegalEntityId]        BIGINT        NOT NULL,
    [ContactId]            BIGINT        NOT NULL,
    [IsDefaultContact]     BIT           CONSTRAINT [LegalEntityContact_DC_IsDefaultContact] DEFAULT ((0)) NOT NULL,
    [Tag]                  VARCHAR (255) DEFAULT ('') NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [LegalEntityContact_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [LegalEntityContact_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [LegalEntityContact_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [LegalEntityContact_DC_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LegalEntityContact] PRIMARY KEY CLUSTERED ([LegalEntityContactId] ASC),
    CONSTRAINT [FK_LegalEntityContact_Contact] FOREIGN KEY ([ContactId]) REFERENCES [dbo].[Contact] ([ContactId]),
    CONSTRAINT [FK_LegalEntityContact_LegalEntity] FOREIGN KEY ([LegalEntityId]) REFERENCES [dbo].[LegalEntity] ([LegalEntityId]),
    CONSTRAINT [FK_LegalEntityContact_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_LegalEntityContactAudit]

   ON  [dbo].[LegalEntityContact]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO LegalEntityContactAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END