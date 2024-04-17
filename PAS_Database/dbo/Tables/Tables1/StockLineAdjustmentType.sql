CREATE TABLE [dbo].[StockLineAdjustmentType] (
    [StockLineAdjustmentTypeId] INT           IDENTITY (1, 1) NOT NULL,
    [Name]                      VARCHAR (50)  NULL,
    [Description]               VARCHAR (250) NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (50)  NOT NULL,
    [CreatedDate]               DATETIME      CONSTRAINT [DF_StockLineAdjustmentType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                 VARCHAR (50)  NULL,
    [UpdatedDate]               DATETIME      CONSTRAINT [DF_StockLineAdjustmentType_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]                  BIT           CONSTRAINT [DF_StockLineAdjustmentType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT           CONSTRAINT [DF_StockLineAdjustmentType_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ToolTip]                   VARCHAR (200) NULL,
    CONSTRAINT [PK_StockLineAdjustmentType] PRIMARY KEY CLUSTERED ([StockLineAdjustmentTypeId] ASC)
);



