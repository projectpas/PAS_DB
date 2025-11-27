CREATE TYPE [dbo].[Nha_Tla_Alt_Equ_ItemMappingType] AS TABLE (
    [ItemMappingId]       BIGINT         NULL,
    [ItemMasterId]        BIGINT         NULL,
    [MappingItemMasterId] BIGINT         NULL,
    [Memo]                NVARCHAR (MAX) NULL,
    [MappingType]         INT            NULL,
    [MasterCompanyId]     INT            NULL,
    [CreatedDate]         DATETIME2 (7)  NULL,
    [CreatedBy]           VARCHAR (256)  NULL,
    [UpdatedDate]         DATETIME2 (7)  NULL,
    [UpdatedBy]           VARCHAR (256)  NULL,
    [IsActive]            BIT            NULL,
    [IsDeleted]           BIT            NULL,
    [CustomerID]          BIGINT         NULL);

