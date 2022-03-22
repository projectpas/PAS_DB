CREATE TABLE [dbo].[WorkOrderShipping] (
    [WorkOrderShippingId]                BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]                        BIGINT          NOT NULL,
    [WorkOrderPartNoId]                  BIGINT          NULL,
    [WorkflowWorkOrderId]                BIGINT          NOT NULL,
    [WOShippingNum]                      VARCHAR (50)    NULL,
    [WOShippingStatusId]                 BIGINT          NOT NULL,
    [OpenDate]                           DATETIME2 (7)   NOT NULL,
    [CustomerId]                         BIGINT          NOT NULL,
    [ShipViaId]                          BIGINT          NOT NULL,
    [ShipDate]                           DATETIME2 (7)   NOT NULL,
    [AirwayBill]                         VARCHAR (50)    NOT NULL,
    [HouseAirwayBill]                    VARCHAR (50)    NULL,
    [TrackingNum]                        VARCHAR (50)    NULL,
    [Weight]                             DECIMAL (10, 2) NOT NULL,
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
    [CreatedDate]                        DATETIME2 (7)   CONSTRAINT [DF_WorkOrderShipping_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                        DATETIME2 (7)   CONSTRAINT [DF_WorkOrderShipping_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                           BIT             CONSTRAINT [DF_WOS_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                          BIT             CONSTRAINT [DF_WOS_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Shipment]                           VARCHAR (100)   NULL,
    [SoldToSiteId]                       BIGINT          NOT NULL,
    [SoldToSiteName]                     VARCHAR (256)   DEFAULT ('') NOT NULL,
    [SoldToCountryName]                  VARCHAR (256)   DEFAULT ('') NOT NULL,
    [ShipToCustomerId]                   BIGINT          NOT NULL,
    [ShipToCountryName]                  VARCHAR (256)   DEFAULT ('') NOT NULL,
    [OriginCountryName]                  VARCHAR (256)   DEFAULT ('') NOT NULL,
    [OriginSiteId]                       BIGINT          DEFAULT ((0)) NOT NULL,
    [IsSameForShipTo]                    BIT             NULL,
    [ShipSizeLength]                     DECIMAL (10, 2) CONSTRAINT [DF_WorkOrderShipping_ShipSizeLength] DEFAULT ((0)) NULL,
    [ShipSizeWidth]                      DECIMAL (10, 2) CONSTRAINT [DF_WorkOrderShipping_ShipSizeWidth] DEFAULT ((0)) NULL,
    [ShipSizeHeight]                     DECIMAL (10, 2) CONSTRAINT [DF_WorkOrderShipping_ShipSizeHeight] DEFAULT ((0)) NULL,
    [ShipWeightUnit]                     BIGINT          NULL,
    [ShipSizeUnitOfMeasureId]            BIGINT          NULL,
    [PickTicketId]                       BIGINT          NULL,
    [NoOfContainer]                      INT             NULL,
    [shipAttention]                      VARCHAR (100)   NULL,
    [soldAttention]                      VARCHAR (100)   NULL,
    [CustomerDomensticShippingShipViaId] BIGINT          NULL,
    [ShippingAccountInfo]                VARCHAR (200)   NULL,
    [NoOfItems]                          INT             NULL,
    CONSTRAINT [PK_WorkOrderShipping] PRIMARY KEY CLUSTERED ([WorkOrderShippingId] ASC),
    CONSTRAINT [FK_WorkOrderShipping_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_WorkOrderShipping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderShipping_OriginCountry] FOREIGN KEY ([OriginCountryId]) REFERENCES [dbo].[Countries] ([countries_id]),
    CONSTRAINT [FK_WorkOrderShipping_OriginSite] FOREIGN KEY ([OriginSiteId]) REFERENCES [dbo].[Site] ([SiteId]),
    CONSTRAINT [FK_WorkOrderShipping_PickTicketId] FOREIGN KEY ([PickTicketId]) REFERENCES [dbo].[WOPickTicket] ([PickTicketId]),
    CONSTRAINT [FK_WorkOrderShipping_ShippingStatus] FOREIGN KEY ([WOShippingStatusId]) REFERENCES [dbo].[ShippingStatus] ([ShippingStatusId]),
    CONSTRAINT [FK_WorkOrderShipping_ShippingVia] FOREIGN KEY ([ShipViaId]) REFERENCES [dbo].[ShippingVia] ([ShippingViaId]),
    CONSTRAINT [FK_WorkOrderShipping_ShipToCountry] FOREIGN KEY ([ShipToCountryId]) REFERENCES [dbo].[Countries] ([countries_id]),
    CONSTRAINT [FK_WorkOrderShipping_ShipToCustomer] FOREIGN KEY ([ShipToCustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_WorkOrderShipping_SoldToCountry] FOREIGN KEY ([SoldToCountryId]) REFERENCES [dbo].[Countries] ([countries_id]),
    CONSTRAINT [FK_WorkOrderShipping_SoldToSite] FOREIGN KEY ([SoldToSiteId]) REFERENCES [dbo].[CustomerBillingAddress] ([CustomerBillingAddressId]),
    CONSTRAINT [FK_WorkOrderShipping_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId]),
    CONSTRAINT [FK_WorkOrderShipping_WorkOrderPartNo] FOREIGN KEY ([WorkOrderPartNoId]) REFERENCES [dbo].[WorkOrderPartNumber] ([ID])
);


GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_WorkOrderShippingAudit]

   ON  [dbo].[WorkOrderShipping]

   AFTER INSERT,UPDATE

AS 

BEGIN



	   

	INSERT INTO [dbo].[WorkOrderShippingAudit] 

    SELECT *  

	FROM INSERTED 

	SET NOCOUNT ON;



END