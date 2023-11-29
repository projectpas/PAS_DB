CREATE TABLE [dbo].[VendorReadyToPayDetails] (
    [ReadyToPayDetailsId]           BIGINT          IDENTITY (1, 1) NOT NULL,
    [ReadyToPayId]                  BIGINT          NULL,
    [DueDate]                       DATETIME2 (7)   NULL,
    [VendorId]                      BIGINT          NULL,
    [VendorName]                    VARCHAR (100)   NULL,
    [PaymentMethodId]               INT             NULL,
    [PaymentMethodName]             VARCHAR (50)    NULL,
    [ReceivingReconciliationId]     BIGINT          NULL,
    [InvoiceNum]                    VARCHAR (100)   NULL,
    [CurrencyId]                    INT             NULL,
    [CurrencyName]                  VARCHAR (50)    NULL,
    [FXRate]                        NUMERIC (9, 4)  NULL,
    [OriginalAmount]                DECIMAL (18, 2) NULL,
    [PaymentMade]                   DECIMAL (18, 2) NULL,
    [AmountDue]                     DECIMAL (18, 2) NULL,
    [DaysPastDue]                   INT             NULL,
    [DiscountDate]                  DATETIME        NULL,
    [DiscountAvailable]             DECIMAL (18, 2) NULL,
    [DiscountToken]                 DECIMAL (18, 2) NULL,
    [MasterCompanyId]               INT             NULL,
    [CreatedBy]                     VARCHAR (256)   NOT NULL,
    [UpdatedBy]                     VARCHAR (256)   NOT NULL,
    [CreatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_VendorReadyToPayDetails_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_VendorReadyToPayDetails_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                      BIT             CONSTRAINT [DF_VendorReadyToPayDetails_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT             CONSTRAINT [DF_VendorReadyToPayDetails_IsDeleted] DEFAULT ((0)) NOT NULL,
    [VendorPaymentDetailsId]        BIGINT          NULL,
    [PdfPath]                       NVARCHAR (MAX)  NULL,
    [CheckNumber]                   NVARCHAR (MAX)  NULL,
    [CheckDate]                     DATETIME        NULL,
    [IsVoidedCheck]                 BIT             NULL,
    [IsCreditMemo]                  BIT             NULL,
    [CreditMemoAmount]              DECIMAL (18, 2) NULL,
    [CreditMemoHeaderId]            BIGINT          NULL,
    [IsCheckPrinted]                BIT             NULL,
    [VendorReadyToPayDetailsTypeId] INT             NULL,
    [NonPOInvoiceId]                BIGINT          NULL,
    CONSTRAINT [PK_ReadyToPayDetails] PRIMARY KEY CLUSTERED ([ReadyToPayDetailsId] ASC)
);






GO
CREATE   TRIGGER [dbo].[Trg_VendorReadyToPayDetailsAudit] ON [dbo].[VendorReadyToPayDetails]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  



 INSERT INTO [dbo].[VendorReadyToPayDetailsAudit]  

 SELECT * FROM INSERTED  



 SET NOCOUNT ON;  



END