CREATE TYPE [dbo].[PublicationItemMasterMappingType] AS TABLE (
    [PublicationRecordId] BIGINT NOT NULL,
    [ItemMasterId]        BIGINT NOT NULL,
    [MasterCompanyId]     INT    NOT NULL,
    [IsActive]            BIT    NOT NULL,
    [IsDeleted]           BIT    NOT NULL);

