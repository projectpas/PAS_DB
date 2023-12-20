CREATE TABLE [dbo].[StocklineAdjustment] (
    [StocklineAdjustmentId]         BIGINT         IDENTITY (1, 1) NOT NULL,
    [StocklineId]                   BIGINT         NOT NULL,
    [StocklineAdjustmentDataTypeId] INT            NOT NULL,
    [ChangedFrom]                   VARCHAR (50)   NULL,
    [ChangedTo]                     VARCHAR (50)   NULL,
    [AdjustmentMemo]                NVARCHAR (MAX) NULL,
    [MasterCompanyId]               INT            NOT NULL,
    [CreatedBy]                     VARCHAR (256)  NOT NULL,
    [UpdatedBy]                     VARCHAR (256)  NOT NULL,
    [CreatedDate]                   DATETIME2 (7)  CONSTRAINT [DF_StocklineAdjustment_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)  CONSTRAINT [DF_StocklineAdjustment_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                      BIT            CONSTRAINT [DF_StocklineAdjustment_IsActive] DEFAULT ((1)) NOT NULL,
    [AdjustmentReasonId]            INT            NULL,
    [IsDeleted]                     BIT            CONSTRAINT [DF_StocklineAdjustment_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CurrencyId]                    INT            NULL,
    [AdjustmentReason]              NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_StocklineAdjustment] PRIMARY KEY CLUSTERED ([StocklineAdjustmentId] ASC),
    CONSTRAINT [FK_StocklineAdjustment_CurrencyId] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_StocklineAdjustment_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_StocklineAdjustment_Stockline] FOREIGN KEY ([StocklineId]) REFERENCES [dbo].[Stockline] ([StockLineId]),
    CONSTRAINT [FK_StocklineAdjustment_StocklineAdjustmentDataType] FOREIGN KEY ([StocklineAdjustmentDataTypeId]) REFERENCES [dbo].[StocklineAdjustmentDataType] ([StocklineAdjustmentDataTypeId])
);


GO


CREATE TRIGGER [dbo].[Trg_StocklineAdjustmentAudit]

   ON  [dbo].[StocklineAdjustment]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[StocklineAdjustmentAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END