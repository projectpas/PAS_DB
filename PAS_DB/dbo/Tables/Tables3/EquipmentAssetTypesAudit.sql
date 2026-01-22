CREATE TABLE [dbo].[EquipmentAssetTypesAudit] (
    [EquipmentAssetTypesAuditId] INT           IDENTITY (1, 1) NOT NULL,
    [Id]                         INT           NOT NULL,
    [CreatedBy]                  VARCHAR (50)  NOT NULL,
    [CreatedDate]                DATETIME2 (7) NOT NULL,
    [UpdatedBy]                  VARCHAR (50)  NOT NULL,
    [UpdatedDate]                DATETIME2 (7) NOT NULL,
    [IsDeleted]                  BIT           NOT NULL,
    [Name]                       VARCHAR (50)  NOT NULL,
    [IsActive]                   BIT           NOT NULL,
    CONSTRAINT [PK_EquipmentAssetTypesAudit] PRIMARY KEY CLUSTERED ([EquipmentAssetTypesAuditId] ASC)
);

