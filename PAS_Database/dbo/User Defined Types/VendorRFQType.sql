CREATE TYPE [dbo].[VendorRFQType] AS TABLE (
    [VendorRFQNumber]    VARCHAR (200) NULL,
    [VendorName]         VARCHAR (200) NULL,
    [Email]              VARCHAR (255) NULL,
    [Phone]              VARCHAR (50)  NULL,
    [Address1]           VARCHAR (500) NULL,
    [Address2]           VARCHAR (500) NULL,
    [City]               VARCHAR (100) NULL,
    [StateProvince]      VARCHAR (100) NULL,
    [PostalCode]         VARCHAR (50)  NULL,
    [Country]            VARCHAR (100) NULL,
    [IntegrationEmailID] BIGINT        NULL);

