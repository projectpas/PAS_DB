CREATE TABLE [dbo].[ItemGroup] (
    [ItemGroupId]     BIGINT         IDENTITY (1, 1) NOT NULL,
    [ItemGroupCode]   VARCHAR (30)   NOT NULL,
    [Description]     VARCHAR (256)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [ItemGroup_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [ItemGroup_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [ItemGroup_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [ItemGroup_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ItemGroup] PRIMARY KEY CLUSTERED ([ItemGroupId] ASC),
    CONSTRAINT [FK_ItemGroup_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UQ_ItemGroup_codes] UNIQUE NONCLUSTERED ([ItemGroupCode] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_ItemgroupAudit]

   ON  [dbo].[ItemGroup]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO ItemgroupAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END