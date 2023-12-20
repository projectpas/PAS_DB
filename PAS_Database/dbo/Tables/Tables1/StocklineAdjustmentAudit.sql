CREATE TABLE [dbo].[StocklineAdjustmentAudit] (
    [AuditStocklineAdjustmentId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [StocklineAdjustmentId]         BIGINT         NOT NULL,
    [StocklineId]                   BIGINT         NOT NULL,
    [StocklineAdjustmentDataTypeId] INT            NOT NULL,
    [ChangedFrom]                   VARCHAR (50)   NULL,
    [ChangedTo]                     VARCHAR (50)   NULL,
    [AdjustmentMemo]                NVARCHAR (MAX) NULL,
    [MasterCompanyId]               INT            NOT NULL,
    [CreatedBy]                     VARCHAR (256)  NOT NULL,
    [UpdatedBy]                     VARCHAR (256)  NOT NULL,
    [CreatedDate]                   DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)  NOT NULL,
    [IsActive]                      BIT            NOT NULL,
    [AdjustmentReasonId]            INT            NULL,
    [IsDeleted]                     BIT            NOT NULL,
    [CurrencyId]                    INT            NULL,
    [AdjustmentReason]              NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_StocklineAdjustmentAudit] PRIMARY KEY CLUSTERED ([AuditStocklineAdjustmentId] ASC)
);

