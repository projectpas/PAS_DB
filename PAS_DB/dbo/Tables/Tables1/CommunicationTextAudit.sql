CREATE TABLE [dbo].[CommunicationTextAudit] (
    [AuditCommunicationTextId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [CommunicationTextId]      BIGINT         NOT NULL,
    [Mobile]                   VARCHAR (20)   NOT NULL,
    [ContactById]              BIGINT         NOT NULL,
    [Notes]                    NVARCHAR (MAX) NULL,
    [ModuleId]                 INT            NOT NULL,
    [ReferenceId]              BIGINT         NOT NULL,
    [MasterCompanyId]          INT            NOT NULL,
    [CreatedBy]                VARCHAR (256)  NOT NULL,
    [UpdatedBy]                VARCHAR (256)  NOT NULL,
    [CreatedDate]              DATETIME2 (7)  NOT NULL,
    [UpdatedDate]              DATETIME2 (7)  NOT NULL,
    [IsActive]                 BIT            NOT NULL,
    [IsDeleted]                BIT            NOT NULL,
    [CustomerContactId]        BIGINT         DEFAULT ((0)) NOT NULL,
    [WorkOrderPartNo]          BIGINT         NULL,
    CONSTRAINT [PK_CommunicationTextAudit] PRIMARY KEY CLUSTERED ([AuditCommunicationTextId] ASC)
);

