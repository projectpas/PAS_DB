CREATE TABLE [dbo].[UnitOfMeasureAudit] (
    [UnitOfMeasureAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [UnitOfMeasureId]      BIGINT         NULL,
    [Description]          VARCHAR (100)  NOT NULL,
    [ShortName]            VARCHAR (100)  NOT NULL,
    [Memo]                 NVARCHAR (MAX) NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [IsActive]             BIT            NOT NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [CreatedDate]          DATETIME2 (7)  NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  NOT NULL,
    [IsDeleted]            BIT            NOT NULL,
    [StandardId]           INT            DEFAULT ((0)) NOT NULL,
    [StandardName]         VARCHAR (256)  NULL,
    [SequenceNo]           INT            NULL
);

