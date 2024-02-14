CREATE TABLE [dbo].[WorkOrderBillingInvoicing] (
    [BillingInvoicingId]                 BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]                        BIGINT          NOT NULL,
    [WorkFlowWorkOrderId]                BIGINT          NOT NULL,
    [WorkOrderPartNoId]                  BIGINT          NULL,
    [ItemMasterId]                       BIGINT          NOT NULL,
    [InvoiceTypeId]                      BIGINT          NOT NULL,
    [InvoiceNo]                          VARCHAR (256)   NOT NULL,
    [CustomerId]                         BIGINT          NOT NULL,
    [InvoiceDate]                        DATETIME2 (7)   NULL,
    [InvoiceTime]                        VARCHAR (10)    NULL,
    [PrintDate]                          DATETIME2 (7)   NULL,
    [ShipDate]                           DATETIME2 (7)   NULL,
    [NoofPieces]                         INT             NULL,
    [EmployeeId]                         BIGINT          NOT NULL,
    [GateStatus]                         VARCHAR (200)   NULL,
    [SoldToCustomerId]                   BIGINT          NOT NULL,
    [SoldToSiteId]                       BIGINT          NOT NULL,
    [ShipToCustomerId]                   BIGINT          NOT NULL,
    [ShipToSiteId]                       BIGINT          NOT NULL,
    [ShipToAttention]                    VARCHAR (256)   NULL,
    [ManagementStructureId]              BIGINT          NULL,
    [Notes]                              NVARCHAR (MAX)  NULL,
    [CostPlusType]                       VARCHAR (15)    NOT NULL,
    [TotalWorkOrder]                     BIT             NULL,
    [TotalWorkOrderValue]                BIGINT          NULL,
    [Material]                           BIT             NULL,
    [MaterialValue]                      BIGINT          NULL,
    [LaborOverHead]                      BIT             NULL,
    [LaborOverHeadValue]                 BIGINT          NULL,
    [MiscCharges]                        BIT             NULL,
    [MiscChargesValue]                   BIGINT          NULL,
    [ProForma]                           BIT             NULL,
    [PartialInvoice]                     BIT             NULL,
    [CostPlusRateCombo]                  BIT             NULL,
    [ShipViaId]                          BIGINT          NULL,
    [WayBillRef]                         VARCHAR (100)   NULL,
    [Tracking]                           VARCHAR (100)   NULL,
    [MasterCompanyId]                    INT             NOT NULL,
    [CreatedBy]                          VARCHAR (256)   NOT NULL,
    [UpdatedBy]                          VARCHAR (256)   NOT NULL,
    [CreatedDate]                        DATETIME2 (7)   CONSTRAINT [DF_WorkOrderBillingInvoicing_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                        DATETIME2 (7)   CONSTRAINT [DF_WorkOrderBillingInvoicing_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                           BIT             DEFAULT ((1)) NOT NULL,
    [IsDeleted]                          BIT             DEFAULT ((0)) NOT NULL,
    [CurrencyId]                         INT             NULL,
    [AvailableCredit]                    DECIMAL (20, 2) NULL,
    [TotalWorkOrderCost]                 DECIMAL (20, 2) NULL,
    [TotalWorkOrderCostPlus]             DECIMAL (20, 2) NULL,
    [MaterialCost]                       DECIMAL (20, 2) NULL,
    [MaterialCostPlus]                   DECIMAL (20, 2) NULL,
    [LaborOverHeadCost]                  DECIMAL (20, 2) NULL,
    [LaborOverHeadCostPlus]              DECIMAL (20, 2) NULL,
    [MiscChargesCost]                    DECIMAL (20, 2) NULL,
    [MiscChargesCostPlus]                DECIMAL (20, 2) NULL,
    [GrandTotal]                         DECIMAL (20, 2) NULL,
    [RevisionTypeId]                     BIGINT          NULL,
    [WorkOrderShippingId]                BIGINT          NULL,
    [InvoiceStatus]                      VARCHAR (50)    NULL,
    [InvoiceFilePath]                    VARCHAR (1000)  NULL,
    [RevType]                            VARCHAR (200)   NULL,
    [VersionNo]                          VARCHAR (10)    NULL,
    [IsVersionIncrease]                  BIT             DEFAULT ((0)) NULL,
    [FreightCost]                        DECIMAL (18, 2) DEFAULT ((0.00)) NULL,
    [FreightCostPlus]                    DECIMAL (18, 2) DEFAULT ((0.00)) NULL,
    [Freight]                            BIT             DEFAULT ((0)) NULL,
    [FreightValue]                       DECIMAL (18, 2) DEFAULT ((0.00)) NULL,
    [CustomerDomensticShippingShipViaId] BIGINT          NULL,
    [ShippingAccountInfo]                VARCHAR (200)   NULL,
    [RemainingAmount]                    DECIMAL (20, 2) NULL,
    [PostedDate]                         DATETIME2 (7)   NULL,
    [TaxRate]                            DECIMAL (18, 2) NULL,
    [SalesTax]                           DECIMAL (18, 2) NULL,
    [OtherTax]                           DECIMAL (18, 2) NULL,
    [SubTotal]                           DECIMAL (18, 2) NULL,
    [IsCustomerShipping]                 BIT             NULL,
    [CreditMemoUsed]                     DECIMAL (18, 2) NULL,
    [ConditionId]                        BIGINT          NULL,
    [RevisedSerialNumber]                VARCHAR (50)    NULL,
    [IsPerformaInvoice]                  BIT             NULL,
    [DepositAmount]                      DECIMAL (18, 2) NULL,
    [IsInvoicePosted]                    BIT             NULL,
    [UsedDeposit]                        DECIMAL (18, 2) NULL,
    CONSTRAINT [PK_WorkOrderBillingInvoicing] PRIMARY KEY CLUSTERED ([BillingInvoicingId] ASC),
    FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_WorkOrderBillingInvoicing_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_WorkOrderBillingInvoicing_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_WorkOrderBillingInvoicing_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrderBillingInvoicing_InvoiceType] FOREIGN KEY ([InvoiceTypeId]) REFERENCES [dbo].[InvoiceType] ([InvoiceTypeId]),
    CONSTRAINT [FK_WorkOrderBillingInvoicing_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_WorkOrderBillingInvoicing_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderBillingInvoicing_RevisionType] FOREIGN KEY ([RevisionTypeId]) REFERENCES [dbo].[RevisionType] ([RevisionTypeId]),
    CONSTRAINT [FK_WorkOrderBillingInvoicing_ShipToCustomer] FOREIGN KEY ([ShipToCustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_WorkOrderBillingInvoicing_ShipToSite] FOREIGN KEY ([ShipToSiteId]) REFERENCES [dbo].[CustomerDomensticShipping] ([CustomerDomensticShippingId]),
    CONSTRAINT [FK_WorkOrderBillingInvoicing_SoldToCustomer] FOREIGN KEY ([SoldToCustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_WorkOrderBillingInvoicing_SoldToSite] FOREIGN KEY ([SoldToSiteId]) REFERENCES [dbo].[CustomerBillingAddress] ([CustomerBillingAddressId]),
    CONSTRAINT [FK_WorkOrderBillingInvoicing_WorkFlowWorkOrderId] FOREIGN KEY ([WorkFlowWorkOrderId]) REFERENCES [dbo].[WorkOrderWorkFlow] ([WorkFlowWorkOrderId]),
    CONSTRAINT [FK_WorkOrderBillingInvoicing_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId]),
    CONSTRAINT [FK_WorkOrderBillingInvoicing_WorkOrderPartNumber] FOREIGN KEY ([WorkOrderPartNoId]) REFERENCES [dbo].[WorkOrderPartNumber] ([ID])
);












GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_WorkOrderBillingInvoicingAudit]

   ON  [dbo].[WorkOrderBillingInvoicing]

   AFTER INSERT,UPDATE

AS 

BEGIN

 

	INSERT INTO [dbo].[WorkOrderBillingInvoicingAudit] 

    SELECT * 

	FROM INSERTED 

	SET NOCOUNT ON;



END