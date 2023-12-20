CREATE TABLE [dbo].[ReceivingReconciliationHeader] (
    [ReceivingReconciliationId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [ReceivingReconciliationNumber] VARCHAR (50)    NOT NULL,
    [InvoiceNum]                    VARCHAR (50)    NULL,
    [StatusId]                      INT             NOT NULL,
    [Status]                        VARCHAR (50)    NULL,
    [VendorId]                      BIGINT          NOT NULL,
    [VendorName]                    VARCHAR (100)   NULL,
    [CurrencyId]                    INT             NULL,
    [CurrencyName]                  VARCHAR (50)    NULL,
    [OpenDate]                      DATETIME        NULL,
    [OriginalTotal]                 DECIMAL (18, 2) NULL,
    [RRTotal]                       DECIMAL (18, 2) NULL,
    [InvoiceTotal]                  DECIMAL (18, 2) NULL,
    [DIfferenceAmount]              DECIMAL (18, 2) NULL,
    [TotalAdjustAmount]             DECIMAL (18, 2) NULL,
    [MasterCompanyId]               INT             NULL,
    [CreatedBy]                     VARCHAR (256)   NOT NULL,
    [UpdatedBy]                     VARCHAR (256)   NOT NULL,
    [CreatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_ReceivingReconciliationHeader_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)   CONSTRAINT [DF_ReceivingReconciliationHeader_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                      BIT             CONSTRAINT [DF_ReceivingReconciliationHeader_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT             CONSTRAINT [DF_ReceivingReconciliationHeader_IsDeleted] DEFAULT ((0)) NOT NULL,
    [InvoiceDate]                   DATETIME2 (7)   NULL,
    [AccountingCalendarId]          BIGINT          NULL,
    [IsInvoiceOnHold]               BIT             NULL,
    CONSTRAINT [PK_ReceivingReconciliationHeader] PRIMARY KEY CLUSTERED ([ReceivingReconciliationId] ASC)
);


GO
CREATE TRIGGER [dbo].[Trg_ReceivingReconciliationHeaderAudit]
   ON  [dbo].[ReceivingReconciliationHeader]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO ReceivingReconciliationHeaderAudit
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END