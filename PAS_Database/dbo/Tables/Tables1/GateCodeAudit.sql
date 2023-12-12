CREATE TABLE [dbo].[GateCodeAudit] (
    [GateCodeAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [GateCodeId]      BIGINT         NULL,
    [GateCode]        VARCHAR (30)   NULL,
    [Description]     VARCHAR (256)  NULL,
    [Sequence]        VARCHAR (30)   NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NULL,
    [CreatedBy]       VARCHAR (256)  NULL,
    [UpdatedBy]       VARCHAR (256)  NULL,
    [CreatedDate]     DATETIME2 (7)  NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            NULL,
    [IsDelete]        BIT            NULL
);

