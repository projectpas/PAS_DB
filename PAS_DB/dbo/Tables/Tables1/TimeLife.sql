﻿CREATE TABLE [dbo].[TimeLife] (
    [TimeLifeCyclesId]          BIGINT        IDENTITY (1, 1) NOT NULL,
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
    [CreatedBy]                 VARCHAR (256) NULL,
    [UpdatedBy]                 VARCHAR (256) NULL,
    [CreatedDate]               DATETIME2 (7) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) NOT NULL,
    [IsActive]                  BIT           NULL,
    [PurchaseOrderId]           BIGINT        NULL,
    [PurchaseOrderPartRecordId] BIGINT        NULL,
    [StockLineId]               BIGINT        DEFAULT ((0)) NULL,
    [DetailsNotProvided]        BIT           DEFAULT ((1)) NOT NULL,
    [RepairOrderId]             BIGINT        NULL,
    [RepairOrderPartRecordId]   BIGINT        NULL,
    [VendorRMAId]               BIGINT        NULL,
    [VendorRMADetailId]         BIGINT        NULL,
    CONSTRAINT [PK__TimeLife__714D5BA5DC0EB54C] PRIMARY KEY CLUSTERED ([TimeLifeCyclesId] ASC),
    CONSTRAINT [FK__TimeLife__Purcha__64247DE6] FOREIGN KEY ([PurchaseOrderId]) REFERENCES [dbo].[PurchaseOrder] ([PurchaseOrderId]),
    CONSTRAINT [FK__TimeLife__Purcha__660CC658] FOREIGN KEY ([PurchaseOrderPartRecordId]) REFERENCES [dbo].[PurchaseOrderPart] ([PurchaseOrderPartRecordId]),
    CONSTRAINT [FK__TimeLife__Repair__2C09769E] FOREIGN KEY ([RepairOrderId]) REFERENCES [dbo].[RepairOrder] ([RepairOrderId]),
    CONSTRAINT [FK__TimeLife__Repair__2CFD9AD7] FOREIGN KEY ([RepairOrderPartRecordId]) REFERENCES [dbo].[RepairOrderPart] ([RepairOrderPartRecordId])
);




GO






-- =============================================

CREATE TRIGGER [dbo].[Trg_TimeLifeAudit]

   ON  [dbo].[TimeLife]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[TimeLifeAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END