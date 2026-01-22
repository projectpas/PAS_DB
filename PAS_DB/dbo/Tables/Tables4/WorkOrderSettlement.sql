CREATE TABLE [dbo].[WorkOrderSettlement] (
    [WorkOrderSettlementId]   BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderSettlementName] VARCHAR (500) NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [DF_WorkOrderSettlement_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [WorkOrderSettlement_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT           CONSTRAINT [WorkOrderSettlement_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           CONSTRAINT [WorkOrderSettlement_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderSettlement] PRIMARY KEY CLUSTERED ([WorkOrderSettlementId] ASC)
);

