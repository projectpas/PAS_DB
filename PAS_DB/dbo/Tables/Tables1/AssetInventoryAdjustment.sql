CREATE TABLE [dbo].[AssetInventoryAdjustment] (
    [AssetInventoryAdjustmentId]         BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetInventoryId]                   BIGINT         NOT NULL,
    [AssetInventoryAdjustmentDataTypeId] INT            NOT NULL,
    [ChangedFrom]                        VARCHAR (50)   NULL,
    [ChangedTo]                          VARCHAR (50)   NULL,
    [AdjustmentMemo]                     NVARCHAR (MAX) NULL,
    [MasterCompanyId]                    INT            NOT NULL,
    [CreatedBy]                          VARCHAR (256)  NOT NULL,
    [UpdatedBy]                          VARCHAR (256)  NOT NULL,
    [CreatedDate]                        DATETIME2 (7)  CONSTRAINT [DF_AssetInventoryAdjustment_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                        DATETIME2 (7)  CONSTRAINT [DF_AssetInventoryAdjustment_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                           BIT            CONSTRAINT [DF_AssetInventoryAdjustment_IsActive] DEFAULT ((1)) NOT NULL,
    [AdjustmentReasonId]                 INT            NULL,
    [IsDeleted]                          BIT            CONSTRAINT [DF_AssetInventoryAdjustment_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CurrencyId]                         INT            NULL,
    [AdjustmentReason]                   VARCHAR (250)  NULL,
    CONSTRAINT [PK_AssetInventoryAdjustment] PRIMARY KEY CLUSTERED ([AssetInventoryAdjustmentId] ASC),
    CONSTRAINT [FK_AssetInventoryAdjustment_AssetInventoryAdjustmentDataType] FOREIGN KEY ([AssetInventoryAdjustmentDataTypeId]) REFERENCES [dbo].[AssetInventoryAdjustmentDataType] ([AssetInventoryAdjustmentDataTypeId]),
    CONSTRAINT [FK_AssetInventoryAdjustment_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_AssetInventoryAdjustment_Stockline] FOREIGN KEY ([AssetInventoryId]) REFERENCES [dbo].[AssetInventory] ([AssetInventoryId])
);


GO


CREATE TRIGGER [dbo].[Trg_AssetInventoryAdjustmentAudit]

   ON  [dbo].[AssetInventoryAdjustment]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[AssetInventoryAdjustmentAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END