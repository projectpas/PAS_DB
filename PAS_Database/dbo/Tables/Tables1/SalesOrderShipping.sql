CREATE TABLE [dbo].[SalesOrderShipping] (
    [SalesOrderShippingId]               BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderId]                       BIGINT          NOT NULL,
    [SOShippingNum]                      VARCHAR (50)    NULL,
    [SOShippingStatusId]                 BIGINT          NOT NULL,
    [OpenDate]                           DATETIME2 (7)   NOT NULL,
    [CustomerId]                         BIGINT          NOT NULL,
    [ShipViaId]                          BIGINT          NOT NULL,
    [ShipDate]                           DATETIME2 (7)   NOT NULL,
    [AirwayBill]                         VARCHAR (50)    NULL,
    [HouseAirwayBill]                    VARCHAR (50)    NOT NULL,
    [TrackingNum]                        VARCHAR (50)    NOT NULL,
    [Weight]                             DECIMAL (10, 2) NULL,
    [SoldToName]                         VARCHAR (256)   NOT NULL,
    [SoldToAddress1]                     VARCHAR (256)   NOT NULL,
    [SoldToAddress2]                     VARCHAR (256)   NULL,
    [SoldToCity]                         VARCHAR (256)   NOT NULL,
    [SoldToState]                        VARCHAR (256)   NOT NULL,
    [SoldToZip]                          VARCHAR (20)    NOT NULL,
    [SoldToCountryId]                    SMALLINT        NOT NULL,
    [ShipToName]                         VARCHAR (256)   NOT NULL,
    [ShipToSiteName]                     VARCHAR (256)   NOT NULL,
    [ShipToSiteId]                       BIGINT          NOT NULL,
    [ShipToAddress1]                     VARCHAR (256)   NOT NULL,
    [ShipToAddress2]                     VARCHAR (256)   NOT NULL,
    [ShipToCity]                         VARCHAR (256)   NOT NULL,
    [ShipToState]                        VARCHAR (256)   NOT NULL,
    [ShipToZip]                          VARCHAR (20)    NOT NULL,
    [ShipToCountryId]                    SMALLINT        NOT NULL,
    [OriginName]                         VARCHAR (256)   NOT NULL,
    [OriginAddress1]                     VARCHAR (256)   NOT NULL,
    [OriginAddress2]                     VARCHAR (256)   NULL,
    [OriginCity]                         VARCHAR (256)   NOT NULL,
    [OriginState]                        VARCHAR (256)   NOT NULL,
    [OriginZip]                          VARCHAR (20)    NOT NULL,
    [OriginCountryId]                    SMALLINT        NOT NULL,
    [Shipment]                           VARCHAR (100)   NULL,
    [SoldToSiteId]                       BIGINT          CONSTRAINT [DF_SOS_SoldToSiteId] DEFAULT ((0)) NOT NULL,
    [SoldToSiteName]                     VARCHAR (256)   CONSTRAINT [DF_SOS_SoldToSiteName] DEFAULT ('') NOT NULL,
    [SoldToCountryName]                  VARCHAR (256)   CONSTRAINT [DF_SOS_SoldToCountryName] DEFAULT ('') NOT NULL,
    [ShipToCustomerId]                   BIGINT          CONSTRAINT [DF_SOS_ShipToCustomerId] DEFAULT ((0)) NOT NULL,
    [ShipToCountryName]                  VARCHAR (256)   CONSTRAINT [DF_SOS_ShipToCountryName] DEFAULT ('') NOT NULL,
    [OriginCountryName]                  VARCHAR (256)   CONSTRAINT [DF_SOS_OriginCountryName] DEFAULT ('') NOT NULL,
    [OriginSiteId]                       BIGINT          CONSTRAINT [DF_SOS_OriginSiteId] DEFAULT ((0)) NOT NULL,
    [IsSameForShipTo]                    BIT             NULL,
    [MasterCompanyId]                    INT             NOT NULL,
    [CreatedBy]                          VARCHAR (256)   NOT NULL,
    [UpdatedBy]                          VARCHAR (256)   NOT NULL,
    [CreatedDate]                        DATETIME2 (7)   CONSTRAINT [DF_SalesOrderShipping_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                        DATETIME2 (7)   CONSTRAINT [DF_SalesOrderShipping_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                           BIT             CONSTRAINT [DF_SOS_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                          BIT             CONSTRAINT [DF_SOS_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ShipSizeLength]                     DECIMAL (10, 2) NULL,
    [ShipSizeWidth]                      DECIMAL (10, 2) NULL,
    [ShipSizeHeight]                     DECIMAL (10, 2) NULL,
    [ShipWeightUnit]                     BIGINT          NULL,
    [ShipSizeUnitOfMeasureId]            BIGINT          NULL,
    [ServiceClass]                       VARCHAR (50)    NULL,
    [NoOfContainer]                      INT             NULL,
    [ShippingAccountNo]                  VARCHAR (50)    NULL,
    [SmentNum]                           INT             NULL,
    [CustomerDomensticShippingShipViaId] BIGINT          NULL,
    [NoOfItems]                          INT             NULL,
    [IsCustomerShipping]                 BIT             NULL,
    [IsManualShipping]                   BIT             NULL,
    [ManufactureCountryId]               INT             NULL,
    [QtyUOM]                             BIGINT          NULL,
    [UnitPrice]                          DECIMAL (20, 2) NULL,
    [UnitPriceCurrencyId]                INT             NULL,
    [Notes]                              VARCHAR (MAX)   NULL,
    [SoldToUserType]                     INT             NULL,
    [ShipToUserType]                     INT             NULL,
    [SoldToCustomerId]                   BIGINT          NULL,
    CONSTRAINT [PK_SalesOrderShipping] PRIMARY KEY CLUSTERED ([SalesOrderShippingId] ASC),
    CONSTRAINT [FK_SalesOrderShipping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderShipping_OriginCountry] FOREIGN KEY ([OriginCountryId]) REFERENCES [dbo].[Countries] ([countries_id]),
    CONSTRAINT [FK_SalesOrderShipping_SalesOrder] FOREIGN KEY ([SalesOrderId]) REFERENCES [dbo].[SalesOrder] ([SalesOrderId]),
    CONSTRAINT [FK_SalesOrderShipping_ShippingStatus] FOREIGN KEY ([SOShippingStatusId]) REFERENCES [dbo].[ShippingStatus] ([ShippingStatusId]),
    CONSTRAINT [FK_SalesOrderShipping_ShipToCountry] FOREIGN KEY ([ShipToCountryId]) REFERENCES [dbo].[Countries] ([countries_id]),
    CONSTRAINT [FK_SalesOrderShipping_SoldToCountry] FOREIGN KEY ([SoldToCountryId]) REFERENCES [dbo].[Countries] ([countries_id])
);




GO


CREATE TRIGGER [dbo].[Trg_SalesOrderShippingAudit]

   ON  [dbo].[SalesOrderShipping]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SalesOrderShippingAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END