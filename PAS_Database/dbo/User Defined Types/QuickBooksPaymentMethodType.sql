CREATE TYPE [dbo].[QuickBooksPaymentMethodType] AS TABLE (
    [Id]              VARCHAR (MAX) NULL,
    [SyncToken]       VARCHAR (MAX) NULL,
    [LastUpdatedTime] DATETIME2 (7) NULL,
    [Name]            VARCHAR (MAX) NULL,
    [Active]          BIT           NULL,
    [Type]            VARCHAR (MAX) NULL);

