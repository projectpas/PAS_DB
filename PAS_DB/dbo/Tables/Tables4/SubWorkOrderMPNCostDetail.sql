CREATE TABLE [dbo].[SubWorkOrderMPNCostDetail] (
    [SubWOMPNCostDetailsId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]            BIGINT          NOT NULL,
    [SubWorkOrderId]         BIGINT          NOT NULL,
    [SubWOPartNoId]          BIGINT          NOT NULL,
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
    [FreightCost]            DECIMAL (20, 2) NULL,
    [TotalCost]              DECIMAL (20, 2) NULL,
    [ActualRevenue]          DECIMAL (20, 2) NULL,
    [ActualMargin]           DECIMAL (20, 2) NULL,
    [ActualMarginPercentage] DECIMAL (20, 2) NULL,
    [MasterCompanyId]        INT             NOT NULL,
    [CreatedBy]              VARCHAR (256)   NOT NULL,
    [UpdatedBy]              VARCHAR (256)   NOT NULL,
    [CreatedDate]            DATETIME2 (7)   CONSTRAINT [DF_SubWorkOrderMPNCostDetail_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)   CONSTRAINT [DF_SubWorkOrderMPNCostDetail_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT             CONSTRAINT [SubWorkOrderMPNCostDetail_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT             CONSTRAINT [SubWorkOrderMPNCostDetail_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SubWorkOrderMPNCostDetail] PRIMARY KEY CLUSTERED ([SubWOMPNCostDetailsId] ASC),
    CONSTRAINT [FK_SubWorkOrderMPNCostDetail_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SubWorkOrderMPNCostDetail_SubWorkOrder] FOREIGN KEY ([SubWorkOrderId]) REFERENCES [dbo].[SubWorkOrder] ([SubWorkOrderId]),
    CONSTRAINT [FK_SubWorkOrderMPNCostDetail_SubWorkOrderPartNumber] FOREIGN KEY ([SubWOPartNoId]) REFERENCES [dbo].[SubWorkOrderPartNumber] ([SubWOPartNoId]),
    CONSTRAINT [FK_SubWorkOrderMPNCostDetail_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);


GO




CREATE TRIGGER [dbo].[Trg_SubWorkOrderMPNCostDetailAudit]

   ON  [dbo].[SubWorkOrderMPNCostDetail]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO SubWorkOrderMPNCostDetailAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END