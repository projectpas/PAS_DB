CREATE TABLE [dbo].[Stkline_History] (
    [StklineHistoryId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [StocklineId]          BIGINT          NULL,
    [ModuleId]             BIGINT          NULL,
    [RefferenceId]         BIGINT          NULL,
    [RefferenceNumber]     VARCHAR (100)   NULL,
    [SubModuleId]          BIGINT          NULL,
    [SubRefferenceId]      BIGINT          NULL,
    [SubRefferenceNumber]  VARCHAR (100)   NULL,
    [ActionId]             INT             NULL,
    [Type]                 VARCHAR (50)    NULL,
    [QtyOH]                DECIMAL (18, 6) NULL,
    [QtyAvailable]         DECIMAL (18, 6) NULL,
    [QtyReserved]          DECIMAL (18, 6) NULL,
    [QtyIssued]            DECIMAL (18, 6) NULL,
    [QtyOnAction]          DECIMAL (18, 6) NULL,
    [Notes]                NVARCHAR (MAX)  NULL,
    [UpdatedBy]            VARCHAR (100)   NULL,
    [UpdatedDate]          DATETIME2 (7)   NULL,
    [UnitSalesPrice]       DECIMAL (18, 2) NULL,
    [SalesPriceExpiryDate] DATETIME2 (7)   NULL,
    CONSTRAINT [PK_Stkline_History] PRIMARY KEY CLUSTERED ([StklineHistoryId] ASC)
);

