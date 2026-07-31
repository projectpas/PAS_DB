CREATE TABLE [dbo].[ReceivingReconciliationDetails] (
    [ReceivingReconciliationDetailId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ReceivingReconciliationId]       BIGINT          NOT NULL,
    [StocklineId]                     BIGINT          NULL,
    [StocklineNumber]                 VARCHAR (50)    NULL,
    [ItemMasterId]                    BIGINT          NULL,
    [PartNumber]                      VARCHAR (100)   NULL,
    [PartDescription]                 VARCHAR (MAX)   NULL,
    [SerialNumber]                    VARCHAR (50)    NULL,
    [POReference]                     VARCHAR (50)    NULL,
    [POQtyOrder]                      DECIMAL (18, 6) NULL,
    [ReceivedQty]                     DECIMAL (18, 6) NULL,
    [POUnitCost]                      DECIMAL (18, 6) NULL,
    [POExtCost]                       DECIMAL (18, 6) NULL,
    [InvoicedQty]                     DECIMAL (18, 6) NULL,
    [InvoicedUnitCost]                DECIMAL (18, 6) NULL,
    [InvoicedExtCost]                 DECIMAL (18, 6) NULL,
    [AdjQty]                          DECIMAL (18, 6) NULL,
    [AdjUnitCost]                     DECIMAL (18, 6) NULL,
    [AdjExtCost]                      DECIMAL (18, 6) NULL,
    [APNumber]                        VARCHAR (50)    NULL,
    [PurchaseOrderId]                 BIGINT          NULL,
    [PurchaseOrderPartRecordId]       BIGINT          NULL,
    [IsManual]                        BIT             DEFAULT ((0)) NULL,
    [PackagingId]                     INT             NULL,
    [Description]                     VARCHAR (200)   NULL,
    [GlAccountId]                     BIGINT          NULL,
    [GlAccountNumber]                 VARCHAR (200)   NULL,
    [GlAccountName]                   VARCHAR (200)   NULL,
    [Type]                            INT             NULL,
    [StockType]                       VARCHAR (50)    NULL,
    [RemainingRRQty]                  DECIMAL (18, 6) NULL,
    [FreightAdjustment]               DECIMAL (18, 6) NULL,
    [TaxAdjustment]                   DECIMAL (18, 6) NULL,
    [FreightAdjustmentPerUnit]        DECIMAL (18, 6) NULL,
    [TaxAdjustmentPerUnit]            DECIMAL (18, 6) NULL,
    [QtyVariance]                     DECIMAL (18, 6) NULL,
    [PriceVariance]                   DECIMAL (18, 6) NULL,
    [VendorProformaAmount]            DECIMAL (18, 6) NULL,
    [VendorProformaInvoiceId]         BIGINT          NULL,
    CONSTRAINT [PK_ReceivingReconciliationDetails] PRIMARY KEY CLUSTERED ([ReceivingReconciliationDetailId] ASC)
);














GO
CREATE TRIGGER [dbo].[Trg_ReceivingReconciliationDetailsAudit]
   ON  [dbo].[ReceivingReconciliationDetails]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO ReceivingReconciliationDetailsAudit
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END
GO
CREATE NONCLUSTERED INDEX [IX_RRDetails_Recon_Type_Order_Part]
    ON [dbo].[ReceivingReconciliationDetails]([ReceivingReconciliationId] ASC, [Type] ASC, [PurchaseOrderId] ASC, [PurchaseOrderPartRecordId] ASC)
    INCLUDE([InvoicedQty], [ReceivingReconciliationDetailId]);


GO
CREATE NONCLUSTERED INDEX [IX_RRD_Recon_Type_Order_Part]
    ON [dbo].[ReceivingReconciliationDetails]([ReceivingReconciliationId] ASC, [Type] ASC, [PurchaseOrderId] ASC, [PurchaseOrderPartRecordId] ASC)
    INCLUDE([InvoicedQty], [ReceivingReconciliationDetailId]);

