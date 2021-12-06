CREATE TABLE [dbo].[DashboardSettings] (
    [Id]               BIGINT       IDENTITY (1, 1) NOT NULL,
    [BacklogStartDate] DATETIME     NULL,
    [BacklogMROStage]  BIGINT       NULL,
    [CreatedDate]      DATETIME     NULL,
    [CreatedBy]        VARCHAR (50) NULL,
    [UpdatedDate]      DATETIME     NULL,
    [UpdatedBy]        VARCHAR (50) NULL,
    [IsActive]         BIT          NULL,
    [IsDeleted]        BIT          NULL,
    [MasterCompanyId]  INT          NULL
);

