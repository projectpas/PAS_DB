CREATE TABLE [dbo].[LegalEntityTagNameMapping] (
    [TagNameMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [TagName]          VARCHAR (256) NOT NULL,
    [LegalEntityId]    BIGINT        NOT NULL,
    [CreatedBy]        VARCHAR (256) NOT NULL,
    [UpdatedBy]        VARCHAR (256) NOT NULL,
    [CreatedDate]      DATETIME2 (7) NOT NULL,
    [UpdatedDate]      DATETIME2 (7) NOT NULL,
    [IsActive]         BIT           NOT NULL,
    [IsDeleted]        BIT           NOT NULL,
    [MasterCompanyId]  INT           NULL,
    CONSTRAINT [PK_TagNameMapping] PRIMARY KEY CLUSTERED ([TagNameMappingId] ASC),
    CONSTRAINT [FK_LegalEntityTagNameMapping_LegalEntity] FOREIGN KEY ([LegalEntityId]) REFERENCES [dbo].[LegalEntity] ([LegalEntityId]),
    CONSTRAINT [FK_LegalEntityTagNameMapping_MasterCompnay] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO






CREATE TRIGGER [dbo].[Trg_LegalEntityTagNameMappingAudit]

   ON  [dbo].[LegalEntityTagNameMapping]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[LegalEntityTagNameMappingAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END