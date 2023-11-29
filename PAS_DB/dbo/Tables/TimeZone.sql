CREATE TABLE [dbo].[TimeZone] (
    [TimeZoneId]       BIGINT        IDENTITY (1, 1) NOT NULL,
    [TimeZoneName]     VARCHAR (100) NOT NULL,
    [Description]      VARCHAR (400) NULL,
    [MasterCompanyId]  INT           NOT NULL,
    [CreatedBy]        VARCHAR (50)  NOT NULL,
    [CreatedDate]      DATETIME2 (7) CONSTRAINT [DF_TimeZone_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]        VARCHAR (50)  NOT NULL,
    [UpdatedDate]      DATETIME2 (7) CONSTRAINT [DF_TimeZone_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]         BIT           CONSTRAINT [DF_TimeZone_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]        BIT           CONSTRAINT [DF_TimeZone_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Abbreviation]     VARCHAR (100) NULL,
    [BaseUtcOffsetSec] BIGINT        NULL,
    CONSTRAINT [PK_TimeZone] PRIMARY KEY CLUSTERED ([TimeZoneId] ASC)
);

