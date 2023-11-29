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
    [MaterialCost]                  DECIMAL (20, 2) NULL,
    [MaterialBilling]               DECIMAL (20, 2) NULL,
    [MaterialRevenuePercentage]     DECIMAL (20, 2) NULL,
    [MaterialMargin]                DECIMAL (20, 2) NULL,
    [LaborHours]                    INT             NULL,
    [LaborCost]                     DECIMAL (20, 2) NULL,
    [LaborBilling]                  DECIMAL (20, 2) NULL,
    [LaborRevenuePercentage]        DECIMAL (20, 2) NULL,
    [LaborMargin]                   DECIMAL (20, 2) NULL,
    [ChargesCost]                   DECIMAL (20, 2) NULL,
    [ChargesBilling]                DECIMAL (20, 2) NULL,
    [ChargesRevenuePercentage]      DECIMAL (20, 2) NULL,
    [ChargesMargin]                 DECIMAL (20, 2) NULL,
    [ExclusionsCost]                DECIMAL (20, 2) NULL,
    [ExclusionsBilling]             DECIMAL (20, 2) NULL,
    [ExclusionsRevenuePercentage]   DECIMAL (20, 2) NULL,
    [ExclusionsMargin]              DECIMAL (20, 2) NULL,
    [FreightCost]                   DECIMAL (20, 2) NULL,
    [FreightBilling]                DECIMAL (20, 2) NULL,
    [FreightRevenuePercentage]      DECIMAL (20, 2) NULL,
    [FreightMargin]                 DECIMAL (20, 2) NULL,
    [MaterialMarginPer]             DECIMAL (20, 2) NULL,
    [LaborMarginPer]                DECIMAL (20, 2) NULL,
    [ChargesMarginPer]              DECIMAL (20, 2) NULL,
    [ExclusionsMarginPer]           DECIMAL (20, 2) NULL,
    [FreightMarginPer]              DECIMAL (20, 2) NULL,
    [OverHeadCost]                  DECIMAL (20, 2) NULL,
    [AdjustmentHours]               INT             NULL,
    [AdjustedHours]                 INT             NULL,
    [LaborFlatBillingAmount]        DECIMAL (20, 2) NULL,
    [MaterialFlatBillingAmount]     DECIMAL (20, 2) NULL,
    [ChargesFlatBillingAmount]      DECIMAL (20, 2) NULL,
    [FreightFlatBillingAmount]      DECIMAL (20, 2) NULL,
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
    [FreightRevenue]                DECIMAL (20, 2) NULL,
    [LaborRevenue]                  DECIMAL (20, 2) NULL,
    [MaterialRevenue]               DECIMAL (20, 2) NULL,
    [ExclusionsRevenue]             DECIMAL (20, 2) NULL,
    [ChargesRevenue]                DECIMAL (20, 2) NULL,
    [OverHeadCostRevenuePercentage] DECIMAL (20, 2) NULL,
    [QuoteParentId]                 BIGINT          NULL,
    [IsVersionIncrease]             BIT             DEFAULT ((0)) NOT NULL,
    [QuoteMethod]                   BIT             DEFAULT ((0)) NULL,
    [CommonFlatRate]                DECIMAL (9, 2)  NULL,
    [EvalFees]                      DECIMAL (20, 2) NULL,
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