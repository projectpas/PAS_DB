CREATE TABLE [dbo].[SubWorkOrderAsset] (
    [SubWorkOrderAssetId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]         BIGINT        NOT NULL,
    [SubWorkOrderId]      BIGINT        NOT NULL,
    [SubWOPartNoId]       BIGINT        NOT NULL,
    [AssetRecordId]       BIGINT        NOT NULL,
    [Quantity]            INT           NOT NULL,
    [IsFromWorkFlow]      BIT           DEFAULT ((0)) NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [CreatedDate]         DATETIME2 (7) CONSTRAINT [DF_SubWorkOrderAsset_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) CONSTRAINT [DF_SubWorkOrderAsset_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT           CONSTRAINT [SubWorkOrderAssets_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT           CONSTRAINT [SubWorkOrderAssets_DC_Delete] DEFAULT ((0)) NOT NULL,
    [TaskId]              BIGINT        NULL,
    CONSTRAINT [PK_SubWorkOrderAsset] PRIMARY KEY CLUSTERED ([SubWorkOrderAssetId] ASC),
    CONSTRAINT [FK_SubWorkOrderAsset_Asset] FOREIGN KEY ([AssetRecordId]) REFERENCES [dbo].[Asset] ([AssetRecordId]),
    CONSTRAINT [FK_SubWorkOrderAsset_TaskId] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_SubWorkOrderAssets_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SubWorkOrderAssets_SubWorkOrder] FOREIGN KEY ([SubWorkOrderId]) REFERENCES [dbo].[SubWorkOrder] ([SubWorkOrderId]),
    CONSTRAINT [FK_SubWorkOrderAssets_SubWorkOrderPartNumber] FOREIGN KEY ([SubWOPartNoId]) REFERENCES [dbo].[SubWorkOrderPartNumber] ([SubWOPartNoId]),
    CONSTRAINT [FK_SubWorkOrderAssets_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_SubWorkOrderAssetAudit]

   ON  [dbo].[SubWorkOrderAsset]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[SubWorkOrderAssetAudit] 

    SELECT * 

	FROM INSERTED 

	SET NOCOUNT ON;



END