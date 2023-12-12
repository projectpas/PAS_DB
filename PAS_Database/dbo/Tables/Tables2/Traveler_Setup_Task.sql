CREATE TABLE [dbo].[Traveler_Setup_Task] (
    [Traveler_Setup_TaskId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Traveler_SetupId]      BIGINT         NOT NULL,
    [TaskId]                BIGINT         NOT NULL,
    [TaskName]              VARCHAR (200)  NULL,
    [Notes]                 NVARCHAR (MAX) NULL,
    [Sequence]              BIGINT         NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  CONSTRAINT [DF_Traveler_Setup_Task_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  CONSTRAINT [DF_Traveler_Setup_Task_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT            CONSTRAINT [DF_Traveler_Setup_Task_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsVersionIncrease]     BIT            NULL,
    [TeardownTypeId]        BIGINT         NULL,
    [TeardownTypeName]      VARCHAR (200)  NULL,
    PRIMARY KEY CLUSTERED ([Traveler_Setup_TaskId] ASC)
);

