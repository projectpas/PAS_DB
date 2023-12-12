CREATE TABLE [dbo].[UserRoleLevel] (
    [UserRoleLevelId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (100) NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NULL,
    [UpdatedBy]       VARCHAR (256) NULL,
    [CreatedDate]     DATETIME2 (7) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) NOT NULL,
    [IsActive]        NCHAR (10)    NULL,
    CONSTRAINT [PK_UserRoleLevel] PRIMARY KEY CLUSTERED ([UserRoleLevelId] ASC),
    CONSTRAINT [FK_UserRoleLevel_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_UserRoleLevelAudit]

   ON  [dbo].[UserRoleLevel]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO UserRoleLevelAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END