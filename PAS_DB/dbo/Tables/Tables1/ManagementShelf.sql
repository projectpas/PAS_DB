CREATE TABLE [dbo].[ManagementShelf] (
    [ManagementShelfId]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [ManagementStructureId] BIGINT        NOT NULL,
    [ShelfId]               BIGINT        NOT NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [DF_ManagementShelf_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [DF_ManagementShelf_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [ManagementShelf_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [ManagementShelf_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ManagementShelf] PRIMARY KEY CLUSTERED ([ManagementShelfId] ASC),
    CONSTRAINT [FK_ManagementShelf_ManagementStructure] FOREIGN KEY ([ManagementStructureId]) REFERENCES [dbo].[ManagementStructure] ([ManagementStructureId]),
    CONSTRAINT [FK_ManagementShelf_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_ManagementShelf_Shelf] FOREIGN KEY ([ShelfId]) REFERENCES [dbo].[Shelf] ([ShelfId])
);


GO




CREATE TRIGGER [dbo].[Trg_ManagementShelfAudit]

   ON  [dbo].[ManagementShelf]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ManagementShelfAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END