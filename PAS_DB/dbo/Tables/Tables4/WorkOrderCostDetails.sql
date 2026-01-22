CREATE TABLE [dbo].[WorkOrderCostDetails] (
    [WorkOrderCostDetailsId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]            BIGINT          NOT NULL,
    [WOQuoteId]              BIGINT          NULL,
    [WOPartNoId]             BIGINT          NOT NULL,
    [WOBillingShippingId]    BIGINT          NULL,
    [Revenue]                DECIMAL (20, 2) NULL,
    [PartsCost]              DECIMAL (20, 2) NULL,
    [PartsRevPercentage]     DECIMAL (20, 2) NULL,
    [LaborCost]              DECIMAL (20, 2) NULL,
    [LaborRevPercentage]     DECIMAL (20, 2) NULL,
    [OverHeadCost]           DECIMAL (20, 2) NULL,
    [OverHeadPercentage]     DECIMAL (20, 2) NULL,
    [OtherCost]              DECIMAL (20, 2) NULL,
    [DirectCost]             DECIMAL (20, 2) NULL,
    [DirectCostPercentage]   DECIMAL (20, 2) NULL,
    [Margin]                 DECIMAL (20, 2) NULL,
    [MarginPercentage]       DECIMAL (20, 2) NULL,
    [ChargesCost]            DECIMAL (20, 2) NULL,
    [ExclusionCost]          DECIMAL (20, 2) NULL,
    [FreightCost]            DECIMAL (20, 2) NULL,
    [TotalCost]              DECIMAL (20, 2) NULL,
    [ActualRevenue]          DECIMAL (20, 2) NULL,
    [ActualMargin]           DECIMAL (20, 2) NULL,
    [ActualMarginPercentage] DECIMAL (20, 2) NULL,
    [MasterCompanyId]        INT             NOT NULL,
    [CreatedBy]              VARCHAR (256)   NOT NULL,
    [UpdatedBy]              VARCHAR (256)   NOT NULL,
    [CreatedDate]            DATETIME2 (7)   CONSTRAINT [DF_WorkOrderCostDetails_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)   CONSTRAINT [DF_WorkOrderCostDetails_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT             CONSTRAINT [WorkOrderCostDetails_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT             CONSTRAINT [WorkOrderCostDetails_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderCostDetails] PRIMARY KEY CLUSTERED ([WorkOrderCostDetailsId] ASC),
    CONSTRAINT [FK_WorkOrderCostDetails_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderCostDetails_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId]),
    CONSTRAINT [FK_WorkOrderCostDetails_WorkOrderPartNumber] FOREIGN KEY ([WOPartNoId]) REFERENCES [dbo].[WorkOrderPartNumber] ([ID])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderCostDetailsAudit]

   ON  [dbo].[WorkOrderCostDetails]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderCostDetailsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END