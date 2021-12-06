CREATE TABLE [dbo].[AuditHistory] (
    [AuditHistoryId]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [TableRecordId]   BIGINT        NULL,
    [TableName]       VARCHAR (100) NOT NULL,
    [ColumnName]      VARCHAR (100) NOT NULL,
    [PreviousValue]   VARCHAR (500) NULL,
    [NewValue]        VARCHAR (500) NULL,
    [UpdatedDate]     DATETIME2 (7) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NULL,
    [MasterCompanyId] INT           NOT NULL,
    CONSTRAINT [PK_AuditHistory] PRIMARY KEY CLUSTERED ([AuditHistoryId] ASC)
);

