CREATE TABLE [dbo].[WorkOrderAssets] (
    [WorkOrderAssetId]    BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]         BIGINT        NOT NULL,
    [WorkFlowWorkOrderId] BIGINT        NOT NULL,
    [AssetRecordId]       BIGINT        NOT NULL,
    [Quantity]            INT           NOT NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [CreatedDate]         DATETIME2 (7) CONSTRAINT [DF_WorkOrderAssets_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) CONSTRAINT [DF_WorkOrderAssets_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT           CONSTRAINT [WorkOrderAssets_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT           CONSTRAINT [WorkOrderAssets_DC_Delete] DEFAULT ((0)) NOT NULL,
    [IsFromWorkFlow]      BIT           DEFAULT ((0)) NULL,
    [WOPartNoId]          BIGINT        DEFAULT ((0)) NOT NULL,
    [TaskId]              BIGINT        DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_WorkOrderAssets] PRIMARY KEY CLUSTERED ([WorkOrderAssetId] ASC),
    CONSTRAINT [FK_WorkOrderAssets_Asset] FOREIGN KEY ([AssetRecordId]) REFERENCES [dbo].[Asset] ([AssetRecordId]),
    CONSTRAINT [FK_WorkOrderAssets_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderAssets_TaskId] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkOrderAssets_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_WorkOrderAssetsAudit]

   ON  [dbo].[WorkOrderAssets]

   AFTER INSERT,UPDATE

AS 

BEGIN



	DECLARE @AssetRecordId BIGINT 



	DECLARE @ToolName VARCHAR(256),@ToolId VARCHAR(256),@ToolDescription VARCHAR(256),@ToolClass VARCHAR(256)

	



	SELECT @AssetRecordId= AssetRecordId FROM INSERTED

	

	SELECT  @ToolName=Name,@ToolId=AssetId,@ToolDescription=Description,@ToolClass=TY.TangibleClassName

	FROM Asset A

	JOIN TangibleClass TY ON A.TangibleClassId=TY.TangibleClassId

	WHERE AssetRecordId=@AssetRecordId



	INSERT INTO [dbo].[WorkOrderAssetsAudit] 

    SELECT *, @ToolName,@ToolId,@ToolDescription,@ToolClass

	FROM INSERTED 

	SET NOCOUNT ON;



END