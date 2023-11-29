CREATE TABLE [dbo].[WorkOrderMaterialsKitMapping] (
    [WorkOrderMaterialsKitMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WOPartNoId]                     BIGINT        NOT NULL,
    [KitId]                          BIGINT        NOT NULL,
    [KitNumber]                      VARCHAR (256) NOT NULL,
    [ItemMasterId]                   BIGINT        NOT NULL,
    [MasterCompanyId]                INT           NOT NULL,
    [CreatedBy]                      VARCHAR (256) NOT NULL,
    [UpdatedBy]                      VARCHAR (256) NOT NULL,
    [CreatedDate]                    DATETIME2 (7) CONSTRAINT [DF_WorkOrderMaterialsKitMapping_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7) CONSTRAINT [DF_WorkOrderMaterialsKitMapping_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                       BIT           CONSTRAINT [WorkOrderMaterialsKitMapping_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                      BIT           CONSTRAINT [WorkOrderMaterialsKitMapping_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderMaterialsKitMapping] PRIMARY KEY CLUSTERED ([WorkOrderMaterialsKitMappingId] ASC)
);

