CREATE TABLE [dbo].[SubWorkOrderMaterialStockLineKit] (
    [SWOMStockLineKitId]         BIGINT          IDENTITY (1, 1) NOT NULL,
    [SubWorkOrderMaterialsKitId] BIGINT          NOT NULL,
    [StockLIneId]                BIGINT          NOT NULL,
    [ItemMasterId]               BIGINT          NOT NULL,
    [ConditionId]                BIGINT          NOT NULL,
    [Quantity]                   DECIMAL (18, 6) NULL,
    [QtyReserved]                DECIMAL (18, 6) NULL,
    [QtyIssued]                  DECIMAL (18, 6) NULL,
    [MasterCompanyId]            INT             NOT NULL,
    [CreatedBy]                  VARCHAR (256)   NOT NULL,
    [UpdatedBy]                  VARCHAR (256)   NOT NULL,
    [CreatedDate]                DATETIME2 (7)   CONSTRAINT [DF_SubWorkOrderMaterialStockLineKit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                DATETIME2 (7)   CONSTRAINT [DF_SubWorkOrderMaterialStockLineKit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                   BIT             CONSTRAINT [DF_SubWorkOrderMaterialStockLineKit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT             CONSTRAINT [DF_SubWorkOrderMaterialStockLineKit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [AltPartMasterPartId]        BIGINT          NULL,
    [EquPartMasterPartId]        BIGINT          NULL,
    [IsAltPart]                  BIT             NULL,
    [IsEquPart]                  BIT             NULL,
    [UnitCost]                   DECIMAL (18, 6) NULL,
    [ExtendedCost]               DECIMAL (18, 6) NULL,
    [UnitPrice]                  DECIMAL (18, 6) NULL,
    [ExtendedPrice]              DECIMAL (18, 6) NULL,
    [ProvisionId]                INT             DEFAULT ((2)) NOT NULL,
    [RepairOrderId]              BIGINT          NULL,
    [QuantityTurnIn]             DECIMAL (18, 6) CONSTRAINT [DF__SubWorkOr__Quant__43525E0A] DEFAULT ((0)) NULL,
    [Figure]                     NVARCHAR (50)   NULL,
    [Item]                       NVARCHAR (50)   NULL,
    [ReferenceNumber]            VARCHAR (100)   NULL,
    [ReservedById]               BIGINT          NULL,
    [ReservedDate]               DATETIME2 (7)   NULL,
    [IssuedById]                 BIGINT          NULL,
    [IssuedDate]                 DATETIME2 (7)   NULL,
    CONSTRAINT [PK_SubWorkOrderMaterialStockLineKit] PRIMARY KEY CLUSTERED ([SWOMStockLineKitId] ASC),
    CONSTRAINT [FK_SubWorkOrderMaterialStockLineKit_ConditionId] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_SubWorkOrderMaterialStockLineKit_ItemMasterId] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_SubWorkOrderMaterialStockLineKit_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SubWorkOrderMaterialStockLineKit_ProvisionId] FOREIGN KEY ([ProvisionId]) REFERENCES [dbo].[Provision] ([ProvisionId]),
    CONSTRAINT [FK_SubWorkOrderMaterialStockLineKit_RepairOrderId] FOREIGN KEY ([RepairOrderId]) REFERENCES [dbo].[RepairOrder] ([RepairOrderId]),
    CONSTRAINT [FK_SubWorkOrderMaterialStockLineKit_StockLine] FOREIGN KEY ([StockLIneId]) REFERENCES [dbo].[Stockline] ([StockLineId]),
    CONSTRAINT [FK_SubWorkOrderMaterialStockLineKit_SubWorkOrderMaterials] FOREIGN KEY ([SubWorkOrderMaterialsKitId]) REFERENCES [dbo].[SubWorkOrderMaterialsKit] ([SubWorkOrderMaterialsKitId])
);






GO
/*************************************************************             
** File:   [Trg_SubWorkOrderMaterialStockLineKitAudit]             
** Author: Devendra Shekh
** Description: Trigger to insert Data for SubWorkOrderMaterialStockLineKitAudit based on changes of SubWorkOrderMaterialStockLineKit
** Date: 22-NOV-2024

**************************************************************             
** Change History             
**************************************************************             
** PR   Date				Author					Change Description              
** --   --------			-------				-------------------------------            
	1   22-NOV-2024			Devendra Shekh			Created
**************************************************************/  
CREATE   TRIGGER [dbo].[Trg_SubWorkOrderMaterialStockLineKitAudit]

   ON  [dbo].[SubWorkOrderMaterialStockLineKit]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO SubWorkOrderMaterialStockLineKitAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END