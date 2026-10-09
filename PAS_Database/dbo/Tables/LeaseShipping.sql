CREATE TABLE [dbo].[LeaseShipping] (
    [LeaseShippingId]                    BIGINT          IDENTITY (1, 1) NOT NULL,
    [LeaseHeaderId]                      BIGINT          NOT NULL,
    [LeaseShippingNum]                   VARCHAR (50)    NULL,
    [LeaseShippingStatusId]              BIGINT          NOT NULL,
    [OpenDate]                           DATETIME2 (7)   NOT NULL,
    [CustomerId]                         BIGINT          NOT NULL,
    [ShipViaId]                          BIGINT          NOT NULL,
    [ShipDate]                           DATETIME2 (7)   NOT NULL,
    [AirwayBill]                         VARCHAR (50)    NULL,
    [HouseAirwayBill]                    VARCHAR (50)    NULL,
    [TrackingNum]                        VARCHAR (50)    NULL,
    [Weight]                             DECIMAL (18, 6) NULL,
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
    [MasterCompanyId]                    INT             NOT NULL,
    [CreatedBy]                          VARCHAR (256)   NOT NULL,
    [UpdatedBy]                          VARCHAR (256)   NOT NULL,
    [CreatedDate]                        DATETIME2 (7)   CONSTRAINT [DF_LeaseShipping_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                        DATETIME2 (7)   CONSTRAINT [DF_LeaseShipping_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                           BIT             CONSTRAINT [DF_LeaseShipping_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                          BIT             CONSTRAINT [DF_LeaseShipping_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Shipment]                           VARCHAR (100)   NULL,
    [SoldToSiteId]                       BIGINT          NOT NULL,
    [SoldToSiteName]                     VARCHAR (256)   CONSTRAINT [DF_LeaseShipping_SoldToSiteName] DEFAULT ('') NOT NULL,
    [SoldToCountryName]                  VARCHAR (256)   CONSTRAINT [DF_LeaseShipping_SoldToCountryName] DEFAULT ('') NOT NULL,
    [ShipToCustomerId]                   BIGINT          NOT NULL,
    [ShipToCountryName]                  VARCHAR (256)   CONSTRAINT [DF_LeaseShipping_ShipToCountryName] DEFAULT ('') NOT NULL,
    [OriginCountryName]                  VARCHAR (256)   CONSTRAINT [DF_LeaseShipping_OriginCountryName] DEFAULT ('') NOT NULL,
    [OriginSiteId]                       BIGINT          CONSTRAINT [DF_LeaseShipping_OriginSiteId] DEFAULT ((0)) NOT NULL,
    [IsSameForShipTo]                    BIT             NULL,
    [ShipSizeLength]                     DECIMAL (18, 6) CONSTRAINT [DF_LeaseShipping_ShipSizeLength] DEFAULT ((0)) NULL,
    [ShipSizeWidth]                      DECIMAL (18, 6) CONSTRAINT [DF_LeaseShipping_ShipSizeWidth] DEFAULT ((0)) NULL,
    [ShipSizeHeight]                     DECIMAL (18, 6) CONSTRAINT [DF_LeaseShipping_ShipSizeHeight] DEFAULT ((0)) NULL,
    [ShipWeightUnit]                     BIGINT          NULL,
    [ShipSizeUnitOfMeasureId]            BIGINT          NULL,
    [PickTicketId]                       BIGINT          NULL,
    [NoOfContainer]                      INT             NULL,
    [shipAttention]                      VARCHAR (100)   NULL,
    [soldAttention]                      VARCHAR (100)   NULL,
    [CustomerDomensticShippingShipViaId] BIGINT          NULL,
    [ShippingAccountInfo]                VARCHAR (200)   NULL,
    [NoOfItems]                          DECIMAL (18, 6) NULL,
    [IsCustomerShipping]                 BIT             NULL,
    [IsManualShipping]                   BIT             NULL,
    [ManufactureCountryId]               INT             NULL,
    [QtyUOM]                             DECIMAL (18, 6) NULL,
    [UnitPrice]                          DECIMAL (18, 6) NULL,
    [UnitPriceCurrencyId]                INT             NULL,
    [Notes]                              VARCHAR (MAX)   NULL,
    [isIgnoreAWB]                        BIT             NULL,
    [isBypassShipping]                   BIT             NULL,
    CONSTRAINT [PK_LeaseShipping] PRIMARY KEY CLUSTERED ([LeaseShippingId] ASC)
);


GO
CREATE TRIGGER [dbo].[Trg_LeaseShippingAudit]

   ON  [dbo].[LeaseShipping]

   AFTER INSERT,UPDATE

AS 
BEGIN	   

	INSERT INTO [dbo].[LeaseShippingAudit] 

    SELECT * FROM INSERTED 

	SET NOCOUNT ON;

END