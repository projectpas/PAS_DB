CREATE TABLE [dbo].[EquipmentListsAudit] (
    [EquipmentListsAuditId] INT           IDENTITY (1, 1) NOT NULL,
    [Id]                    INT           NOT NULL,
    [CreatedBy]             VARCHAR (50)  NULL,
    [CreatedDate]           DATETIME      NOT NULL,
    [UpdatedBy]             VARCHAR (50)  NULL,
    [UpdatedDate]           DATETIME      NULL,
    [IsDeleted]             BIT           NULL,
    [AssetId]               VARCHAR (256) NULL,
    [AssetType]             VARCHAR (256) NULL,
    [AssetDescription]      VARCHAR (256) NULL,
    [Quantity]              VARCHAR (256) NULL,
    [ActionId]              BIGINT        NOT NULL,
    [WorkFlowId]            BIGINT        NOT NULL,
    CONSTRAINT [PK_EquipmentListsAudit] PRIMARY KEY CLUSTERED ([EquipmentListsAuditId] ASC)
);

