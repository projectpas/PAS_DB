CREATE TABLE [dbo].[StocklineAdjustmentStatus] (
    [Id]              INT           IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (50)  NULL,
    [Description]     VARCHAR (250) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (50)  NOT NULL,
    [CreatedDate]     DATETIME      CONSTRAINT [DF_StocklineAdjustmentStatus_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (50)  NULL,
    [UpdatedDate]     DATETIME      CONSTRAINT [DF_StocklineAdjustmentStatus_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]        BIT           CONSTRAINT [DF_StocklineAdjustmentStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_StocklineAdjustmentStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_StocklineAdjustmentStatus] PRIMARY KEY CLUSTERED ([Id] ASC)
);

