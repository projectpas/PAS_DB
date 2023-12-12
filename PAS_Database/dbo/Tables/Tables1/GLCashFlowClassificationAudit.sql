CREATE TABLE [dbo].[GLCashFlowClassificationAudit] (
    [GLClassFlowClassificationAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [GLClassFlowClassificationId]      BIGINT         NOT NULL,
    [GLClassFlowClassificationName]    VARCHAR (100)  NOT NULL,
    [MasterCompanyId]                  INT            NOT NULL,
    [CreatedBy]                        VARCHAR (256)  NOT NULL,
    [UpdatedBy]                        VARCHAR (256)  NOT NULL,
    [CreatedDate]                      DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                      DATETIME2 (7)  NOT NULL,
    [IsActive]                         BIT            NOT NULL,
    [IsDeleted]                        BIT            NOT NULL,
    [Description]                      VARCHAR (100)  NOT NULL,
    [Memo]                             NVARCHAR (MAX) NULL,
    PRIMARY KEY CLUSTERED ([GLClassFlowClassificationAuditId] ASC)
);

