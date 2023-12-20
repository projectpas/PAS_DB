CREATE TABLE [dbo].[StocklineReceivingEquipment] (
    [StocklineReceivingEquipmentId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [StocklineId]                   BIGINT        NOT NULL,
    [ReceivingEquipmentId]          BIGINT        NOT NULL,
    [MasterCompanyId]               INT           NOT NULL,
    [CreatedBy]                     VARCHAR (256) NULL,
    [UpdatedBy]                     VARCHAR (256) NULL,
    [CreatedDate]                   DATETIME2 (7) CONSTRAINT [DF_StocklineReceivingEquipment_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7) CONSTRAINT [DF_StocklineReceivingEquipment_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                      BIT           CONSTRAINT [DF_StocklineReceivingEquipment_IsActive] DEFAULT ((1)) NULL,
    [IsDelete]                      BIT           NULL,
    CONSTRAINT [PK_StocklineReceivingEquipment] PRIMARY KEY CLUSTERED ([StocklineReceivingEquipmentId] ASC),
    CONSTRAINT [FK_StocklineReceivingEquipment_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_StocklineReceivingEquipment_ReceivingEquipment] FOREIGN KEY ([ReceivingEquipmentId]) REFERENCES [dbo].[ReceivingEquipment] ([ReceivingEquipmentId]),
    CONSTRAINT [FK_StocklineReceivingEquipment_StockLine] FOREIGN KEY ([StocklineId]) REFERENCES [dbo].[Stockline] ([StockLineId])
);

