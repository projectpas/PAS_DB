CREATE TYPE [dbo].[LeaseCustomsInfoType] AS TABLE (
    [LeaseShippingId]  BIGINT          NULL,
    [EntryType]        VARCHAR (100)   NULL,
    [EntryNumber]      VARCHAR (100)   NULL,
    [CommodityCode]    VARCHAR (100)   NULL,
    [EPU]              VARCHAR (100)   NULL,
    [UCR]              VARCHAR (100)   NULL,
    [MasterUCR]        VARCHAR (100)   NULL,
    [MovementRefNo]    VARCHAR (100)   NULL,
    [CustomsValue]     DECIMAL (20, 6) NULL,
    [CustomCurrencyId] INT             NULL,
    [NetMass]          DECIMAL (20, 6) NULL,
    [VATValue]         DECIMAL (20, 6) NULL,
    [MasterCompanyId]  INT             NOT NULL,
    [CreatedBy]        VARCHAR (256)   NOT NULL,
    [UpdatedBy]        VARCHAR (256)   NOT NULL);

