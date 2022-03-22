CREATE TABLE [dbo].[ExpertiseType] (
    [ExpertiseTypeId] SMALLINT       IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (100)  NOT NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NULL,
    [UpdatedBy]       VARCHAR (256)  NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            NULL,
    [IsDeleted]       BIT            NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_ExpertiseType] PRIMARY KEY CLUSTERED ([ExpertiseTypeId] ASC),
    CONSTRAINT [FK_ExpertiseType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_ExpertiseTypeAudit]

   ON  [dbo].[ExpertiseType]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ExpertiseTypeAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END