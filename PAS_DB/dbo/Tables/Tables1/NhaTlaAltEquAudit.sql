CREATE TABLE [dbo].[NhaTlaAltEquAudit] (
    [NhaTlaAltEquAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
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
    CONSTRAINT [PK_NhaTlaAltEquAudit] PRIMARY KEY CLUSTERED ([NhaTlaAltEquAuditId] ASC)
);

