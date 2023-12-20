CREATE TABLE [dbo].[ExpenditureCategory] (
    [ExpenditureCategoryId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]           VARCHAR (256)  NOT NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  CONSTRAINT [ExpenditureCategory_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  CONSTRAINT [ExpenditureCategory_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT            CONSTRAINT [ExpenditureCategory_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT            CONSTRAINT [ExpenditureCategory_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ExpenditureCategory] PRIMARY KEY CLUSTERED ([ExpenditureCategoryId] ASC),
    CONSTRAINT [FK_ExpenditureCategory_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UQ_ExpenditureCategory_codes] UNIQUE NONCLUSTERED ([Description] ASC, [MasterCompanyId] ASC)
);


GO








CREATE TRIGGER [dbo].[Trg_ExpenditureCategory] ON [dbo].[ExpenditureCategory] FOR INSERT, UPDATE, DELETE

AS

SET NOCOUNT ON;

INSERT [dbo].[ExpenditureCategoryAudit] ([ExpenditureCategoryId]

           ,[Description]

           ,[Memo]

           ,[MasterCompanyId]

           ,[CreatedBy]

           ,[UpdatedBy]

           ,[CreatedDate]

           ,[UpdatedDate]

           ,[IsActive]

           ,[IsDeleted])

SELECT

   I.[ExpenditureCategoryId],

   I.[Description],

   I.[Memo],

   I.[MasterCompanyId],

    I.[CreatedBy],

    I.[UpdatedBy],

    I.[CreatedDate],

    I.[UpdatedDate],

    I.[IsActive],

    I.[IsDeleted]

FROM

   Inserted I

UNION ALL

SELECT

   D.[ExpenditureCategoryId],

   D.[Description],

   D.[Memo],

   D.[MasterCompanyId],

    D.[CreatedBy],

    D.[UpdatedBy],

    D.[CreatedDate],

    D.[UpdatedDate],

    D.[IsActive],

    D.[IsDeleted]

FROM Deleted D

WHERE NOT EXISTS (

   SELECT * FROM Inserted

);