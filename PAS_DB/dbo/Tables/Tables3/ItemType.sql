CREATE TABLE [dbo].[ItemType] (
    [ItemTypeId]      INT            IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (256)  NOT NULL,
    [IsActive]        BIT            CONSTRAINT [ItemType_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [ItemType_DC_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Name]            VARCHAR (256)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [ItemType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [ItemType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [MasterCompanyId] INT            NOT NULL,
    CONSTRAINT [PK_ItemType] PRIMARY KEY CLUSTERED ([ItemTypeId] ASC),
    CONSTRAINT [Unique_ItemType] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_ItemgTypeAudit]

   ON  [dbo].[ItemType]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO ItemTypeAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END