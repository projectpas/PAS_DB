CREATE TABLE [dbo].[FileSystem] (
    [FileSystemId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [FilePath]        VARCHAR (1000) NOT NULL,
    [FileType]        VARCHAR (30)   NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NULL,
    [UpdatedBy]       VARCHAR (256)  NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            NULL,
    CONSTRAINT [PK_FileSystem] PRIMARY KEY CLUSTERED ([FileSystemId] ASC),
    CONSTRAINT [FK_FileSystem_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_FileSystemudit]

   ON  [dbo].[FileSystem]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO FileSystemAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END