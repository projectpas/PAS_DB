CREATE TABLE [dbo].[Nha_Tla_Alt_Equ_ItemMappingAudit] (
    [ItemMappingAuditId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [ItemMappingId]       BIGINT         NOT NULL,
    [ItemMasterId]        BIGINT         NOT NULL,
    [MappingItemMasterId] BIGINT         NOT NULL,
    [Memo]                NVARCHAR (MAX) NULL,
    [MappingType]         INT            NOT NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedDate]         DATETIME2 (7)  NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [IsActive]            BIT            NOT NULL,
    [IsDeleted]           BIT            NOT NULL,
    [CustomerID]          BIGINT         NULL,
    CONSTRAINT [PK_Nha_Tla_Alt_Equ_ItemMappingAudit] PRIMARY KEY CLUSTERED ([ItemMappingAuditId] ASC)
);

