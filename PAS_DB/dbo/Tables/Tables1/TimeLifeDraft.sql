CREATE TABLE [dbo].[TimeLifeDraft] (
    [TimeLifeDraftCyclesId]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [CyclesRemaining]           VARCHAR (20)  NULL,
    [CyclesSinceNew]            VARCHAR (20)  NULL,
    [CyclesSinceOVH]            VARCHAR (20)  NULL,
    [CyclesSinceInspection]     VARCHAR (20)  NULL,
    [CyclesSinceRepair]         VARCHAR (20)  NULL,
    [TimeRemaining]             VARCHAR (20)  NULL,
    [TimeSinceNew]              VARCHAR (20)  NULL,
    [TimeSinceOVH]              VARCHAR (20)  NULL,
    [TimeSinceInspection]       VARCHAR (20)  NULL,
    [TimeSinceRepair]           VARCHAR (20)  NULL,
    [LastSinceNew]              VARCHAR (20)  NULL,
    [LastSinceOVH]              VARCHAR (20)  NULL,
    [LastSinceInspection]       VARCHAR (20)  NULL,
    [MasterCompanyId]           INT           NULL,
    [CreatedBy]                 VARCHAR (256) NOT NULL,
    [UpdatedBy]                 VARCHAR (256) NOT NULL,
    [CreatedDate]               DATETIME2 (7) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) NOT NULL,
    [IsActive]                  BIT           NOT NULL,
    [PurchaseOrderId]           BIGINT        NULL,
    [PurchaseOrderPartRecordId] BIGINT        NULL,
    [StockLineDraftId]          BIGINT        DEFAULT ((0)) NOT NULL,
    [DetailsNotProvided]        BIT           DEFAULT ((1)) NOT NULL,
    [RepairOrderId]             BIGINT        NULL,
    [RepairOrderPartRecordId]   BIGINT        NULL,
    [VendorRMAId]               BIGINT        NULL,
    [VendorRMADetailId]         BIGINT        NULL,
    CONSTRAINT [PK__TimeLifeDraft__714D5BA5DC0EB54C] PRIMARY KEY CLUSTERED ([TimeLifeDraftCyclesId] ASC),
    CONSTRAINT [FK__TimeLifeD__Repai__3726EEE6] FOREIGN KEY ([RepairOrderId]) REFERENCES [dbo].[RepairOrder] ([RepairOrderId]),
    CONSTRAINT [FK__TimeLifeD__Repai__381B131F] FOREIGN KEY ([RepairOrderPartRecordId]) REFERENCES [dbo].[RepairOrderPart] ([RepairOrderPartRecordId]),
    CONSTRAINT [FK__TimeLifeDraft__Purcha__64247DE6] FOREIGN KEY ([PurchaseOrderId]) REFERENCES [dbo].[PurchaseOrder] ([PurchaseOrderId]),
    CONSTRAINT [FK__TimeLifeDraft__Purcha__660CC658] FOREIGN KEY ([PurchaseOrderPartRecordId]) REFERENCES [dbo].[PurchaseOrderPart] ([PurchaseOrderPartRecordId]),
    CONSTRAINT [FK_TimeLifeDraft_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO




-- =============================================

CREATE TRIGGER [dbo].[Trg_TimeLifeDraftAudit]

   ON  [dbo].[TimeLifeDraft]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[TimeLifeDraftAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END