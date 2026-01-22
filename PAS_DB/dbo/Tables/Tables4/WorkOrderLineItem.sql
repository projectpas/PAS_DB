CREATE TABLE [dbo].[WorkOrderLineItem] (
    [LineItemNumber]        INT           IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]           BIGINT        NOT NULL,
    [PartNumber]            INT           NOT NULL,
    [PartNumberDescription] VARCHAR (30)  NULL,
    [QuantityRequired]      SMALLINT      NULL,
    [QuantityReserved]      SMALLINT      NULL,
    [QuantityIssued]        SMALLINT      NULL,
    [QuantityTurnIn]        SMALLINT      NULL,
    [StockControlNumber]    INT           NULL,
    [SerialNumber]          VARCHAR (30)  NULL,
    [Condition]             VARCHAR (30)  NULL,
    [ProvisionId]           TINYINT       NULL,
    [SubWorkOrderId]        INT           NULL,
    [PurchaseOrderId]       INT           NULL,
    [RepairOrderId]         INT           NULL,
    [WorkFlowAssignment]    VARCHAR (30)  NULL,
    [MasterComapnyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [DF_WorkOrderLineItem_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [DF_WorkOrderLineItem_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [DF_WorkOrderLineItem_IsActive] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_WorkOrderLineItem] PRIMARY KEY CLUSTERED ([LineItemNumber] ASC),
    CONSTRAINT [FK_WorkOrderLineItem_MasterCompany] FOREIGN KEY ([MasterComapnyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderLineItem_Provision] FOREIGN KEY ([ProvisionId]) REFERENCES [dbo].[WorkOrderProvision] ([WorkOrderProvisionId]),
    CONSTRAINT [FK_WorkOrderLineItem_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrderMain] ([WorkOrderId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderLineItemudit]

   ON  [dbo].[WorkOrderLineItem]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderLineItemAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END