CREATE TABLE [dbo].[WorkOrderMarginAnalysis] (
    [WorkOrderMarginAnalysisId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]               BIGINT        NOT NULL,
    [Currency]                  VARCHAR (30)  NOT NULL,
    [PartsCost]                 VARCHAR (20)  NULL,
    [DirectLaborCost]           VARCHAR (20)  NULL,
    [OverheadApplied]           VARCHAR (20)  NULL,
    [RepairCost]                VARCHAR (20)  NULL,
    [MiscCharges]               VARCHAR (20)  NULL,
    [TotalCost]                 VARCHAR (20)  NULL,
    [EstimatedMargin]           VARCHAR (20)  NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (256) NOT NULL,
    [UpdatedBy]                 VARCHAR (256) NOT NULL,
    [CreatedDate]               DATETIME2 (7) CONSTRAINT [DF_WorkOrderMarginAnalysis_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) CONSTRAINT [DF_WorkOrderMarginAnalysis_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT           CONSTRAINT [DF_WorkOrderMarginAnalysis_IsActive] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [FK_WorkOrderMarginAnalysis_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderMarginAnalysis_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderMarginAnalysisAudit]

   ON  [dbo].[WorkOrderMarginAnalysis]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderMarginAnalysisAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END