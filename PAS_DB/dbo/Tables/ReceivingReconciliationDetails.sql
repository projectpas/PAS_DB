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
    [POQtyOrder]                      INT             NULL,
    [ReceivedQty]                     INT             NULL,
    [POUnitCost]                      DECIMAL (18, 2) NULL,
    [POExtCost]                       DECIMAL (18, 2) NULL,
    [InvoicedQty]                     INT             NULL,
    [InvoicedUnitCost]                DECIMAL (18, 2) NULL,
    [InvoicedExtCost]                 DECIMAL (18, 2) NULL,
    [AdjQty]                          INT             NULL,
    [AdjUnitCost]                     DECIMAL (18, 2) NULL,
    [AdjExtCost]                      DECIMAL (18, 2) NULL,
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
    [RemainingRRQty]                  INT             NULL,
    [FreightAdjustment]               DECIMAL (18, 2) NULL,
    [TaxAdjustment]                   DECIMAL (18, 2) NULL,
    [FreightAdjustmentPerUnit]        DECIMAL (18, 2) NULL,
    [TaxAdjustmentPerUnit]            DECIMAL (18, 2) NULL,
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