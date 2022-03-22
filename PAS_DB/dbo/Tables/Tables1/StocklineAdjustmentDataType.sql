CREATE TABLE [dbo].[StocklineAdjustmentDataType] (
    [StocklineAdjustmentDataTypeId] INT           IDENTITY (1, 1) NOT NULL,
    [Description]                   VARCHAR (100) NOT NULL,
    [MasterCompanyId]               INT           NOT NULL,
    [CreatedBy]                     VARCHAR (256) NULL,
    [UpdatedBy]                     VARCHAR (256) NULL,
    [CreatedDate]                   DATETIME2 (7) CONSTRAINT [DF_StocklineAdjustmentDataType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7) CONSTRAINT [DF_StocklineAdjustmentDataType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                      BIT           CONSTRAINT [DF_StocklineAdjustmentDataType_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]                     BIT           CONSTRAINT [DF_StocklineAdjustmentDataType_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_StocklineAdjustmentDataType] PRIMARY KEY CLUSTERED ([StocklineAdjustmentDataTypeId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_StocklineAdjustmentDataTypeAudit]

   ON  [dbo].[StocklineAdjustmentDataType]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[StocklineAdjustmentDataTypeAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END