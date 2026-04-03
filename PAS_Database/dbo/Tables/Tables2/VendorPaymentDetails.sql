CREATE TABLE [dbo].[VendorPaymentDetails] (
    [VendorPaymentDetailsId]        BIGINT          IDENTITY (1, 1) NOT NULL,
    [ReadyToPayId]                  BIGINT          NOT NULL,
    [DueDate]                       DATETIME        NULL,
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
    [OriginalTotal]                 DECIMAL (18, 2) NULL,
    [RRTotal]                       DECIMAL (18, 2) NULL,
    [InvoiceTotal]                  DECIMAL (18, 2) NULL,
    [DIfferenceAmount]              DECIMAL (18, 2) NULL,
    [TotalAdjustAmount]             DECIMAL (18, 2) NULL,
    [StatusId]                      INT             NULL,
    [Status]                        VARCHAR (50)    NULL,
    [MasterCompanyId]               INT             NULL,
    [CreatedBy]                     VARCHAR (256)   NOT NULL,
    [UpdatedBy]                     VARCHAR (256)   NOT NULL,
    [CreatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_VendorPaymentDetails_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_VendorPaymentDetails_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                      BIT             CONSTRAINT [DF_VendorPaymentDetails_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT             CONSTRAINT [DF_VendorPaymentDetails_IsDeleted] DEFAULT ((0)) NOT NULL,
    [RemainingAmount]               DECIMAL (18, 2) NULL,
    [NonPOInvoiceId]                BIGINT          NULL,
    [CustomerCreditPaymentDetailId] BIGINT          NULL,
    [CreditMemoHeaderId]            BIGINT          NULL,
    [VendorProformaInvoiceId]       BIGINT          NULL,
    [LastMSLevel]                   VARCHAR (256)   NULL,
    [LegalEntityId]                 BIGINT          NULL,
    [ManualJournalHeaderId]         BIGINT          NULL,
    [ManualJournalDetailsId]        BIGINT          NULL,
    CONSTRAINT [PK_VendorPaymentDetails] PRIMARY KEY CLUSTERED ([VendorPaymentDetailsId] ASC)
);


GO
create   TRIGGER [dbo].[Trg_VendorPaymentDetailsAudit]
ON [dbo].[VendorPaymentDetails]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

	INSERT INTO [dbo].[VendorPaymentDetailsAudit]
           ([VendorPaymentDetailsId]
           ,[ReadyToPayId]
           ,[DueDate]
           ,[VendorId]
           ,[VendorName]
           ,[PaymentMethodId]
           ,[PaymentMethodName]
           ,[ReceivingReconciliationId]
           ,[InvoiceNum]
           ,[CurrencyId]
           ,[CurrencyName]
           ,[FXRate]
           ,[OriginalAmount]
           ,[PaymentMade]
           ,[AmountDue]
           ,[DaysPastDue]
           ,[DiscountDate]
           ,[DiscountAvailable]
           ,[DiscountToken]
           ,[OriginalTotal]
           ,[RRTotal]
           ,[InvoiceTotal]
           ,[DIfferenceAmount]
           ,[TotalAdjustAmount]
           ,[StatusId]
           ,[Status]
           ,[MasterCompanyId]
           ,[CreatedBy]
           ,[UpdatedBy]
           ,[CreatedDate]
           ,[UpdatedDate]
           ,[IsActive]
           ,[IsDeleted]
           ,[RemainingAmount]
           ,[NonPOInvoiceId]
           ,[CustomerCreditPaymentDetailId]
           ,[CreditMemoHeaderId]
           ,[VendorProformaInvoiceId]
           ,[LastMSLevel]
           ,[LegalEntityId]
           ,[ManualJournalHeaderId]
           ,[ManualJournalDetailsId])
		SELECT
		    i.[VendorPaymentDetailsId]
           ,i.[ReadyToPayId]
           ,i.[DueDate]
           ,i.[VendorId]
           ,i.[VendorName]
           ,i.[PaymentMethodId]
           ,i.[PaymentMethodName]
           ,i.[ReceivingReconciliationId]
           ,i.[InvoiceNum]
           ,i.[CurrencyId]
           ,i.[CurrencyName]
           ,i.[FXRate]
           ,i.[OriginalAmount]
           ,i.[PaymentMade]
           ,i.[AmountDue]
           ,i.[DaysPastDue]
           ,i.[DiscountDate]
           ,i.[DiscountAvailable]
           ,i.[DiscountToken]
           ,i.[OriginalTotal]
           ,i.[RRTotal]
           ,i.[InvoiceTotal]
           ,i.[DIfferenceAmount]
           ,i.[TotalAdjustAmount]
           ,i.[StatusId]
           ,i.[Status]
           ,i.[MasterCompanyId]
           ,i.[CreatedBy]
           ,i.[UpdatedBy]
           ,i.[CreatedDate]
           ,i.[UpdatedDate]
           ,i.[IsActive]
           ,i.[IsDeleted]
           ,i.[RemainingAmount]
           ,i.[NonPOInvoiceId]
           ,i.[CustomerCreditPaymentDetailId]
           ,i.[CreditMemoHeaderId]
           ,i.[VendorProformaInvoiceId]
           ,i.[LastMSLevel]
           ,i.[LegalEntityId]
           ,i.[ManualJournalHeaderId]
           ,i.[ManualJournalDetailsId]
         FROM INSERTED i;
END