/*************************************************************           
 ** File:   [FleetQuoteDetails.sql]           
 ** Author:   SUMIT KUMAR
 ** Description: This Table is used to store Fleet Quote Detail Line Items
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteDetails] (
    [FleetQuoteDetailsId]           BIGINT          IDENTITY (1, 1) NOT NULL,
    [FleetQuoteId]                  BIGINT          NOT NULL,
    [ItemMasterId]                  BIGINT          NOT NULL,
    [BuildMethodId]                 BIGINT          NOT NULL,
    [MasterCompanyId]               INT             NOT NULL,
    [CreatedBy]                     VARCHAR (256)   NOT NULL,
    [UpdatedBy]                     VARCHAR (256)   NOT NULL,
    [CreatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_FleetQuoteDetails_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_FleetQuoteDetails_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                      BIT             CONSTRAINT [DF_FleetQuoteDetails_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT             CONSTRAINT [DF_FleetQuoteDetails_IsDeleted] DEFAULT ((0)) NOT NULL,
    [WorkflowWorkOrderId]           BIGINT          NULL,
    [WOPartNoId]                    BIGINT          NULL,
    [WorkOrderId]                   BIGINT          NULL,
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
    [IsVersionIncrease]             BIT             CONSTRAINT [DF_FleetQuoteDetails_IsVersionIncrease] DEFAULT ((0)) NOT NULL,
    [QuoteMethod]                   BIT             CONSTRAINT [DF_FleetQuoteDetails_QuoteMethod] DEFAULT ((0)) NULL,
    [CommonFlatRate]                DECIMAL (18, 6) NULL,
    [EvalFees]                      DECIMAL (18, 6) NULL,
    CONSTRAINT [PK_FleetQuoteDetails] PRIMARY KEY CLUSTERED ([FleetQuoteDetailsId] ASC),
    CONSTRAINT [FK_FleetQuoteDetails_FleetQuote] FOREIGN KEY ([FleetQuoteId]) REFERENCES [dbo].[FleetQuote] ([FleetQuoteId]),
    CONSTRAINT [FK_FleetQuoteDetails_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_FleetQuoteDetails_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_FleetQuoteDetails_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId]),
    CONSTRAINT [FK_FleetQuoteDetails_WOPartNoId] FOREIGN KEY ([WOPartNoId]) REFERENCES [dbo].[WorkOrderPartNumber] ([ID]),
    CONSTRAINT [FK_FleetQuoteDetails_WorkFlowWorkOrderId] FOREIGN KEY ([WorkflowWorkOrderId]) REFERENCES [dbo].[WorkOrderWorkFlow] ([WorkFlowWorkOrderId])
);

GO

/*************************************************************           
 ** File:   [Trg_FleetQuoteDetailsAudit]           
 ** Author:   SUMIT KUMAR
 ** Description: This Trigger is used to insert data into FleetQuoteDetailsAudit
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TRIGGER [dbo].[Trg_FleetQuoteDetailsAudit]
   ON [dbo].[FleetQuoteDetails]
   AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    INSERT INTO [dbo].[FleetQuoteDetailsAudit]
    SELECT * FROM INSERTED;
    SET NOCOUNT ON;
END;
