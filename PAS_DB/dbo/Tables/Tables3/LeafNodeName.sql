CREATE TABLE [dbo].[LeafNodeName] (
    [LeafNodeNameId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (256)  NOT NULL,
    [Description]     VARCHAR (MAX)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [LeafNodeName_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [LeafNodeName_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [LeafNodeName_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [LeafNodeName_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LeafNodeName] PRIMARY KEY CLUSTERED ([LeafNodeNameId] ASC),
    CONSTRAINT [FK_LeafNodeName_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_LeafNodeName] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);


GO






CREATE TRIGGER [dbo].[Trg_LeafNodeNameAudit]

   ON  [dbo].[LeafNodeName]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO LeafNodeNameAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END