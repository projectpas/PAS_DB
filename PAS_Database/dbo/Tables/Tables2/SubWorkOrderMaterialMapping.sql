CREATE TABLE [dbo].[SubWorkOrderMaterialMapping] (
    [SWOMaterialMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderMaterialsId] BIGINT        NOT NULL,
    [SubWorkOrderId]       BIGINT        NOT NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [DF_SubWorkOrderMaterialMapping_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [DF_SubWorkOrderMaterialMapping_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [DF_SWOMP_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [DF_SWOMP_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SubWorkOrderMaterialMapping] PRIMARY KEY CLUSTERED ([SWOMaterialMappingId] ASC),
    CONSTRAINT [FK_SubWorkOrderMaterialMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SubWorkOrderMaterialMapping_SubWorkOrder] FOREIGN KEY ([SubWorkOrderId]) REFERENCES [dbo].[SubWorkOrder] ([SubWorkOrderId]),
    CONSTRAINT [FK_SubWorkOrderMaterialMapping_WorkOrderMaterials] FOREIGN KEY ([WorkOrderMaterialsId]) REFERENCES [dbo].[WorkOrderMaterials] ([WorkOrderMaterialsId])
);

