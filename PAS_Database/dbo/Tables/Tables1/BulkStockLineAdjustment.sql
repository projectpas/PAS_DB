CREATE TABLE [dbo].[BulkStockLineAdjustment] (
    [BulkStkLineAdjId]          INT          IDENTITY (1, 1) NOT NULL,
    [BulkStkLineAdjNumber]      VARCHAR (50) NULL,
    [StatusId]                  INT          NULL,
    [Status]                    VARCHAR (50) NULL,
    [MasterCompanyId]           INT          NOT NULL,
    [CreatedBy]                 VARCHAR (50) NOT NULL,
    [CreatedDate]               DATETIME     CONSTRAINT [DF_BulkStockLineAdjustment_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                 VARCHAR (50) NULL,
    [UpdatedDate]               DATETIME     CONSTRAINT [DF_BulkStockLineAdjustment_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]                  BIT          CONSTRAINT [DF_BulkStockLineAdjustment_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT          CONSTRAINT [DF_BulkStockLineAdjustment_IsDeleted] DEFAULT ((0)) NOT NULL,
    [StockLineAdjustmentTypeId] INT          NULL,
    CONSTRAINT [PK_BulkStockLineAdjustment] PRIMARY KEY CLUSTERED ([BulkStkLineAdjId] ASC)
);

