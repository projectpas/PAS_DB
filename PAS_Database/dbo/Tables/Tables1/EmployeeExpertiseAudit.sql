CREATE TABLE [dbo].[EmployeeExpertiseAudit] (
    [AuditEmployeeExpertiseId] SMALLINT        IDENTITY (1, 1) NOT NULL,
    [EmployeeExpertiseId]      SMALLINT        NOT NULL,
    [Description]              VARCHAR (30)    NOT NULL,
    [Memo]                     NVARCHAR (MAX)  NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   NOT NULL,
    [IsActive]                 BIT             NOT NULL,
    [IsDeleted]                BIT             NOT NULL,
    [IsWorksInShop]            BIT             NOT NULL,
    [EmpExpCode]               VARCHAR (50)    NULL,
    [Avglaborrate]             DECIMAL (18, 2) NULL,
    [Overheadburden]           DECIMAL (18, 2) NULL,
    [OverheadburdenPercentId]  BIGINT          NULL,
    [FlatAmount]               DECIMAL (18, 2) NULL,
    CONSTRAINT [PK_EmployeeExpertiseAudit] PRIMARY KEY CLUSTERED ([AuditEmployeeExpertiseId] ASC)
);

