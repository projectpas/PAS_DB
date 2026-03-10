CREATE TABLE [dbo].[WorkOrderCostDetails] (
    [WorkOrderCostDetailsId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]            BIGINT          NOT NULL,
    [WOQuoteId]              BIGINT          NULL,
    [WOPartNoId]             BIGINT          NOT NULL,
    [WOBillingShippingId]    BIGINT          NULL,
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
    [ExclusionCost]          DECIMAL (18, 6) NULL,
    [FreightCost]            DECIMAL (18, 6) NULL,
    [TotalCost]              DECIMAL (18, 6) NULL,
    [ActualRevenue]          DECIMAL (18, 6) NULL,
    [ActualMargin]           DECIMAL (18, 6) NULL,
    [ActualMarginPercentage] DECIMAL (18, 6) NULL,
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