CREATE TABLE [dbo].[ItemMasterPurchaseSale] (
    [ItemMasterId]                            BIGINT          NOT NULL,
    [PartNumber]                              VARCHAR (50)    NOT NULL,
    [PP_UOMId]                                BIGINT          NOT NULL,
    [PP_CurrencyId]                           INT             NOT NULL,
    [PP_FXRatePerc]                           DECIMAL (18, 2) NOT NULL,
    [PP_VendorListPrice]                      DECIMAL (18, 2) NULL,
    [PP_LastListPriceDate]                    DATETIME2 (7)   NULL,
    [PP_PurchaseDiscPerc]                     INT             NULL,
    [PP_PurchaseDiscAmount]                   DECIMAL (18, 2) NULL,
    [PP_LastPurchaseDiscDate]                 DATETIME2 (7)   NULL,
    [PP_UnitPurchasePrice]                    DECIMAL (18, 2) NULL,
    [SP_FSP_UOMId]                            BIGINT          NULL,
    [SP_FSP_CurrencyId]                       INT             NULL,
    [SP_FSP_FXRatePerc]                       DECIMAL (18, 2) NOT NULL,
    [SP_FSP_FlatPriceAmount]                  DECIMAL (18, 2) NULL,
    [SP_FSP_LastFlatPriceDate]                DATETIME2 (7)   NULL,
    [SP_CalSPByPP_MarkUpPercOnListPrice]      INT             NULL,
    [SP_CalSPByPP_MarkUpAmount]               DECIMAL (18, 2) NULL,
    [SP_CalSPByPP_LastMarkUpDate]             DATETIME2 (7)   NULL,
    [SP_CalSPByPP_BaseSalePrice]              DECIMAL (18, 2) NULL,
    [SP_CalSPByPP_SaleDiscPerc]               INT             NULL,
    [SP_CalSPByPP_SaleDiscAmount]             DECIMAL (18, 2) NULL,
    [SP_CalSPByPP_LastSalesDiscDate]          DATETIME2 (7)   NULL,
    [SP_CalSPByPP_UnitSalePrice]              DECIMAL (18, 2) NULL,
    [MasterCompanyId]                         INT             NOT NULL,
    [CreatedBy]                               VARCHAR (256)   NOT NULL,
    [UpdatedBy]                               VARCHAR (256)   NOT NULL,
    [CreatedDate]                             DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                             DATETIME2 (7)   NOT NULL,
    [IsActive]                                BIT             NOT NULL,
    [IsDeleted]                               BIT             NOT NULL,
    [ItemMasterPurchaseSaleId]                BIGINT          IDENTITY (1, 1) NOT NULL,
    [ConditionId]                             BIGINT          NULL,
    [SalePriceSelectId]                       INT             NULL,
    [ConditionName]                           VARCHAR (200)   NULL,
    [PP_UOMName]                              VARCHAR (200)   NULL,
    [SP_FSP_UOMName]                          VARCHAR (200)   NULL,
    [PP_CurrencyName]                         VARCHAR (200)   NULL,
    [SP_FSP_CurrencyName]                     VARCHAR (200)   NULL,
    [PP_PurchaseDiscPercValue]                DECIMAL (18, 2) NULL,
    [SP_CalSPByPP_SaleDiscPercValue]          DECIMAL (18, 2) NULL,
    [SP_CalSPByPP_MarkUpPercOnListPriceValue] DECIMAL (18, 2) NULL,
    [SalePriceSelectName]                     VARCHAR (200)   NULL,
    PRIMARY KEY CLUSTERED ([ItemMasterPurchaseSaleId] ASC),
    CONSTRAINT [FK_ItemMasterPurchaseSale_Currency] FOREIGN KEY ([PP_CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_ItemMasterPurchaseSale_Currency1] FOREIGN KEY ([SP_FSP_CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_ItemMasterPurchaseSale_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_ItemMasterPurchaseSale_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_ItemMasterPurchaseSale_UnitOfMeasure] FOREIGN KEY ([PP_UOMId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [FK_ItemMasterPurchaseSale_UnitOfMeasure1] FOREIGN KEY ([SP_FSP_UOMId]) REFERENCES [dbo].[UnitOfMeasure] ([UnitOfMeasureId]),
    CONSTRAINT [Unique_ItemMasterPurchaseSale] UNIQUE NONCLUSTERED ([ItemMasterId] ASC, [ConditionId] ASC, [MasterCompanyId] ASC)
);


GO






CREATE TRIGGER [dbo].[Trg_ItemMasterPurchaseSaleAudit]

   ON  [dbo].[ItemMasterPurchaseSale]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[ItemMasterPurchaseSaleAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END