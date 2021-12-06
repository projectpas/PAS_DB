CREATE TABLE [dbo].[GLAccountNodeAudit] (
    [GLAccountNodeAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [GLAccountNodeId]      BIGINT         NOT NULL,
    [LedgerName]           VARCHAR (30)   NOT NULL,
    [NodeCode]             VARCHAR (100)  NOT NULL,
    [NodeName]             VARCHAR (100)  NOT NULL,
    [Description]          VARCHAR (2000) NULL,
    [ParentNodeId]         BIGINT         NULL,
    [LeafNodeCheck]        BIT            NOT NULL,
    [GLAccountNodeType]    VARCHAR (50)   NOT NULL,
    [FSType]               VARCHAR (30)   NOT NULL,
    [LedgerNameId]         BIGINT         NOT NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [CreatedDate]          DATETIME2 (7)  NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  NOT NULL,
    [IsActive]             BIT            NOT NULL,
    [IsDeleted]            BIT            NOT NULL,
    [NodeTypeId]           BIGINT         NULL,
    CONSTRAINT [PK_GLAccountNodeaUDIT] PRIMARY KEY CLUSTERED ([GLAccountNodeAuditId] ASC)
);

