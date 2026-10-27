CREATE TABLE [dbo].[StocklineTimeCycleHistory] (
    [StocklineTimeCycleHistoryId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [StocklineId]                 BIGINT          NULL,
    [ModuleId]                    BIGINT          NULL,
    [ReferenceId]                 BIGINT          NULL,
    [ReferenceNumber]             VARCHAR (100)   NULL,
    [SubModuleId]                 BIGINT          NULL,
    [SubReferenceId]              BIGINT          NULL,
    [SubReferenceNumber]          VARCHAR (100)   NULL,
    [EntryType]                   VARCHAR (50)    NULL,
    [EntryDate]                   DATETIME2 (7)   NULL,
    [Hours]                       DECIMAL (18, 6) NULL,
    [Minutes]                     DECIMAL (18, 6) NULL,
    [Cycles]                      DECIMAL (18, 6) NULL,
    [TotalTSN]                    DECIMAL (18, 6) NULL,
    [TotalTSNMM]                  DECIMAL (18, 6) NULL,
    [TotalCSN]                    DECIMAL (18, 6) NULL,
    [TotalTSO]                    DECIMAL (18, 6) NULL,
    [TotalTSOMM]                  DECIMAL (18, 6) NULL,
    [TotalCSO]                    DECIMAL (18, 6) NULL,
    [Memo]                        NVARCHAR (MAX)  NULL,
    [MasterCompanyId]             INT             NULL,
    [CreatedBy]                   VARCHAR (256)   NULL,
    [CreatedDate]                 DATETIME2 (7)   CONSTRAINT [DF_StocklineTimeCycleHistory_CreatedDate] DEFAULT (getutcdate()) NULL,
    [UpdatedBy]                   VARCHAR (256)   NULL,
    [UpdatedDate]                 DATETIME2 (7)   CONSTRAINT [DF_StocklineTimeCycleHistory_UpdatedDate] DEFAULT (getutcdate()) NULL,
    [IsActive]                    BIT             CONSTRAINT [DF_StocklineTimeCycleHistory_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]                   BIT             CONSTRAINT [DF_StocklineTimeCycleHistory_IsDeleted] DEFAULT ((0)) NULL,
    [ParentStocklineId]           BIGINT          NULL,
    CONSTRAINT [PK_StocklineTimeCycleHistory] PRIMARY KEY CLUSTERED ([StocklineTimeCycleHistoryId] ASC),
    CONSTRAINT [FK_StocklineTimeCycleHistory_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_StocklineTimeCycleHistory_Stockline] FOREIGN KEY ([StocklineId]) REFERENCES [dbo].[Stockline] ([StockLineId])
);


GO
CREATE NONCLUSTERED INDEX [IX_StocklineTimeCycleHistory_Module_Reference]
    ON [dbo].[StocklineTimeCycleHistory]([ModuleId] ASC, [ReferenceId] ASC)
    INCLUDE([StocklineId], [SubModuleId], [SubReferenceId]);


GO
CREATE NONCLUSTERED INDEX [IX_StocklineTimeCycleHistory_StocklineId]
    ON [dbo].[StocklineTimeCycleHistory]([StocklineId] ASC, [StocklineTimeCycleHistoryId] DESC)
    INCLUDE([TotalTSN], [TotalTSNMM], [TotalCSN], [TotalTSO], [TotalTSOMM], [TotalCSO], [IsDeleted]);

