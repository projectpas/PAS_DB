CREATE TABLE [dbo].[LeaseStocklineUsageHistoryAudit] (
    [LeaseStocklineUsageHistoryAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [LeaseStocklineUsageHistoryId]      BIGINT          NULL,
    [LeaseStocklineId]                  BIGINT          NULL,
    [EntryDate]                         DATETIME2 (7)   NULL,
    [TSNHours]                          DECIMAL (18, 6) NULL,
    [TSNMinutes]                        DECIMAL (18, 6) NULL,
    [CSNHours]                          DECIMAL (18, 6) NULL,
    [CSNMinutes]                        DECIMAL (18, 6) NULL,
    [Notes]                             NVARCHAR (MAX)  NULL,
    [MasterCompanyId]                   INT             NULL,
    [CreatedBy]                         VARCHAR (256)   NULL,
    [UpdatedBy]                         VARCHAR (256)   NULL,
    [CreatedDate]                       DATETIME2 (7)   NULL,
    [UpdatedDate]                       DATETIME2 (7)   NULL,
    [IsActive]                          BIT             NULL,
    [IsDeleted]                         BIT             NULL,
    CONSTRAINT [PK_LeaseStocklineUsageHistoryAudit] PRIMARY KEY CLUSTERED ([LeaseStocklineUsageHistoryAuditId] ASC)
);
