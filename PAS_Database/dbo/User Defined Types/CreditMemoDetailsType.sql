CREATE TYPE [dbo].[CreditMemoDetailsType] AS TABLE (
    [CreditMemoDetailId]     BIGINT          NULL,
    [CreditMemoHeaderId]     BIGINT          NULL,
    [RMAHeaderId]            BIGINT          NULL,
    [InvoiceId]              BIGINT          NULL,
    [ItemMasterId]           BIGINT          NULL,
    [PartNumber]             VARCHAR (100)   NULL,
    [PartDescription]        VARCHAR (MAX)   NULL,
    [AltPartNumber]          VARCHAR (100)   NULL,
    [CustPartNumber]         VARCHAR (100)   NULL,
    [SerialNumber]           VARCHAR (100)   NULL,
    [Qty]                    INT             NULL,
    [UnitPrice]              DECIMAL (18, 2) NULL,
    [SalesTax]               DECIMAL (18, 2) NULL,
    [OtherTax]               DECIMAL (18, 2) NULL,
    [Amount]                 DECIMAL (18, 2) NULL,
    [ReasonId]               INT             NULL,
    [Reason]                 VARCHAR (500)   NULL,
    [StocklineId]            BIGINT          NULL,
    [StocklineNumber]        VARCHAR (100)   NULL,
    [ControlNumber]          VARCHAR (100)   NULL,
    [ControlId]              VARCHAR (100)   NULL,
    [ReferenceId]            BIGINT          NULL,
    [ReferenceNo]            VARCHAR (100)   NULL,
    [SOWONum]                VARCHAR (100)   NULL,
    [Notes]                  NVARCHAR (MAX)  NULL,
    [IsWorkOrder]            BIT             NULL,
    [MasterCompanyId]        INT             NULL,
    [CreatedBy]              VARCHAR (256)   NULL,
    [UpdatedBy]              VARCHAR (256)   NULL,
    [CreatedDate]            DATETIME2 (7)   NULL,
    [UpdatedDate]            DATETIME2 (7)   NULL,
    [IsActive]               BIT             NULL,
    [IsDeleted]              BIT             NULL,
    [RMADeatilsId]           BIGINT          NULL,
    [BillingInvoicingItemId] BIGINT          NULL,
    [PartsUnitCost]          DECIMAL (18, 2) NULL,
    [PartsRevenue]           DECIMAL (18, 2) NULL,
    [LaborRevenue]           DECIMAL (18, 2) NULL,
    [MiscRevenue]            DECIMAL (18, 2) NULL,
    [FreightRevenue]         DECIMAL (18, 2) NULL,
    [RestockingFee]          DECIMAL (18, 2) NULL,
    [CogsParts]              DECIMAL (18, 2) NULL,
    [CogsLabor]              DECIMAL (18, 2) NULL,
    [CogsOverHeadCost]       DECIMAL (18, 2) NULL,
    [CogsInventory]          DECIMAL (18, 2) NULL,
    [COGSPartsUnitCost]      DECIMAL (18, 2) NULL);









