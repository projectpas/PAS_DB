CREATE TABLE [dbo].[ECCNDeterminationSource] (
    [EccnDeterminationSourceID] INT           IDENTITY (1, 1) NOT NULL,
    [Name]                      VARCHAR (100) NOT NULL,
    [Description]               VARCHAR (100) NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (50)  NOT NULL,
    [CreatedDate]               DATETIME      CONSTRAINT [DF_ECCNDeterminationSource_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                 VARCHAR (50)  NOT NULL,
    [UpdatedDate]               DATETIME      CONSTRAINT [DF_ECCNDeterminationSource_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT           CONSTRAINT [DF_ECCNDeterminationSource_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT           CONSTRAINT [DF_ECCNDeterminationSource_IsDeleted] DEFAULT ((0)) NOT NULL,
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