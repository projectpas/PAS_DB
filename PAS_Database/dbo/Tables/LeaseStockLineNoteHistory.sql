CREATE TABLE [dbo].[LeaseStockLineNoteHistory] (
    [LeaseStockLineNoteHistoryId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [LeaseStocklineId]            BIGINT         NOT NULL,
    [Description]                 NVARCHAR (MAX) NOT NULL,
    [EnteredBy]                   VARCHAR (256)  NOT NULL,
    [CreatedDate]                 DATETIME2 (7)  CONSTRAINT [DF_LeaseStockLineNoteHistory_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [EditedBy]                    VARCHAR (256)  NULL,
    [UpdatedDate]                 DATETIME2 (7)  NULL,
    [MasterCompanyId]             INT            NOT NULL,
    [IsActive]                    BIT            CONSTRAINT [DF_LeaseStockLineNoteHistory_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT            CONSTRAINT [DF_LeaseStockLineNoteHistory_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LeaseStockLineNoteHistory] PRIMARY KEY CLUSTERED ([LeaseStockLineNoteHistoryId] ASC),
    CONSTRAINT [FK_LeaseStockLineNoteHistory_LeaseStockline] FOREIGN KEY ([LeaseStocklineId]) REFERENCES [dbo].[LeaseStockline] ([LeaseStocklineId]),
    CONSTRAINT [FK_LeaseStockLineNoteHistory_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO
CREATE NONCLUSTERED INDEX [IX_LeaseStockLineNoteHistory_LeaseStocklineId]
    ON [dbo].[LeaseStockLineNoteHistory]([LeaseStocklineId] ASC);


GO

-- CREATE OR ALTER : safe to run again
CREATE   TRIGGER [dbo].[Trg_LeaseStockLineNoteHistoryAudit]
   ON  [dbo].[LeaseStockLineNoteHistory]
   AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON;

	-- Handles INSERT and UPDATE (rows exist in INSERTED) - the new values of the note
	IF EXISTS (SELECT 1 FROM INSERTED)
	BEGIN
		INSERT INTO [dbo].[LeaseStockLineNoteHistoryAudit] ([LeaseStockLineNoteHistoryId], [LeaseStocklineId], [Description], [EnteredBy], [CreatedDate], [EditedBy], [UpdatedDate], [MasterCompanyId], [IsActive], [IsDeleted])
		SELECT I.[LeaseStockLineNoteHistoryId], I.[LeaseStocklineId], I.[Description], I.[EnteredBy], I.[CreatedDate], I.[EditedBy], I.[UpdatedDate], I.[MasterCompanyId], I.[IsActive], I.[IsDeleted] FROM INSERTED I
	END

	-- Handles DELETE (rows exist only in DELETED)
	IF EXISTS (SELECT 1 FROM DELETED) AND NOT EXISTS (SELECT 1 FROM INSERTED)
	BEGIN
		INSERT INTO [dbo].[LeaseStockLineNoteHistoryAudit] ([LeaseStockLineNoteHistoryId], [LeaseStocklineId], [Description], [EnteredBy], [CreatedDate], [EditedBy], [UpdatedDate], [MasterCompanyId], [IsActive], [IsDeleted])
		SELECT D.[LeaseStockLineNoteHistoryId], D.[LeaseStocklineId], D.[Description], D.[EnteredBy], D.[CreatedDate], D.[EditedBy], D.[UpdatedDate], D.[MasterCompanyId], D.[IsActive], D.[IsDeleted] FROM DELETED D
	END
END