CREATE TABLE [dbo].[EquipmentAudit] (
    [EquipmentAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [EquipmentId]      BIGINT        NOT NULL,
    [Description]      VARCHAR (200) NOT NULL,
    [MasterCompanyId]  INT           NOT NULL,
    [CreatedBy]        VARCHAR (256) NULL,
    [UpdatedBy]        VARCHAR (256) NULL,
    [CreatedDate]      DATETIME2 (7) NOT NULL,
    [UpdatedDate]      DATETIME2 (7) NOT NULL,
    [IsActive]         BIT           NOT NULL,
    [IsDeleted]        BIT           NOT NULL,
    CONSTRAINT [PK_EquipmentAudit] PRIMARY KEY CLUSTERED ([EquipmentAuditId] ASC)
);

