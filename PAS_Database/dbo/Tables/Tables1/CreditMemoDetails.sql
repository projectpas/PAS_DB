CREATE TABLE [dbo].[CreditMemoDetails] (
    [CreditMemoDetailId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [CreditMemoHeaderId]     BIGINT          NOT NULL,
    [RMAHeaderId]            BIGINT          NULL,
    [InvoiceId]              BIGINT          NOT NULL,
    [ItemMasterId]           BIGINT          NOT NULL,
    [PartNumber]             VARCHAR (100)   NULL,
    [PartDescription]        VARCHAR (MAX)   NULL,
    [AltPartNumber]          VARCHAR (100)   NULL,
    [CustPartNumber]         VARCHAR (100)   NULL,
    [SerialNumber]           VARCHAR (100)   NULL,
    [Qty]                    INT             NOT NULL,
    [UnitPrice]              DECIMAL (18, 2) NOT NULL,
    [Amount]                 DECIMAL (18, 2) NOT NULL,
    [ReasonId]               INT             NOT NULL,
    [Reason]                 VARCHAR (500)   NULL,
    [StocklineId]            BIGINT          NULL,
    [StocklineNumber]        VARCHAR (100)   NULL,
    [ControlNumber]          VARCHAR (100)   NULL,
    [ControlId]              VARCHAR (100)   NULL,
    [ReferenceId]            BIGINT          NULL,
    [ReferenceNo]            VARCHAR (100)   NULL,
    [SOWONum]                VARCHAR (100)   NULL,
    [Notes]                  NVARCHAR (MAX)  NULL,
    [IsWorkOrder]            BIT             CONSTRAINT [DF_Table_1_isWorkOrder] DEFAULT ((0)) NULL,
    [MasterCompanyId]        INT             NOT NULL,
    [CreatedBy]              VARCHAR (256)   NOT NULL,
    [UpdatedBy]              VARCHAR (256)   NOT NULL,
    [CreatedDate]            DATETIME2 (7)   CONSTRAINT [DF_CreditMemoDetails_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)   CONSTRAINT [DF_CreditMemoDetails_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT             CONSTRAINT [DF_CreditMemoDetails_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT             CONSTRAINT [DF_CreditMemoDetails_IsDeleted] DEFAULT ((0)) NOT NULL,
    [RMADeatilsId]           BIGINT          NULL,
    [BillingInvoicingItemId] BIGINT          NULL,
    [SalesTax]               DECIMAL (18, 2) NULL,
    [OtherTax]               DECIMAL (18, 2) NULL,
    [PartsRevenue]           DECIMAL (18, 2) NULL,
    [LaborRevenue]           DECIMAL (18, 2) NULL,
    [MiscRevenue]            DECIMAL (18, 2) NULL,
    [FreightRevenue]         DECIMAL (18, 2) NULL,
    [RestockingFee]          DECIMAL (18, 2) NULL,
    [CogsParts]              DECIMAL (18, 2) NULL,
    [CogsLabor]              DECIMAL (18, 2) NULL,
    [CogsOverHeadCost]       DECIMAL (18, 2) NULL,
    [CogsInventory]          DECIMAL (18, 2) NULL,
    [PartsUnitCost]          DECIMAL (18, 2) NULL,
    [COGSPartsUnitCost]      DECIMAL (18, 2) NULL,
    [InvoiceTypeId]          INT             NULL,
    CONSTRAINT [PK_CreditMemoDetails] PRIMARY KEY CLUSTERED ([CreditMemoDetailId] ASC)
);














GO





CREATE TRIGGER [dbo].[Trg_CreditMemoDetailsAudit]
ON  [dbo].[CreditMemoDetails]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO [dbo].[CreditMemoDetailsAudit]
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END