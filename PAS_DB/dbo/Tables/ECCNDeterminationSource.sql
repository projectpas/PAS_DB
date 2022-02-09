CREATE TABLE [dbo].[ECCNDeterminationSource] (
    [EccnDeterminationSourceID] INT           IDENTITY (1, 1) NOT NULL,
    [Name]                      VARCHAR (100) NOT NULL,
    [Description]               VARCHAR (100) NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (50)  NOT NULL,
    [CreatedOn]                 DATETIME      NOT NULL,
    [UpdatedBy]                 VARCHAR (50)  NULL,
    [UpdatedOn]                 DATETIME      NULL,
    [IsActive]                  BIT           NOT NULL,
    [IsDeleted]                 BIT           NOT NULL,
    CONSTRAINT [PK_ECCNDeterminationSource] PRIMARY KEY CLUSTERED ([EccnDeterminationSourceID] ASC)
);


GO
CREATE TRIGGER [dbo].[TrgECCNDeterminationSourceAudit]
   ON  [dbo].[ECCNDeterminationSource]
AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO ECCNDeterminationSourceAudit
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END