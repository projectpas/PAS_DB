CREATE TABLE [dbo].[CommunicationContactAudit] (
    [ContactAuditId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [ContactId]       BIGINT         NOT NULL,
    [ContactNo]       VARCHAR (20)   NOT NULL,
    [ContactTypeId]   INT            NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [ContactById]     BIGINT         NOT NULL,
    [ContactDate]     DATETIME2 (7)  NOT NULL,
    [ModuleId]        INT            NOT NULL,
    [ReferenceId]     BIGINT         NOT NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    CONSTRAINT [PK_CommunicationContactAudit] PRIMARY KEY CLUSTERED ([ContactAuditId] ASC)
);

