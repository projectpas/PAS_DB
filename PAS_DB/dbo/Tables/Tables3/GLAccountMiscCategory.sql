CREATE TABLE [dbo].[GLAccountMiscCategory] (
    [GLAccountMiscCategoryId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Name]                    VARCHAR (30)  NOT NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [GLAccountMiscCategory_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [GLAccountMiscCategory_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT           CONSTRAINT [GLAccountMiscCategory_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           CONSTRAINT [GLAccountMiscCategory_DC_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_GLAccountMiscCategory] PRIMARY KEY CLUSTERED ([GLAccountMiscCategoryId] ASC),
    CONSTRAINT [FK_GLAccountMiscCategory_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_GLAccountMiscCategory] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_GLAccountMiscCategoryAudit]

   ON  [dbo].[GLAccountMiscCategory]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO GLAccountMiscCategoryAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END