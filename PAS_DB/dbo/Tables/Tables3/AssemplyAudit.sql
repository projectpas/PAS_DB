CREATE TABLE [dbo].[AssemplyAudit] (
    [AssemplyAuditId]        BIGINT        IDENTITY (1, 1) NOT NULL,
    [AssemplyId]             BIGINT        NOT NULL,
    [ItemMasterId]           BIGINT        NOT NULL,
    [Quantity]               BIGINT        NOT NULL,
    [WorkscopeId]            BIGINT        NOT NULL,
    [ProvisionId]            BIGINT        NOT NULL,
    [PopulateWoMaterialList] BIT           NOT NULL,
    [Memo]                   VARCHAR (500) NOT NULL,
    [MasterCompanyId]        INT           NOT NULL,
    [CreatedBy]              VARCHAR (50)  NOT NULL,
    [CreatedDate]            DATETIME2 (7) CONSTRAINT [DF_AssemplyAudit_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]              VARCHAR (50)  NOT NULL,
    [UpdatedDate]            DATETIME2 (7) CONSTRAINT [DF_AssemplyAudit_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]               BIT           CONSTRAINT [DF__AssemplyAudit__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT           CONSTRAINT [DF__AssemplyAudit__IsDeleted] DEFAULT ((0)) NOT NULL,
    [MappingItemMasterId]    BIGINT        NULL,
    CONSTRAINT [PK_AssemplyAudit] PRIMARY KEY CLUSTERED ([AssemplyAuditId] ASC)
);

