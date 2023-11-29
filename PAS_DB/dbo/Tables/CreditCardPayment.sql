CREATE TABLE [dbo].[CreditCardPayment] (
    [CreditCardPaymentId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerId]          BIGINT        NOT NULL,
    [CustomerFinancialId] BIGINT        NOT NULL,
    [PaymentMethodId]     BIGINT        NOT NULL,
    [CardNumber]          VARCHAR (100) NULL,
    [CardHolderName]      VARCHAR (100) NULL,
    [Address]             VARCHAR (250) NULL,
    [State]               VARCHAR (100) NULL,
    [PostalCode]          VARCHAR (100) NULL,
    [InActive]            BIT           NOT NULL,
    [IsDefault]           BIT           NOT NULL,
    [ExpirationDate]      DATETIME2 (7) NOT NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [CreatedDate]         DATETIME2 (7) CONSTRAINT [DF_CreditCardPayment_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) CONSTRAINT [DF_CreditCardPayment_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]            BIT           CONSTRAINT [DF_CreditCardPayment_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT           CONSTRAINT [DF_CreditCardPayment_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CreditCardPayment] PRIMARY KEY CLUSTERED ([CreditCardPaymentId] ASC),
    CONSTRAINT [FK_CreditCardPayment_customerFinancialId] FOREIGN KEY ([CustomerFinancialId]) REFERENCES [dbo].[CustomerFinancial] ([CustomerFinancialId]),
    CONSTRAINT [FK_CreditCardPayment_customerId] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId])
);


GO
/****************************   
** Author:  Devendra Shekh
** Create date:  25-08-2023
** Description: this trigger is used to insert data into [CreditCardPaymentAudit]
  
EXEC [Trg_CreditCardPaymentAudit] 
******** 
** Change History 
********   
** PR   Date			Author				  Change Description  
** --   --------		-------				--------------------------------
** 1    21-07-2023      Devendra Shekh          created
 
****************************/
CREATE   TRIGGER [dbo].[Trg_CreditCardPaymentAudit]

   ON  [dbo].[CreditCardPayment]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[CreditCardPaymentAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END