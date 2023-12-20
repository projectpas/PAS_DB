CREATE TABLE [dbo].[SubWOCheckInCheckOutWorkOrderAsset] (
    [SubWOCheckInCheckOutWorkOrderAssetId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [SubWorkOrderAssetId]                  BIGINT         NOT NULL,
    [WorkOrderId]                          BIGINT         NOT NULL,
    [SubWorkOrderId]                       BIGINT         NOT NULL,
    [SubWOPartNoId]                        BIGINT         NOT NULL,
    [AssetRecordId]                        BIGINT         NOT NULL,
    [AssetInventoryId]                     BIGINT         NOT NULL,
    [CheckOutById]                         BIGINT         NULL,
    [CheckOutDate]                         DATETIME2 (7)  NULL,
    [CheckInById]                          BIGINT         NULL,
    [CheckInDate]                          DATETIME2 (7)  NULL,
    [Quantity]                             INT            NOT NULL,
    [CheckOutQty]                          INT            NULL,
    [CheckInQty]                           INT            NULL,
    [CheckOutEmpId]                        BIGINT         NULL,
    [CheckInEmpId]                         BIGINT         NULL,
    [IsQtyCheckOut]                        BIT            NOT NULL,
    [Notes]                                NVARCHAR (MAX) NULL,
    [InventoryStatusId]                    BIGINT         NOT NULL,
    [MasterCompanyId]                      INT            NOT NULL,
    [CreatedBy]                            VARCHAR (256)  NOT NULL,
    [UpdatedBy]                            VARCHAR (256)  NOT NULL,
    [CreatedDate]                          DATETIME2 (7)  CONSTRAINT [DF_SubWOCheckInCheckOutWorkOrderAsset_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                          DATETIME2 (7)  CONSTRAINT [DF_SubWOCheckInCheckOutWorkOrderAsset_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                             BIT            CONSTRAINT [SubWOCheckInCheckOutWorkOrderAsset_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                            BIT            CONSTRAINT [SubWOCheckInCheckOutWorkOrderAsset_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SubWOCheckInCheckOutWorkOrderAsset] PRIMARY KEY CLUSTERED ([SubWOCheckInCheckOutWorkOrderAssetId] ASC),
    CONSTRAINT [FK_SubWOCheckInCheckOutWorkOrderAsset_Asset] FOREIGN KEY ([AssetRecordId]) REFERENCES [dbo].[Asset] ([AssetRecordId]),
    CONSTRAINT [FK_SubWOCheckInCheckOutWorkOrderAsset_AssetInventory] FOREIGN KEY ([AssetInventoryId]) REFERENCES [dbo].[AssetInventory] ([AssetInventoryId]),
    CONSTRAINT [FK_SubWOCheckInCheckOutWorkOrderAsset_CheckInBy] FOREIGN KEY ([CheckInById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SubWOCheckInCheckOutWorkOrderAsset_CheckInEmp] FOREIGN KEY ([CheckInEmpId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SubWOCheckInCheckOutWorkOrderAsset_CheckOutBy] FOREIGN KEY ([CheckOutById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SubWOCheckInCheckOutWorkOrderAsset_CheckOutEmp] FOREIGN KEY ([CheckOutEmpId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SubWOCheckInCheckOutWorkOrderAsset_InventoryStatus] FOREIGN KEY ([InventoryStatusId]) REFERENCES [dbo].[AssetInventoryStatus] ([AssetInventoryStatusId]),
    CONSTRAINT [FK_SubWOCheckInCheckOutWorkOrderAsset_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SubWOCheckInCheckOutWorkOrderAsset_SubWoPartNo] FOREIGN KEY ([SubWOPartNoId]) REFERENCES [dbo].[SubWorkOrderPartNumber] ([SubWOPartNoId]),
    CONSTRAINT [FK_SubWOCheckInCheckOutWorkOrderAsset_SubWorkOrder] FOREIGN KEY ([SubWorkOrderId]) REFERENCES [dbo].[SubWorkOrder] ([SubWorkOrderId]),
    CONSTRAINT [FK_SubWOCheckInCheckOutWorkOrderAsset_SubWorkOrderAsset] FOREIGN KEY ([SubWorkOrderAssetId]) REFERENCES [dbo].[SubWorkOrderAsset] ([SubWorkOrderAssetId]),
    CONSTRAINT [FK_SubWOCheckInCheckOutWorkOrderAsset_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO




-------------------

CREATE TRIGGER [dbo].[Trg_SubWoCheckInCheckOutWorkOrderAsset]

   ON  [dbo].[SubWOCheckInCheckOutWorkOrderAsset]

   AFTER INSERT,UPDATE

AS

BEGIN



INSERT INTO [dbo].[SubWOCheckInCheckOutWorkOrderAssetAudit]

SELECT * FROM INSERTED



SET NOCOUNT ON;



END