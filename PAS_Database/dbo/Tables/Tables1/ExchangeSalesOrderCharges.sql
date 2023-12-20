CREATE TABLE [dbo].[ExchangeSalesOrderCharges] (
    [ExchangeSalesOrderChargesId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderId]        BIGINT          NOT NULL,
    [ExchangeSalesOrderPartId]    BIGINT          NULL,
    [ChargesTypeId]               BIGINT          NOT NULL,
    [VendorId]                    BIGINT          NULL,
    [Quantity]                    INT             NOT NULL,
    [MarkupPercentageId]          BIGINT          NULL,
    [Description]                 VARCHAR (256)   NULL,
    [UnitCost]                    DECIMAL (20, 2) NOT NULL,
    [ExtendedCost]                DECIMAL (20, 2) NOT NULL,
    [MasterCompanyId]             INT             NOT NULL,
    [MarkupFixedPrice]            DECIMAL (20, 2) NULL,
    [BillingMethodId]             INT             NULL,
    [BillingAmount]               DECIMAL (20, 2) NULL,
    [BillingRate]                 DECIMAL (20, 2) NULL,
    [HeaderMarkupId]              BIGINT          NULL,
    [RefNum]                      VARCHAR (20)    NULL,
    [CreatedBy]                   VARCHAR (256)   NOT NULL,
    [UpdatedBy]                   VARCHAR (256)   NOT NULL,
    [CreatedDate]                 DATETIME2 (7)   CONSTRAINT [DF_ExchangeSalesOrderCharges_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)   CONSTRAINT [DF_ExchangeSalesOrderCharges_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT             CONSTRAINT [DF_ExchangeSalesOrderCharges_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT             CONSTRAINT [DF_ExchangeSalesOrderCharges_IsDeleted] DEFAULT ((0)) NOT NULL,
    [HeaderMarkupPercentageId]    BIGINT          NULL,
    [VendorName]                  NVARCHAR (100)  NULL,
    [ChargeName]                  NVARCHAR (100)  NULL,
    [MarkupName]                  NVARCHAR (100)  NULL,
    [IsInsert]                    BIT             CONSTRAINT [DF__ExchangeS__IsIns__440BE8B8] DEFAULT ((0)) NOT NULL,
    [UomId]                       BIGINT          NULL,
    [UomName]                     NVARCHAR (200)  NULL,
    CONSTRAINT [PK_ExchangeSalesOrderCharges] PRIMARY KEY CLUSTERED ([ExchangeSalesOrderChargesId] ASC),
    CONSTRAINT [FK_EExchangeSalesOrderCharges_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO
CREATE TRIGGER [dbo].[Trg_ExchangeSalesOrderChargesAudit]

   ON  dbo.ExchangeSalesOrderCharges

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO ExchangeSalesOrderChargesAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END