CREATE TABLE [dbo].[CustomerCCPayments] (
    [CustomerCCPaymentsId]            BIGINT        IDENTITY (1, 1) NOT NULL,
    [LegalEntityId]                   BIGINT        NOT NULL,
    [CustomerName]                    VARCHAR (100) NULL,
    [CompanyBankAccount]              BIGINT        NOT NULL,
    [MerchantID]                      VARCHAR (230) NULL,
    [CurrencyId]                      VARCHAR (50)  NULL,
    [SupportedPaymentMethods]         VARCHAR (150) NULL,
    [GatewayRequestTypes]             VARCHAR (150) NULL,
    [TestMode]                        BIT           NULL,
    [PayerAuthentication]             BIT           NULL,
    [IgnoreAVSResponse]               BIT           NULL,
    [IgnoreCSCResponse]               BIT           NULL,
    [DisableSendingRecurringRequests] BIT           NULL,
    [InActive]                        BIT           NULL,
    [PartialAVSMatch]                 INT           NULL,
    [NoAVSMatch]                      INT           NULL,
    [AVSServiceNotAvailable]          INT           NULL,
    [NoCSCMatch]                      INT           NULL,
    [CSCNotSubmitted]                 INT           NULL,
    [CSCServiceNotAvailable]          INT           NULL,
    [CSCNotSupportedbyCardholderBank] INT           NULL,
    [MasterCompanyId]                 INT           NOT NULL,
    [CreatedBy]                       VARCHAR (256) NOT NULL,
    [UpdatedBy]                       VARCHAR (256) NOT NULL,
    [CreatedDate]                     DATETIME2 (7) CONSTRAINT [DF_CustomerCCPayments_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                     DATETIME2 (7) CONSTRAINT [DF_CustomerCCPayments_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                        BIT           CONSTRAINT [CustomerCCPayments_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                       BIT           CONSTRAINT [CustomerCCPayments_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CustomerCCPayments] PRIMARY KEY CLUSTERED ([CustomerCCPaymentsId] ASC)
);




GO
/*************************************************************           
 ** File:   [Trg_CustomerCCPaymentsAudit]           
 ** Date:  09/01/2023
 ** PARAMETERS:           
 ** Description :  Trigger to add the data in [CustomerCCPaymentsAudit]
 ** CreatedBy : Devendra Shekh
 

**************************************************************/

Create   TRIGGER [dbo].[Trg_CustomerCCPaymentsAudit]
   ON  [dbo].[CustomerCCPayments]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	INSERT INTO [CustomerCCPaymentsAudit]
	SELECT * FROM INSERTED
	   
	SET NOCOUNT ON;
	   
END