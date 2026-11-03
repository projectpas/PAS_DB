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

