CREATE TABLE [dbo].[BulkStockLineAdjustmentDetails] (
    [BulkStkLineAdjDetailsId]   INT             IDENTITY (1, 1) NOT NULL,
    [BulkStkLineAdjId]          BIGINT          NOT NULL,
    [StockLineId]               BIGINT          NOT NULL,
    [Qty]                       INT             NOT NULL,
    [NewQty]                    INT             NULL,
    [QtyAdjustment]             INT             NULL,
    [UnitCost]                  DECIMAL (18, 2) NULL,
    [AdjustmentAmount]          DECIMAL (18, 2) NULL,
    [StockLineAdjustmentTypeId] INT             NOT NULL,
    [ManagementStructureId]     BIGINT          NULL,
    [LastMSLevel]               VARCHAR (200)   NULL,
    [AllMSlevels]               VARCHAR (MAX)   NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [CreatedBy]                 VARCHAR (50)    NOT NULL,
    [CreatedDate]               DATETIME        CONSTRAINT [DF_BulkStockLineAdjustmentDetails_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                 VARCHAR (50)    NULL,
    [UpdatedDate]               DATETIME        CONSTRAINT [DF_BulkStockLineAdjustmentDetails_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]                  BIT             CONSTRAINT [DF_BulkStockLineAdjustmentDetails_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT             CONSTRAINT [DF_BulkStockLineAdjustmentDetails_IsDeleted] DEFAULT ((0)) NOT NULL,
    [NewUnitCost]               DECIMAL (18, 2) NULL,
    [UnitCostAdjustment]        DECIMAL (18, 2) NULL,
    [FreightAdjustment]         DECIMAL (18, 2) NULL,
    [TaxAdjustment]             DECIMAL (18, 2) NULL,
    [FromManagementStructureId] BIGINT          NULL,
    [ToManagementStructureId]   BIGINT          NULL,
    [QuantityOnHand]            DECIMAL (18, 2) NULL,
    [UnitOfMeasure]             VARCHAR (100)   NULL,
    [NewUnitCostTotransfer]     DECIMAL (18, 2) NULL,
    CONSTRAINT [PK_BulkStockLineAdjustmentDetails] PRIMARY KEY CLUSTERED ([BulkStkLineAdjDetailsId] ASC)
);



