CREATE TABLE [dbo].[ExchangeSalesOrderScheduleBilling] (
    [ExchangeSalesOrderScheduleBillingId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderPartId]            BIGINT          NOT NULL,
    [ExchangeSalesOrderId]                BIGINT          NOT NULL,
    [ScheduleBillingDate]                 DATETIME2 (7)   NULL,
    [PeriodicBillingAmount]               DECIMAL (18, 6) NULL,
    [Cogs]                                INT             NOT NULL,
    [CogsAmount]                          DECIMAL (18, 6) NULL,
    [Qty]                                 DECIMAL (18, 6) CONSTRAINT [DF__ExchangeSal__Qty__6C19DA12] DEFAULT ((1)) NULL,
    [BillingTypeId]                       INT             DEFAULT ((1)) NOT NULL,
    [UnitOfMeasureId]                     BIGINT          NULL,
    [Notes]                               NVARCHAR (MAX)  NULL,
    [Memo]                                NVARCHAR (MAX)  NULL,
    [Type]                                NVARCHAR (50)   DEFAULT ('Part') NOT NULL,
    [StatusId]                            INT             DEFAULT ((1)) NOT NULL,
    [ExchangeSalesOrderChargesId]         BIGINT          NULL,
    [ExchangeSalesOrderFreightId]         BIGINT          NULL,
    [IsPartEntry]                         BIT             DEFAULT ((0)) NOT NULL,
    [BillingAmount]                       DECIMAL (18, 6) NULL,
    [MarkupPercentageId]                  INT             NULL,
    [ExtendedCost]                        DECIMAL (18, 6) NULL,
    CONSTRAINT [PK_ExchangeSalesOrderScheduleBilling] PRIMARY KEY CLUSTERED ([ExchangeSalesOrderScheduleBillingId] ASC)
);




GO




CREATE TRIGGER [dbo].[Trg_ExchangeSalesOrderScheduleBillingAudit]

   ON  [dbo].[ExchangeSalesOrderScheduleBilling]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ExchangeSalesOrderScheduleBillingAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END