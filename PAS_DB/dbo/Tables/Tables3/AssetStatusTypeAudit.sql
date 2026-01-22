CREATE TABLE [dbo].[AssetStatusTypeAudit] (
    [AssetStatusTypeAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AssetStatusTypeId]      BIGINT         NOT NULL,
    [AssetStatusId]          VARCHAR (30)   NOT NULL,
    [AssetStatusName]        VARCHAR (50)   NOT NULL,
    [AssetStatusMemo]        NVARCHAR (MAX) NULL,
    [MasterCompanyId]        INT            NOT NULL,
    [CreatedBy]              VARCHAR (256)  NOT NULL,
    [UpdatedBy]              VARCHAR (256)  NOT NULL,
    [CreatedDate]            DATETIME2 (7)  NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  NOT NULL,
    [IsActive]               BIT            NOT NULL,
    [IsDeleted]              BIT            NOT NULL,
    CONSTRAINT [PK_AssetStatusTypeAudit] PRIMARY KEY CLUSTERED ([AssetStatusTypeAuditId] ASC)
);

