CREATE TABLE [dbo].[WorkOrderQuoteDetails] (
    [WorkOrderQuoteDetailsId]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderQuoteId]              BIGINT          NOT NULL,
    [ItemMasterId]                  BIGINT          NOT NULL,
    [BuildMethodId]                 BIGINT          NOT NULL,
    [MasterCompanyId]               INT             NOT NULL,
    [CreatedBy]                     VARCHAR (256)   NOT NULL,
    [UpdatedBy]                     VARCHAR (256)   NOT NULL,
    [CreatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_WorkOrderQuoteDetails_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_WorkOrderQuoteDetails_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                      BIT             DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT             DEFAULT ((0)) NOT NULL,
    [WorkflowWorkOrderId]           BIGINT          NULL,
    [WOPartNoId]                    BIGINT          NULL,
    [MaterialCost]                  DECIMAL (18, 6) NULL,
    [MaterialBilling]               DECIMAL (18, 6) NULL,
    [MaterialRevenuePercentage]     DECIMAL (18, 6) NULL,
    [MaterialMargin]                DECIMAL (18, 6) NULL,
    [LaborHours]                    INT             NULL,
    [LaborCost]                     DECIMAL (18, 6) NULL,
    [LaborBilling]                  DECIMAL (18, 6) NULL,
    [LaborRevenuePercentage]        DECIMAL (18, 6) NULL,
    [LaborMargin]                   DECIMAL (18, 6) NULL,
    [ChargesCost]                   DECIMAL (18, 6) NULL,
    [ChargesBilling]                DECIMAL (18, 6) NULL,
    [ChargesRevenuePercentage]      DECIMAL (18, 6) NULL,
    [ChargesMargin]                 DECIMAL (18, 6) NULL,
    [ExclusionsCost]                DECIMAL (18, 6) NULL,
    [ExclusionsBilling]             DECIMAL (18, 6) NULL,
    [ExclusionsRevenuePercentage]   DECIMAL (18, 6) NULL,
    [ExclusionsMargin]              DECIMAL (18, 6) NULL,
    [FreightCost]                   DECIMAL (18, 6) NULL,
    [FreightBilling]                DECIMAL (18, 6) NULL,
    [FreightRevenuePercentage]      DECIMAL (18, 6) NULL,
    [FreightMargin]                 DECIMAL (18, 6) NULL,
    [MaterialMarginPer]             DECIMAL (18, 6) NULL,
    [LaborMarginPer]                DECIMAL (18, 6) NULL,
    [ChargesMarginPer]              DECIMAL (18, 6) NULL,
    [ExclusionsMarginPer]           DECIMAL (18, 6) NULL,
    [FreightMarginPer]              DECIMAL (18, 6) NULL,
    [OverHeadCost]                  DECIMAL (18, 6) NULL,
    [AdjustmentHours]               INT             NULL,
    [AdjustedHours]                 INT             NULL,
    [LaborFlatBillingAmount]        DECIMAL (18, 6) NULL,
    [MaterialFlatBillingAmount]     DECIMAL (18, 6) NULL,
    [ChargesFlatBillingAmount]      DECIMAL (18, 6) NULL,
    [FreightFlatBillingAmount]      DECIMAL (18, 6) NULL,
    [MaterialBuildMethod]           INT             NULL,
    [LaborBuildMethod]              INT             NULL,
    [ChargesBuildMethod]            INT             NULL,
    [FreightBuildMethod]            INT             NULL,
    [ExclusionsBuildMethod]         INT             NULL,
    [MaterialMarkupId]              BIGINT          NULL,
    [LaborMarkupId]                 BIGINT          NULL,
    [ChargesMarkupId]               BIGINT          NULL,
    [FreightMarkupId]               BIGINT          NULL,
    [ExclusionsMarkupId]            BIGINT          NULL,
    [FreightRevenue]                DECIMAL (18, 6) NULL,
    [LaborRevenue]                  DECIMAL (18, 6) NULL,
    [MaterialRevenue]               DECIMAL (18, 6) NULL,
    [ExclusionsRevenue]             DECIMAL (18, 6) NULL,
    [ChargesRevenue]                DECIMAL (18, 6) NULL,
    [OverHeadCostRevenuePercentage] DECIMAL (18, 6) NULL,
    [QuoteParentId]                 BIGINT          NULL,
    [IsVersionIncrease]             BIT             DEFAULT ((0)) NOT NULL,
    [QuoteMethod]                   BIT             DEFAULT ((0)) NULL,
    [CommonFlatRate]                DECIMAL (18, 6) NULL,
    [EvalFees]                      DECIMAL (18, 6) NULL,
    CONSTRAINT [PK_WorkOrderQuoteDetails] PRIMARY KEY CLUSTERED ([WorkOrderQuoteDetailsId] ASC),
    CONSTRAINT [FK_WorkOrderQuoteDetails_ItemMasterId] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_WorkOrderQuoteDetails_MasterCompanyId] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderQuoteDetails_WOPartNoId] FOREIGN KEY ([WOPartNoId]) REFERENCES [dbo].[WorkOrderPartNumber] ([ID]),
    CONSTRAINT [FK_WorkOrderQuoteDetails_WorkFlowWorkOrderId] FOREIGN KEY ([WorkflowWorkOrderId]) REFERENCES [dbo].[WorkOrderWorkFlow] ([WorkFlowWorkOrderId]),
    CONSTRAINT [FK_WorkOrderQuoteDetails_WorkOrderQuote] FOREIGN KEY ([WorkOrderQuoteId]) REFERENCES [dbo].[WorkOrderQuote] ([WorkOrderQuoteId])
);




GO




CREATE TRIGGER [dbo].[Trg_WorkOrderQuoteDetailsAudit]

   ON  [dbo].[WorkOrderQuoteDetails]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderQuoteDetailsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END