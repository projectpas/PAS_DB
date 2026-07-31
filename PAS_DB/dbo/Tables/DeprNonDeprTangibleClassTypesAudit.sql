CREATE TABLE [dbo].[DeprNonDeprTangibleClassTypesAudit] (
    [AuditDeprNonDeprTangibleClassTypeId]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [DeprNonDeprTangibleClassTypeId]          BIGINT        NOT NULL,
    [DeprNonDeprTangibleClassTypeName]        VARCHAR (100) NOT NULL,
    [DeprNonDeprTangibleClassTypeDescription] VARCHAR (500) NOT NULL,
    [MasterCompanyId]                         INT           NOT NULL,
    [CreatedBy]                               VARCHAR (256) NOT NULL,
    [UpdatedBy]                               VARCHAR (256) NOT NULL,
    [CreatedDate]                             DATETIME2 (7) CONSTRAINT [DF_DeprNonDeprTangibleClassTypeAudit_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                             DATETIME2 (7) CONSTRAINT [DF_DeprNonDeprTangibleClassTypeAudit_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                                BIT           NOT NULL,
    [IsDeleted]                               BIT           CONSTRAINT [DF_DeprNonDeprTangibleClassTypeAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_DeprNonDeprTangibleClassTypeAudit] PRIMARY KEY CLUSTERED ([AuditDeprNonDeprTangibleClassTypeId] ASC)
);

