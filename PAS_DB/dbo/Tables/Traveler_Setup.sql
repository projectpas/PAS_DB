CREATE TABLE [dbo].[Traveler_Setup] (
    [Traveler_SetupId]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [TravelerId]        VARCHAR (100) NULL,
    [WorkScopeId]       INT           NOT NULL,
    [WorkScope]         VARCHAR (100) NULL,
    [Version]           VARCHAR (100) NULL,
    [MasterCompanyId]   INT           NOT NULL,
    [CreatedBy]         VARCHAR (256) NOT NULL,
    [UpdatedBy]         VARCHAR (256) NOT NULL,
    [CreatedDate]       DATETIME2 (7) CONSTRAINT [DF_Traveler_Setup_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7) CONSTRAINT [DF_Traveler_Setup_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT           DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT           CONSTRAINT [DF_Traveler_Setup_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ItemMasterId]      BIGINT        NULL,
    [PartNumber ]       VARCHAR (256) NOT NULL,
    [IsVersionIncrease] BIT           NULL,
    [CurrentNummber]    BIGINT        NULL,
    PRIMARY KEY CLUSTERED ([Traveler_SetupId] ASC)
);

