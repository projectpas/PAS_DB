CREATE TABLE [dbo].[StocklineHistory] (
    [StocklineHistoryId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ModuleId]           BIGINT         NULL,
    [RefferenceId]       BIGINT         NULL,
    [StocklineId]        BIGINT         NULL,
    [QuantityAvailable]  BIGINT         NULL,
    [QuantityOnHand]     BIGINT         NULL,
    [QuantityReserved]   BIGINT         NULL,
    [QuantityIssued]     BIGINT         NULL,
    [TextMessage]        NVARCHAR (MAX) NULL,
    [CreatedBy]          VARCHAR (256)  NOT NULL,
    [CreatedDate]        DATETIME2 (7)  NOT NULL,
    [UpdatedBy]          VARCHAR (256)  NOT NULL,
    [UpdatedDate]        DATETIME2 (7)  NOT NULL,
    [MasterCompanyId]    INT            NULL,
    [SubReferenceId]     BIGINT         NULL,
    [SubModuleId]        BIGINT         NULL,
    CONSTRAINT [PK_StocklineHisto] PRIMARY KEY CLUSTERED ([StocklineHistoryId] ASC)
);





