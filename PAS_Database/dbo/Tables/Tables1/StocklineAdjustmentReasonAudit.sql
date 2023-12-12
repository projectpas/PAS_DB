CREATE TABLE [dbo].[StocklineAdjustmentReasonAudit] (
    [AdjustmentReasonAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AdjustmentReasonId]      BIGINT         NOT NULL,
    [Description]             VARCHAR (200)  NOT NULL,
    [Memo]                    NVARCHAR (MAX) NULL,
    [MasterCompanyId]         INT            NOT NULL,
    [CreatedBy]               VARCHAR (256)  NOT NULL,
    [UpdatedBy]               VARCHAR (256)  NOT NULL,
    [CreatedDate]             DATETIME2 (7)  NOT NULL,
    [UpdatedDate]             DATETIME2 (7)  NOT NULL,
    [IsActive]                BIT            NOT NULL,
    [IsDeleted]               BIT            NOT NULL,
    CONSTRAINT [PK_StocklineAdjustmentReasonAudit] PRIMARY KEY CLUSTERED ([AdjustmentReasonAuditId] ASC),
    CONSTRAINT [FK_StocklineAdjustmentReasonAudit_StocklineAdjustmentReason] FOREIGN KEY ([AdjustmentReasonId]) REFERENCES [dbo].[StocklineAdjustmentReason] ([AdjustmentReasonId])
);

