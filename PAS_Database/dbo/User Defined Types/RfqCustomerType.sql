CREATE TYPE [dbo].[RfqCustomerType] AS TABLE (
    [CustomerName]       VARCHAR (200) NULL,
    [BuyerName]          VARCHAR (300) NULL,
    [CompanyName]        VARCHAR (300) NULL,
    [Email]              VARCHAR (255) NULL,
    [Phone]              VARCHAR (50)  NULL,
    [Address]            VARCHAR (500) NULL,
    [City]               VARCHAR (100) NULL,
    [State]              VARCHAR (100) NULL,
    [Zip]                VARCHAR (50)  NULL,
    [Country]            VARCHAR (100) NULL,
    [ExtractionNotes]    VARCHAR (MAX) NULL,
    [IntegrationEmailID] BIGINT        NULL);

