CREATE TYPE [dbo].[GeneralLedgerSearchParamsType] AS TABLE (
    [UrlName]                     VARCHAR (500) NULL,
    [FromEffectiveDate]           DATETIME2 (7) NULL,
    [ToEffectiveDate]             DATETIME2 (7) NULL,
    [FromJournalId]               VARCHAR (500) NULL,
    [ToJournalId]                 VARCHAR (500) NULL,
    [FromGLAccount]               VARCHAR (500) NULL,
    [ToGLAccount]                 VARCHAR (500) NULL,
    [EmployeeId]                  BIGINT        NULL,
    [Level1]                      VARCHAR (500) NULL,
    [Level2]                      VARCHAR (500) NULL,
    [Level3]                      VARCHAR (500) NULL,
    [Level4]                      VARCHAR (500) NULL,
    [Level5]                      VARCHAR (500) NULL,
    [Level6]                      VARCHAR (500) NULL,
    [Level7]                      VARCHAR (500) NULL,
    [Level8]                      VARCHAR (500) NULL,
    [Level9]                      VARCHAR (500) NULL,
    [Level10]                     VARCHAR (500) NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (50)  NOT NULL,
    [GeneralLedgerSearchParamsId] BIGINT        NULL);



