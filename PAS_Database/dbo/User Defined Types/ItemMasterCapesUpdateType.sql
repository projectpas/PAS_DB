CREATE TYPE [dbo].[ItemMasterCapesUpdateType] AS TABLE (
    [ItemMasterCapesId]     BIGINT         NULL,
    [ItemMasterId]          BIGINT         NULL,
    [CapabilityTypeId]      INT            NULL,
    [ManagementStructureId] BIGINT         NULL,
    [IsVerified]            BIT            NULL,
    [MasterCompanyId]       INT            NULL,
    [VerifiedById]          BIGINT         NULL,
    [VerifiedDate]          DATETIME2 (7)  NULL,
    [AddedDate]             DATETIME2 (7)  NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    [UpdatedBy]             VARCHAR (256)  NULL,
    [UpdatedDate]           DATETIME2 (7)  NULL,
    [IsActive]              BIT            NULL);

