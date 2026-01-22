CREATE TABLE [dbo].[MasterPartsAudit] (
    [MasterPartAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [MasterPartId]      BIGINT         NOT NULL,
    [PartNumber]        VARCHAR (100)  NULL,
    [Description]       NVARCHAR (MAX) NULL,
    [MasterCompanyId]   INT            NULL,
    [CreatedDate]       DATETIME2 (7)  CONSTRAINT [DF_MasterPartsAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [CreatedBy]         VARCHAR (256)  NULL,
    [UpdatedDate]       DATETIME2 (7)  CONSTRAINT [DF_MasterPartsAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NULL,
    [IsActive]          BIT            CONSTRAINT [DF_MasterPartsAudit_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]         BIT            CONSTRAINT [DF_MasterPartsAudit_IsDeleted] DEFAULT ((0)) NULL,
    [ManufacturerId]    BIGINT         NULL,
    [PartType]          VARCHAR (50)   NULL,
    CONSTRAINT [PK_MasterPartsAudit] PRIMARY KEY CLUSTERED ([MasterPartAuditId] ASC)
);

