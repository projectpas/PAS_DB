/*************************************************************           
 ** File:   [FleetQuoteFreight.sql]           
 ** Author:   SUMIT KUMAR
 ** Description: This Table is used to store Fleet Quote Freight Charges
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteFreight] (
    [FleetQuoteFreightId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [FleetQuoteDetailsId] BIGINT          NOT NULL,
    [ShipViaId]               BIGINT          NOT NULL,
    [Weight]                  VARCHAR (50)    NULL,
    [Memo]                    NVARCHAR (MAX)  NULL,
    [Amount]                  DECIMAL (20, 3) CONSTRAINT [DF_FleetQuoteFreight_Amount] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [DF_FleetQuoteFreight_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [DF_FleetQuoteFreight_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT             CONSTRAINT [DF_FleetQuoteFreight_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT             CONSTRAINT [DF_FleetQuoteFreight_IsDeleted] DEFAULT ((0)) NOT NULL,
    [MarkupPercentageId]      BIGINT          NULL,
    [MarkupFixedPrice]        VARCHAR (15)    NULL,
    [TaskId]                  BIGINT          NOT NULL,
    [HeaderMarkupId]          BIGINT          NULL,
    [BillingRate]             DECIMAL (20, 2) NULL,
    [BillingAmount]           DECIMAL (20, 2) CONSTRAINT [DF_FleetQuoteFreight_BillingAmount] DEFAULT ((0)) NULL,
    [Length]                  DECIMAL (10, 2) CONSTRAINT [DF_FleetQuoteFreight_Length] DEFAULT ((0)) NULL,
    [Width]                   DECIMAL (10, 2) CONSTRAINT [DF_FleetQuoteFreight_Width] DEFAULT ((0)) NULL,
    [Height]                  DECIMAL (10, 2) CONSTRAINT [DF_FleetQuoteFreight_Height] DEFAULT ((0)) NULL,
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
    CONSTRAINT [PK_FleetQuoteFreight] PRIMARY KEY CLUSTERED ([FleetQuoteFreightId] ASC),
    CONSTRAINT [FK_FleetQuoteFreight_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_FleetQuoteFreight_DimensionUOM] FOREIGN KEY ([DimensionUOMId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [FK_FleetQuoteFreight_MarkupPercentage] FOREIGN KEY ([MarkupPercentageId]) REFERENCES [dbo].[Percent] ([PercentId]),
    CONSTRAINT [FK_FleetQuoteFreight_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_FleetQuoteFreight_ShipVia] FOREIGN KEY ([ShipViaId]) REFERENCES [dbo].[ShippingVia] ([ShippingViaId]),
    CONSTRAINT [FK_FleetQuoteFreight_UOM] FOREIGN KEY ([UOMId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [FK_FleetQuoteFreight_FleetQuoteDetails] FOREIGN KEY ([FleetQuoteDetailsId]) REFERENCES [dbo].[FleetQuoteDetails] ([FleetQuoteDetailsId])
);

GO

/*************************************************************           
 ** File:   [Trg_FleetQuoteFreightAudit]           
 ** Author:   SUMIT KUMAR
 ** Description: This Trigger is used to insert data into FleetQuoteFreightAudit
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TRIGGER [dbo].[Trg_FleetQuoteFreightAudit]
   ON [dbo].[FleetQuoteFreight]
   AFTER INSERT, UPDATE
AS
BEGIN
    INSERT INTO [dbo].[FleetQuoteFreightAudit]
    SELECT * FROM INSERTED;
    SET NOCOUNT ON;
END;
