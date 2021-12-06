CREATE TABLE [dbo].[ShiftAudit] (
    [ShiftAuditId]    BIGINT        IDENTITY (1, 1) NOT NULL,
    [ShiftId]         BIGINT        NOT NULL,
    [Description]     VARCHAR (100) NOT NULL,
    [MasterCompanyId] INT           NULL,
    [CreatedBy]       VARCHAR (256) NULL,
    [UpdatedBy]       VARCHAR (256) NULL,
    [CreatedDate]     DATETIME2 (7) NULL,
    [UpdatedDate]     DATETIME2 (7) NULL,
    [IsActive]        BIT           NULL,
    [IsDeleted]       BIT           NULL,
    CONSTRAINT [PK_ShiftAudit] PRIMARY KEY CLUSTERED ([ShiftAuditId] ASC)
);

