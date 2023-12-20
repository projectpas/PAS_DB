CREATE TABLE [dbo].[CheckInCheckOutWorkOrderAsset] (
    [CheckInCheckOutWorkOrderAssetId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderAssetId]                BIGINT         NOT NULL,
    [WorkOrderId]                     BIGINT         NOT NULL,
    [WorkOrderPartNoId]               BIGINT         NOT NULL,
    [AssetRecordId]                   BIGINT         NOT NULL,
    [AssetInventoryId]                BIGINT         NOT NULL,
    [CheckOutById]                    BIGINT         NULL,
    [CheckOutDate]                    DATETIME2 (7)  NULL,
    [CheckInById]                     BIGINT         NULL,
    [CheckInDate]                     DATETIME2 (7)  NULL,
    [Quantity]                        INT            NOT NULL,
    [CheckOutQty]                     INT            NULL,
    [CheckInQty]                      INT            NULL,
    [CheckOutEmpId]                   BIGINT         NULL,
    [CheckInEmpId]                    BIGINT         NULL,
    [IsQtyCheckOut]                   BIT            NOT NULL,
    [Notes]                           NVARCHAR (MAX) NULL,
    [InventoryStatusId]               BIGINT         NOT NULL,
    [MasterCompanyId]                 INT            NOT NULL,
    [CreatedBy]                       VARCHAR (256)  NOT NULL,
    [UpdatedBy]                       VARCHAR (256)  NOT NULL,
    [CreatedDate]                     DATETIME2 (7)  CONSTRAINT [DF_CheckInCheckOutWorkOrderAsset_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                     DATETIME2 (7)  CONSTRAINT [DF_CheckInCheckOutWorkOrderAsset_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                        BIT            CONSTRAINT [CheckInCheckOutWorkOrderAsset_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                       BIT            CONSTRAINT [CheckInCheckOutWorkOrderAsset_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CheckInCheckOutWorkOrderAsset] PRIMARY KEY CLUSTERED ([CheckInCheckOutWorkOrderAssetId] ASC),
    CONSTRAINT [FK_CheckInCheckOutWorkOrderAsset_Asset] FOREIGN KEY ([AssetRecordId]) REFERENCES [dbo].[Asset] ([AssetRecordId]),
    CONSTRAINT [FK_CheckInCheckOutWorkOrderAsset_AssetInventory] FOREIGN KEY ([AssetInventoryId]) REFERENCES [dbo].[AssetInventory] ([AssetInventoryId]),
    CONSTRAINT [FK_CheckInCheckOutWorkOrderAsset_CheckInBy] FOREIGN KEY ([CheckInById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_CheckInCheckOutWorkOrderAsset_CheckInEmp] FOREIGN KEY ([CheckInEmpId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_CheckInCheckOutWorkOrderAsset_CheckOutBy] FOREIGN KEY ([CheckOutById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_CheckInCheckOutWorkOrderAsset_CheckOutEmp] FOREIGN KEY ([CheckOutEmpId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_CheckInCheckOutWorkOrderAsset_InventoryStatus] FOREIGN KEY ([InventoryStatusId]) REFERENCES [dbo].[AssetInventoryStatus] ([AssetInventoryStatusId]),
    CONSTRAINT [FK_CheckInCheckOutWorkOrderAsset_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_CheckInCheckOutWorkOrderAsset_PartNo] FOREIGN KEY ([WorkOrderPartNoId]) REFERENCES [dbo].[WorkOrderPartNumber] ([ID]),
    CONSTRAINT [FK_CheckInCheckOutWorkOrderAsset_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId]),
    CONSTRAINT [FK_CheckInCheckOutWorkOrderAsset_WorkOrderAsset] FOREIGN KEY ([WorkOrderAssetId]) REFERENCES [dbo].[WorkOrderAssets] ([WorkOrderAssetId])
);


GO


-------------------

CREATE TRIGGER [dbo].[Trg_CheckInCheckOutWorkOrderAsset]

   ON  [dbo].[CheckInCheckOutWorkOrderAsset]

   AFTER INSERT,UPDATE

AS

BEGIN



INSERT INTO [dbo].[CheckInCheckOutWorkOrderAssetAudit]

SELECT * FROM INSERTED



SET NOCOUNT ON;



END