CREATE TABLE [dbo].[UserRoleBusinessEntity] (
    [UserRoleBusinessEntityId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [UserRoleLevelId]          BIGINT        NOT NULL,
    [BusinessEntityId]         INT           NOT NULL,
    [BusinessEntityType]       SMALLINT      NOT NULL,
    [MasterCompanyId]          INT           NULL,
    [CreatedBy]                VARCHAR (256) NULL,
    [UpdatedBy]                VARCHAR (256) NULL,
    [CreatedDate]              DATETIME2 (7) NULL,
    [UpdatedDate]              DATETIME2 (7) NULL,
    [IsActive]                 BIT           NULL,
    CONSTRAINT [PK_UserRoleBusinessEntity] PRIMARY KEY CLUSTERED ([UserRoleBusinessEntityId] ASC)
);

