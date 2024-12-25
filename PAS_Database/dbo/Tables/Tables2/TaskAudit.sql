CREATE TABLE [dbo].[TaskAudit] (
    [TaskAuditId]     BIGINT         IDENTITY (1, 1) NOT NULL,
    [TaskId]          BIGINT         NULL,
    [Description]     VARCHAR (200)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NULL,
    [CreatedBy]       VARCHAR (256)  NULL,
    [UpdatedBy]       VARCHAR (256)  NULL,
    [CreatedDate]     DATETIME2 (7)  NULL,
    [UpdatedDate]     DATETIME2 (7)  NULL,
    [IsActive]        BIT            NULL,
    [IsDeleted]       BIT            NULL,
    [Sequence]        BIGINT         NULL,
    [IsTravelerTask]  BIT            NULL,
    [Descrepancy]     NVARCHAR (MAX) NULL,
    [Resolution]      NVARCHAR (MAX) NULL,
    [StandardHours]   INT            NULL,
    [StandardMinute]  INT            NULL,
    CONSTRAINT [PK__TaskAudi__5C947BB6D445DC6F] PRIMARY KEY CLUSTERED ([TaskAuditId] ASC)
);





