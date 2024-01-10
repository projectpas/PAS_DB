CREATE TABLE [dbo].[SalesOrderCharges] (
    [SalesOrderChargesId]      BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuoteId]        BIGINT          NULL,
    [SalesOrderId]             BIGINT          NOT NULL,
    [SalesOrderPartId]         BIGINT          NULL,
    [ChargesTypeId]            BIGINT          NOT NULL,
    [VendorId]                 BIGINT          NULL,
    [Quantity]                 INT             NOT NULL,
    [MarkupPercentageId]       BIGINT          NULL,
    [Description]              VARCHAR (256)   NULL,
    [UnitCost]                 DECIMAL (20, 2) NOT NULL,
    [ExtendedCost]             DECIMAL (20, 2) NOT NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [MarkupFixedPrice]         DECIMAL (20, 2) NULL,
    [BillingMethodId]          INT             NULL,
    [BillingAmount]            DECIMAL (20, 2) NULL,
    [BillingRate]              DECIMAL (20, 2) NULL,
    [HeaderMarkupId]           BIGINT          NULL,
    [RefNum]                   VARCHAR (20)    NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_SalesOrderCharges_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_SalesOrderCharges_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [DF_SalesOrderCharges_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF_SalesOrderCharges_IsDeleted] DEFAULT ((0)) NOT NULL,
    [HeaderMarkupPercentageId] BIGINT          NULL,
    [VendorName]               VARCHAR (100)   NULL,
    [ChargeName]               VARCHAR (50)    NULL,
    [MarkupName]               VARCHAR (50)    NULL,
    [ItemMasterId]             BIGINT          NULL,
    [ConditionId]              BIGINT          NULL,
    [UOMId]                    BIGINT          NULL,
    CONSTRAINT [PK_SalesOrderCharges] PRIMARY KEY CLUSTERED ([SalesOrderChargesId] ASC),
    CONSTRAINT [FK_SalesOrderCharges_Charge] FOREIGN KEY ([ChargesTypeId]) REFERENCES [dbo].[Charge] ([ChargeId]),
    CONSTRAINT [FK_SalesOrderCharges_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderCharges_SalesOrderId] FOREIGN KEY ([SalesOrderId]) REFERENCES [dbo].[SalesOrder] ([SalesOrderId])
);




GO


CREATE TRIGGER [dbo].[Trg_SalesOrderChargesAudit]

   ON  [dbo].[SalesOrderCharges]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SalesOrderChargesAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END