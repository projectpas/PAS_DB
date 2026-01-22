CREATE TABLE [dbo].[ItemCategory] (
    [ItemCategoryId]  TINYINT       IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (50)  NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NULL,
    [UpdatedBy]       VARCHAR (256) NULL,
    [CreatedDate]     DATETIME2 (7) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) NOT NULL,
    [IsActive]        BIT           NULL,
    CONSTRAINT [PK_ItemCategory] PRIMARY KEY CLUSTERED ([ItemCategoryId] ASC),
    CONSTRAINT [FK_ItemCategory_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_ItemCategoryAudit]

   ON  [dbo].[ItemCategory]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ItemCategoryAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END