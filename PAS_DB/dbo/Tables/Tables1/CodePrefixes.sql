CREATE TABLE [dbo].[CodePrefixes] (
    [CodePrefixId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [CodeTypeId]      BIGINT         NOT NULL,
    [CurrentNummber]  BIGINT         CONSTRAINT [DF_CodePrefixes_CurrentNummber] DEFAULT ((0)) NULL,
    [CodePrefix]      VARCHAR (10)   NOT NULL,
    [CodeSufix]       VARCHAR (10)   NULL,
    [StartsFrom]      BIGINT         NOT NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_CodePrefixes_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_CodePrefixes_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_CodePrefixes_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_CodePrefixes_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Description]     VARCHAR (250)  DEFAULT ('') NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_CodePrefix] PRIMARY KEY CLUSTERED ([CodePrefixId] ASC),
    CONSTRAINT [FK_CodePrefixes_CodeTypes] FOREIGN KEY ([CodeTypeId]) REFERENCES [dbo].[CodeTypes] ([CodeTypeId]),
    CONSTRAINT [FK_CodePrefixes_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_CodePrefixesAudit]

   ON  [dbo].[CodePrefixes]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN

	DECLARE @CurrentNummber BIGINT, @CodePrefixId BIGINT, @CodeTypeId BIGINT,@CodeType VARCHAR(100)



	SELECT @CodePrefixId=CodePrefixId, @CodeTypeId=CodeTypeId FROM INSERTED

	SELECT @CodeType=CodeType FROM CodeTypes WHERE CodeTypeId=@CodeTypeId



	INSERT INTO CodePrefixesAudit

	SELECT *,@CodeType FROM INSERTED



	SELECT @CurrentNummber=CurrentNummber FROM CodePrefixes WHERE CodePrefixId=@CodePrefixId



	IF(@CurrentNummber IS NULL OR @CurrentNummber=0)

		UPDATE CodePrefixes SET CurrentNummber=StartsFrom WHERE CodePrefixId=@CodePrefixId



	SET NOCOUNT ON;



END