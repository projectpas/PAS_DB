CREATE TYPE [dbo].[RfqPartDetailType] AS TABLE (
    [PartNumber]          VARCHAR (250)   NULL,
    [PartDescription]     VARCHAR (500)   NULL,
    [AlternatePart]       VARCHAR (100)   NULL,
    [Quantity]            INT             NULL,
    [Condition]           VARCHAR (50)    NULL,
    [Price]               DECIMAL (18, 2) NULL,
    [Currency]            VARCHAR (20)    NULL,
    [IsMRO]               BIT             NULL,
    [Notes]               VARCHAR (MAX)   NULL,
    [IntegrationPortalId] INT             NULL,
    [Type]                VARCHAR (50)    NULL,
    [IntegrationEmailID]  BIGINT          NULL);

