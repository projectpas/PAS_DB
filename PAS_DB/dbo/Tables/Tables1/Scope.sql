CREATE TABLE [dbo].[Scope] (
    [ScopeId]     TINYINT       IDENTITY (1, 1) NOT NULL,
    [Description] VARCHAR (100) NOT NULL,
    [CreatedBy]   VARCHAR (256) NULL,
    [UpdatedBy]   VARCHAR (256) NULL,
    [CreatedDate] DATETIME2 (7) NOT NULL,
    [UpdatedDate] DATETIME2 (7) NOT NULL,
    [IsActive]    BIT           NULL,
    CONSTRAINT [PK_Scope] PRIMARY KEY CLUSTERED ([ScopeId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_ScopeAudit]

   ON  [dbo].[Scope]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ScopeAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END