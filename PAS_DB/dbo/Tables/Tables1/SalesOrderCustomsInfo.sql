CREATE TABLE [dbo].[SalesOrderCustomsInfo] (
    [SalesOrderCustomsInfoId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderShippingId]    BIGINT          NOT NULL,
    [EntryType]               VARCHAR (100)   NULL,
    [EPU]                     VARCHAR (100)   NULL,
    [CustomsValue]            DECIMAL (20, 2) NULL,
    [NetMass]                 DECIMAL (20, 2) NULL,
    [EntryStatus]             VARCHAR (100)   NULL,
    [EntryNumber]             VARCHAR (100)   NULL,
    [VATValue]                DECIMAL (20, 2) NULL,
    [UCR]                     VARCHAR (100)   NULL,
    [MasterUCR]               VARCHAR (100)   NULL,
    [MovementRefNo]           VARCHAR (100)   NULL,
    [CommodityCode]           VARCHAR (100)   NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [DF_SalesOrderCustomsInfo_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [DF_SalesOrderCustomsInfo_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT             CONSTRAINT [DF_SCI_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT             CONSTRAINT [DF_SCI_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SalesOrderCustomsInfo] PRIMARY KEY CLUSTERED ([SalesOrderCustomsInfoId] ASC),
    CONSTRAINT [FK_SalesOrderCustomsInfo_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderCustomsInfo_SalesOrderShipping] FOREIGN KEY ([SalesOrderShippingId]) REFERENCES [dbo].[SalesOrderShipping] ([SalesOrderShippingId])
);


GO


CREATE TRIGGER [dbo].[Trg_SalesOrderCustomsInfoAudit]

   ON  [dbo].[SalesOrderCustomsInfo]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SalesOrderCustomsInfoAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END