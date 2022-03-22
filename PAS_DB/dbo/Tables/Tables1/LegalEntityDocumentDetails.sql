CREATE TABLE [dbo].[LegalEntityDocumentDetails] (
    [LegalEntityDocumentDetailId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [LegalEntityId]               BIGINT         NOT NULL,
    [AttachmentId]                BIGINT         NOT NULL,
    [DocName]                     VARCHAR (100)  NULL,
    [DocMemo]                     NVARCHAR (MAX) NULL,
    [DocDescription]              VARCHAR (100)  NULL,
    [MasterCompanyId]             INT            NOT NULL,
    [CreatedBy]                   VARCHAR (256)  NOT NULL,
    [UpdatedBy]                   VARCHAR (256)  NOT NULL,
    [CreatedDate]                 DATETIME2 (7)  CONSTRAINT [LegalEntityDocumentDetails_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)  CONSTRAINT [LegalEntityDocumentDetails_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT            CONSTRAINT [LegalEntityDocumentDetails_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT            CONSTRAINT [LegalEntityDocumentDetails_DC_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LegalEntityDocumentDetails] PRIMARY KEY CLUSTERED ([LegalEntityDocumentDetailId] ASC),
    CONSTRAINT [FK_LegalEntityDocumentDetails_Attachment] FOREIGN KEY ([AttachmentId]) REFERENCES [dbo].[Attachment] ([AttachmentId]),
    CONSTRAINT [FK_LegalEntityDocumentDetails_LegalEntity] FOREIGN KEY ([LegalEntityId]) REFERENCES [dbo].[LegalEntity] ([LegalEntityId]),
    CONSTRAINT [UQ_LegalEntityDocumentDeatails] UNIQUE NONCLUSTERED ([LegalEntityId] ASC, [MasterCompanyId] ASC, [AttachmentId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_LegalEntityDocumentDetailsAudit]

   ON  [dbo].[LegalEntityDocumentDetails]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO LegalEntityDocumentDetailsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END