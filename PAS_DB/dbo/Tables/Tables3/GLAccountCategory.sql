CREATE TABLE [dbo].[GLAccountCategory] (
    [GLAccountCategoryId]   BIGINT        IDENTITY (1, 1) NOT NULL,
    [GLAccountCategoryName] VARCHAR (200) NOT NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [GLAccountCategory_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [GLAccountCategory_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [GLAccountCategory_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [GLAccountCategory_DC_Delete] DEFAULT ((0)) NOT NULL,
    [GLCID]                 INT           NOT NULL,
    CONSTRAINT [PK_GLAccountCategory] PRIMARY KEY CLUSTERED ([GLAccountCategoryId] ASC),
    CONSTRAINT [FK_GLAccountCategory_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_GLAccountCategory] UNIQUE NONCLUSTERED ([GLAccountCategoryName] ASC, [MasterCompanyId] ASC),
    CONSTRAINT [Unique_GLAccountCategoryGLCID] UNIQUE NONCLUSTERED ([GLCID] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_GLAccountCategory] ON [dbo].[GLAccountCategory] FOR INSERT, UPDATE, DELETE

AS

SET NOCOUNT ON;

INSERT [dbo].[GLAccountCategoryAudit] ([GLAccountCategoryId]

           ,[GLAccountCategoryName]

           ,[MasterCompanyId]

           ,[CreatedBy]

           ,[UpdatedBy]

           ,[CreatedDate]

           ,[UpdatedDate]

           ,[IsActive]

           ,[IsDeleted]

		   ,[GLCID])

SELECT

   I.[GLAccountCategoryId],

   I.[GLAccountCategoryName],

   I.[MasterCompanyId],

    I.[CreatedBy],

    I.[UpdatedBy],

    I.[CreatedDate],

    I.[UpdatedDate],

    I.[IsActive],

    I.[IsDeleted],

	I.[GLCID]

FROM

   Inserted I

UNION ALL

SELECT

   D.[GLAccountCategoryId],

   D.[GLAccountCategoryName],

   D.[MasterCompanyId],

    D.[CreatedBy],

    D.[UpdatedBy],

    D.[CreatedDate],

    D.[UpdatedDate],

    D.[IsActive],

    D.[IsDeleted],

	D.[GLCID]

FROM Deleted D

WHERE NOT EXISTS (

   SELECT * FROM Inserted

);