CREATE TABLE [dbo].[RMAReasonAudit] (
    [RMAReasonAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [RMAReasonId]      BIGINT         NOT NULL,
    [Reason]           VARCHAR (1000) NOT NULL,
    [Memo]             NVARCHAR (MAX) NULL,
    [MasterCompanyId]  INT            NOT NULL,
    [CreatedBy]        VARCHAR (256)  NOT NULL,
    [UpdatedBy]        VARCHAR (256)  NOT NULL,
    [CreatedDate]      DATETIME2 (7)  NOT NULL,
    [UpdatedDate]      DATETIME2 (7)  NOT NULL,
    [IsActive]         BIT            NOT NULL,
    [IsDeleted]        BIT            NOT NULL,
    CONSTRAINT [PK_RMAReasonAudit] PRIMARY KEY CLUSTERED ([RMAReasonAuditId] ASC)
);

