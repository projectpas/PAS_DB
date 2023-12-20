CREATE TABLE [dbo].[WorkOrderQuoteFreight] (
    [WorkOrderQuoteFreightId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderQuoteDetailsId] BIGINT          NOT NULL,
    [ShipViaId]               BIGINT          NOT NULL,
    [Weight]                  VARCHAR (50)    NULL,
    [Memo]                    NVARCHAR (MAX)  NULL,
    [Amount]                  DECIMAL (20, 3) CONSTRAINT [DF_WorkOrderQuoteFreight_Amount] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [DF_WorkOrderQuoteFreight_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [DF_WorkOrderQuoteFreight_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT             DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT             DEFAULT ((0)) NOT NULL,
    [MarkupPercentageId]      BIGINT          NULL,
    [MarkupFixedPrice]        VARCHAR (15)    NULL,
    [TaskId]                  BIGINT          NOT NULL,
    [HeaderMarkupId]          BIGINT          NULL,
    [BillingRate]             DECIMAL (20, 2) NULL,
    [BillingAmount]           DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderQuoteFreight_BillingAmount] DEFAULT ((0)) NULL,
    [Length]                  DECIMAL (10, 2) CONSTRAINT [DF_WorkOrderQuoteFreight_Length] DEFAULT ((0)) NULL,
    [Width]                   DECIMAL (10, 2) CONSTRAINT [DF_WorkOrderQuoteFreight_Width] DEFAULT ((0)) NULL,
    [Height]                  DECIMAL (10, 2) CONSTRAINT [DF_WorkOrderQuoteFreight_Height] DEFAULT ((0)) NULL,
    [UOMId]                   BIGINT          NULL,
    [DimensionUOMId]          BIGINT          NULL,
    [CurrencyId]              INT             NULL,
    [BillingMethodId]         INT             NULL,
    [TaskName]                VARCHAR (100)   NULL,
    [Shipvia]                 VARCHAR (50)    NULL,
    [UomName]                 VARCHAR (50)    NULL,
    [DimensionUomName]        VARCHAR (50)    NULL,
    [Currency]                VARCHAR (50)    NULL,
    [BillingName]             VARCHAR (50)    NULL,
    [MarkUp]                  VARCHAR (50)    NULL,
    CONSTRAINT [PK_WorkOrderQuoteFreight] PRIMARY KEY CLUSTERED ([WorkOrderQuoteFreightId] ASC),
    CONSTRAINT [FK_WorkOrderQuoteFreight_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_WorkOrderQuoteFreight_DimensionUOM] FOREIGN KEY ([DimensionUOMId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [FK_WorkOrderQuoteFreight_MarkupPercentage] FOREIGN KEY ([MarkupPercentageId]) REFERENCES [dbo].[Percent] ([PercentId]),
    CONSTRAINT [FK_WorkOrderQuoteFreight_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderQuoteFreight_ShipVia] FOREIGN KEY ([ShipViaId]) REFERENCES [dbo].[ShippingVia] ([ShippingViaId]),
    CONSTRAINT [FK_WorkOrderQuoteFreight_Task] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkOrderQuoteFreight_UOM] FOREIGN KEY ([UOMId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [FK_WorkOrderQuoteFreight_WorkOrderQuoteDetails] FOREIGN KEY ([WorkOrderQuoteDetailsId]) REFERENCES [dbo].[WorkOrderQuoteDetails] ([WorkOrderQuoteDetailsId])
);


GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_WorkOrderQuoteFreightAudit]

   ON  [dbo].[WorkOrderQuoteFreight]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[WorkOrderQuoteFreightAudit] 

    SELECT * 

	FROM INSERTED 

	SET NOCOUNT ON;



END