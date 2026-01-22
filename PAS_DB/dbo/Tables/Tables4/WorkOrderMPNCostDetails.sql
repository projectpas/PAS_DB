CREATE TABLE [dbo].[WorkOrderMPNCostDetails] (
    [WorkOrderMPNCostDetailsId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]               BIGINT          NOT NULL,
    [WOQuoteId]                 BIGINT          NULL,
    [WOPartNoId]                BIGINT          NOT NULL,
    [WOBillingShippingId]       BIGINT          NULL,
    [Revenue]                   DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMPNCostDetails_Revenue] DEFAULT ((0)) NULL,
    [PartsCost]                 DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMPNCostDetails_PartsCost] DEFAULT ((0)) NULL,
    [PartsRevPercentage]        DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMPNCostDetails_PartsRevPercentage] DEFAULT ((0)) NULL,
    [LaborCost]                 DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMPNCostDetails_LaborCost] DEFAULT ((0)) NULL,
    [LaborRevPercentage]        DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMPNCostDetails_LaborRevPercentage] DEFAULT ((0)) NULL,
    [OverHeadCost]              DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMPNCostDetails_OverHeadCost] DEFAULT ((0)) NULL,
    [OverHeadPercentage]        DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMPNCostDetails_OverHeadPercentage] DEFAULT ((0)) NULL,
    [OtherCost]                 DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMPNCostDetails_OtherCost] DEFAULT ((0)) NULL,
    [DirectCost]                DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMPNCostDetails_DirectCost] DEFAULT ((0)) NULL,
    [DirectCostPercentage]      DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMPNCostDetails_DirectCostPercentage] DEFAULT ((0)) NULL,
    [Margin]                    DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMPNCostDetails_Margin] DEFAULT ((0)) NULL,
    [MarginPercentage]          DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMPNCostDetails_MarginPercentage] DEFAULT ((0)) NULL,
    [ChargesCost]               DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMPNCostDetails_ChargesCost] DEFAULT ((0)) NULL,
    [ExclusionCost]             DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMPNCostDetails_ExclusionCost] DEFAULT ((0)) NULL,
    [FreightCost]               DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMPNCostDetails_FreightCost] DEFAULT ((0)) NULL,
    [TotalCost]                 DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMPNCostDetails_TotalCost] DEFAULT ((0)) NULL,
    [ActualRevenue]             DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMPNCostDetails_ActualRevenue] DEFAULT ((0)) NULL,
    [ActualMargin]              DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMPNCostDetails_ActualMargin] DEFAULT ((0)) NULL,
    [ActualMarginPercentage]    DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderMPNCostDetails_ActualMarginPercentage] DEFAULT ((0)) NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]               DATETIME2 (7)   CONSTRAINT [DF_WorkOrderMPNCostDetails_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   CONSTRAINT [DF_WorkOrderMPNCostDetails_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT             CONSTRAINT [WorkOrderMPNCostDetails_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT             CONSTRAINT [WorkOrderMPNCostDetails_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderMPNCostDetails] PRIMARY KEY CLUSTERED ([WorkOrderMPNCostDetailsId] ASC),
    CONSTRAINT [FK_WorkOrderMPNCostDetails_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderMPNCostDetails_WOQuoteId] FOREIGN KEY ([WOQuoteId]) REFERENCES [dbo].[WorkOrderQuote] ([WorkOrderQuoteId]),
    CONSTRAINT [FK_WorkOrderMPNCostDetails_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId]),
    CONSTRAINT [FK_WorkOrderMPNCostDetails_WorkOrderPartNumber] FOREIGN KEY ([WOPartNoId]) REFERENCES [dbo].[WorkOrderPartNumber] ([ID])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderMPNCostDetailsAudit]

   ON  [dbo].[WorkOrderMPNCostDetails]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderMPNCostDetailsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END