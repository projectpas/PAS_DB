CREATE TABLE [dbo].[RestrictedParts] (
    [RestrictedPartId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ModuleId]         BIGINT         NOT NULL,
    [ReferenceId]      BIGINT         NOT NULL,
    [ItemMasterId]     BIGINT         NOT NULL,
    [PartNumber]       VARCHAR (100)  NULL,
    [PartType]         VARCHAR (20)   NULL,
    [CreatedDate]      DATETIME2 (7)  NOT NULL,
    [CreatedBy]        VARCHAR (256)  NULL,
    [UpdatedDate]      DATETIME2 (7)  NOT NULL,
    [UpdatedBy]        VARCHAR (256)  NULL,
    [IsActive]         BIT            NULL,
    [IsDeleted]        BIT            NULL,
    [Memo]             NVARCHAR (MAX) DEFAULT ('') NULL,
    CONSTRAINT [PK_RestrictedParts] PRIMARY KEY CLUSTERED ([RestrictedPartId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_RestrictedPartsAudit]

   ON  [dbo].[RestrictedParts]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO RestrictedPartsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END