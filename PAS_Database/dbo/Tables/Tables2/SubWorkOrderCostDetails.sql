CREATE TABLE [dbo].[SubWorkOrderCostDetails] (
    [SubWOCostDetailsId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]            BIGINT          NOT NULL,
    [SubWorkOrderId]         BIGINT          NOT NULL,
    [SubWOPartNoId]          BIGINT          NOT NULL,
    [Revenue]                DECIMAL (18, 6) NULL,
    [PartsCost]              DECIMAL (18, 6) NULL,
    [PartsRevPercentage]     DECIMAL (18, 6) NULL,
    [LaborCost]              DECIMAL (18, 6) NULL,
    [LaborRevPercentage]     DECIMAL (18, 6) NULL,
    [OverHeadCost]           DECIMAL (18, 6) NULL,
    [OverHeadPercentage]     DECIMAL (18, 6) NULL,
    [OtherCost]              DECIMAL (18, 6) NULL,
    [DirectCost]             DECIMAL (18, 6) NULL,
    [DirectCostPercentage]   DECIMAL (18, 6) NULL,
    [Margin]                 DECIMAL (18, 6) NULL,
    [MarginPercentage]       DECIMAL (18, 6) NULL,
    [ChargesCost]            DECIMAL (18, 6) NULL,
    [FreightCost]            DECIMAL (18, 6) NULL,
    [TotalCost]              DECIMAL (18, 6) NULL,
    [ActualRevenue]          DECIMAL (18, 6) NULL,
    [ActualMargin]           DECIMAL (18, 6) NULL,
    [ActualMarginPercentage] DECIMAL (18, 6) NULL,
    [MasterCompanyId]        INT             NOT NULL,
    [CreatedBy]              VARCHAR (256)   NOT NULL,
    [UpdatedBy]              VARCHAR (256)   NOT NULL,
    [CreatedDate]            DATETIME2 (7)   CONSTRAINT [DF_SubWorkOrderCostDetails_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)   CONSTRAINT [DF_SubWorkOrderCostDetails_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT             CONSTRAINT [SubWorkOrderCostDetails_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT             CONSTRAINT [SubWorkOrderCostDetails_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SubWorkOrderCostDetails] PRIMARY KEY CLUSTERED ([SubWOCostDetailsId] ASC),
    CONSTRAINT [FK_SubWorkOrderCostDetails_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SubWorkOrderCostDetails_SubWorkOrder] FOREIGN KEY ([SubWorkOrderId]) REFERENCES [dbo].[SubWorkOrder] ([SubWorkOrderId]),
    CONSTRAINT [FK_SubWorkOrderCostDetails_SubWorkOrderPartNumber] FOREIGN KEY ([SubWOPartNoId]) REFERENCES [dbo].[SubWorkOrderPartNumber] ([SubWOPartNoId]),
    CONSTRAINT [FK_SubWorkOrderCostDetails_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);




GO




CREATE TRIGGER [dbo].[Trg_SubWorkOrderCostDetailsAudit]

   ON  [dbo].[SubWorkOrderCostDetails]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO SubWorkOrderCostDetailsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END