﻿CREATE TABLE [dbo].[WorkOrderBillingInvoicingAudit] (
    [BillingInvoicingAuditId]            BIGINT          IDENTITY (1, 1) NOT NULL,
    [BillingInvoicingId]                 BIGINT          NOT NULL,
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
    [CreatedDate]                        DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                        DATETIME2 (7)   NOT NULL,
    [IsActive]                           BIT             NOT NULL,
    [IsDeleted]                          BIT             NOT NULL,
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
    [ProformaDeposit]                    DECIMAL (18, 2) NULL,
    [IsReversedJE]                       BIT             NULL,
    CONSTRAINT [PK_WorkOrderBillingInvoicingAudit] PRIMARY KEY CLUSTERED ([BillingInvoicingAuditId] ASC),
    FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId])
);















