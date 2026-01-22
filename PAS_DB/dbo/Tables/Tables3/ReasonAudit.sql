CREATE TABLE [dbo].[ReasonAudit] (
    [ReasonAuditId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [ReasonId]         VARCHAR (256)  NOT NULL,
    [ReasonCode]       VARCHAR (30)   NOT NULL,
    [ReasonForRemoval] VARCHAR (256)  NOT NULL,
    [Memo]             NVARCHAR (MAX) NULL,
    [MasterCompanyId]  INT            NOT NULL,
    [CreatedBy]        VARCHAR (256)  NOT NULL,
    [UpdatedBy]        VARCHAR (256)  NOT NULL,
    [CreatedDate]      DATETIME2 (7)  NOT NULL,
    [UpdatedDate]      DATETIME2 (7)  NOT NULL,
    [IsActive]         BIT            NOT NULL,
    [IsDeleted]        BIT            NOT NULL
);

