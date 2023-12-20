CREATE TABLE [dbo].[AssetInventoryAdjustmentDataType] (
    [AssetInventoryAdjustmentDataTypeId] INT           IDENTITY (1, 1) NOT NULL,
    [Description]                        VARCHAR (100) NOT NULL,
    [MasterCompanyId]                    INT           NOT NULL,
    [CreatedBy]                          VARCHAR (256) NOT NULL,
    [UpdatedBy]                          VARCHAR (256) NOT NULL,
    [CreatedDate]                        DATETIME2 (7) CONSTRAINT [DF_AssetInventoryAdjustmentDataType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                        DATETIME2 (7) CONSTRAINT [DF_AssetInventoryAdjustmentDataType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                           BIT           CONSTRAINT [DF_AssetInventoryAdjustmentDataType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                          BIT           CONSTRAINT [DF_AssetInventoryAdjustmentDataType_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AssetInventoryAdjustmentDataType] PRIMARY KEY CLUSTERED ([AssetInventoryAdjustmentDataTypeId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_AssetInventoryAdjustmentDataTypeAudit]

   ON  [dbo].[AssetInventoryAdjustmentDataType]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[AssetInventoryAdjustmentDataTypeAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END