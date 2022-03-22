CREATE TABLE [dbo].[StocklineAdjustmentDataTypeAudit] (
    [AuditStocklineAdjustmentDataTypeId] INT           IDENTITY (1, 1) NOT NULL,
    [StocklineAdjustmentDataTypeId]      INT           NOT NULL,
    [Description]                        VARCHAR (100) NOT NULL,
    [MasterCompanyId]                    INT           NOT NULL,
    [CreatedBy]                          VARCHAR (256) NULL,
    [UpdatedBy]                          VARCHAR (256) NULL,
    [CreatedDate]                        DATETIME2 (7) NOT NULL,
    [UpdatedDate]                        DATETIME2 (7) NOT NULL,
    [IsActive]                           BIT           NULL,
    [IsDeleted]                          BIT           NOT NULL,
    CONSTRAINT [PK_StocklineAdjustmentDataTypeAudit] PRIMARY KEY CLUSTERED ([AuditStocklineAdjustmentDataTypeId] ASC)
);

