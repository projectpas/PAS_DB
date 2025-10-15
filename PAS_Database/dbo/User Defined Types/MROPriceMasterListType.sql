CREATE TYPE [dbo].[MROPriceMasterListType] AS TABLE (
    [MROPriceMasterId] BIGINT          NULL,
    [ItemMasterId]     BIGINT          NULL,
    [MasterCompanyId]  INT             NULL,
    [CustomerId]       BIGINT          NULL,
    [WorkscopeId]      BIGINT          NULL,
    [CurrencyId]       INT             NULL,
    [UnitPrice]        DECIMAL (18, 2) NULL,
    [StartDate]        DATETIME2 (7)   NULL,
    [CreatedBy]        VARCHAR (50)    NULL,
    [UpdatedBy]        VARCHAR (50)    NULL);

