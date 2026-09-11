CREATE TABLE [dbo].[WorkOrderQuoteTask] (
    [WorkOrderQuoteTaskId]          BIGINT          IDENTITY (1, 1) NOT NULL,
    [WOPartNoId]                    BIGINT          NOT NULL,
    [TaskId]                        BIGINT          DEFAULT ((0)) NOT NULL,
    [LaborHours]                    INT             NULL,
    [LaborCost]                     DECIMAL (28, 6) NULL,
    [LaborBilling]                  DECIMAL (28, 6) NULL,
    [LaborRevenue]                  DECIMAL (28, 6) NULL,
    [LaborRevnuePercentage]         DECIMAL (28, 6) NULL,
    [LaborMargin]                   DECIMAL (28, 6) NULL,
    [MaterialCost]                  DECIMAL (28, 6) NULL,
    [MaterialBilling]               DECIMAL (28, 6) NULL,
    [MaterialRevenue]               DECIMAL (28, 6) NULL,
    [MaterialRevnuePercentage]      DECIMAL (28, 6) NULL,
    [MaterialMargin]                DECIMAL (28, 6) NULL,
    [ChargesCost]                   DECIMAL (28, 6) NULL,
    [ChargesBilling]                DECIMAL (28, 6) NULL,
    [ChargesRevenue]                DECIMAL (28, 6) NULL,
    [ChargesRevnuePercentage]       DECIMAL (28, 6) NULL,
    [ChargesMargin]                 DECIMAL (28, 6) NULL,
    [FreightCost]                   DECIMAL (28, 6) NULL,
    [FreightBilling]                DECIMAL (28, 6) NULL,
    [FreightRevenue]                DECIMAL (28, 6) NULL,
    [FreightRevnuePercentage]       DECIMAL (28, 6) NULL,
    [FreightMargin]                 DECIMAL (28, 6) NULL,
    [ExclusionsCost]                DECIMAL (28, 6) NULL,
    [ExclusionsBilling]             DECIMAL (28, 6) NULL,
    [ExclusionsRevenue]             DECIMAL (28, 6) NULL,
    [ExclusionsRevnuePercentage]    DECIMAL (28, 6) NULL,
    [ExclusionsMargin]              DECIMAL (28, 6) NULL,
    [MasterCompanyId]               INT             NOT NULL,
    [CreatedBy]                     VARCHAR (256)   NOT NULL,
    [UpdatedBy]                     VARCHAR (256)   NOT NULL,
    [CreatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_WorkOrderQuoteTask_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_WorkOrderQuoteTask_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                      BIT             CONSTRAINT [WorkOrderQuoteTask_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT             CONSTRAINT [WorkOrderQuoteTask_DC_Delete] DEFAULT ((0)) NOT NULL,
    [MaterialMarginPer]             DECIMAL (28, 6) NULL,
    [LaborMarginPer]                DECIMAL (28, 6) NULL,
    [ChargesMarginPer]              DECIMAL (28, 6) NULL,
    [ExclusionsMarginPer]           DECIMAL (28, 6) NULL,
    [FreightMarginPer]              DECIMAL (28, 6) NULL,
    [OverHeadCost]                  DECIMAL (28, 6) NULL,
    [AdjustmentHours]               INT             NULL,
    [AdjustedHours]                 INT             NULL,
    [WorkOrderLaborHeaderId]        BIGINT          NULL,
    [ChargesRevenuePercentage]      DECIMAL (28, 6) NULL,
    [ExclusionsRevenuePercentage]   DECIMAL (28, 6) NULL,
    [FreightRevenuePercentage]      DECIMAL (28, 6) NULL,
    [LaborRevenuePercentage]        DECIMAL (28, 6) NULL,
    [MaterialRevenuePercentage]     DECIMAL (28, 6) NULL,
    [OverHeadCostRevenuePercentage] DECIMAL (28, 6) NULL,
    [IsKitPart]                     BIT             NULL,
    CONSTRAINT [PK_WorkOrderQuoteTask] PRIMARY KEY CLUSTERED ([WorkOrderQuoteTaskId] ASC),
    CONSTRAINT [FK_WorkOrderQuoteTask_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderQuoteTask_WorkOrderPartNumber] FOREIGN KEY ([WOPartNoId]) REFERENCES [dbo].[WorkOrderPartNumber] ([ID])
);






GO




CREATE TRIGGER [dbo].[Trg_WorkOrderQuoteTaskAudit]

   ON  [dbo].[WorkOrderQuoteTask]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderQuoteTaskAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END