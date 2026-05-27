CREATE TABLE [dbo].[AircraftInfo] (
    [AircraftInfoId]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [ACMakeTypeId]    BIGINT        NULL,
    [ACMakeTypeName]  VARCHAR (100) NULL,
    [ACModelId]       BIGINT        NULL,
    [ACModelName]     VARCHAR (100) NULL,
    [ACSubModel]      VARCHAR (100) NULL,
    [ItemMasterId]    BIGINT        NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NULL,
    [UpdatedBy]       VARCHAR (256) NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_AircraftInfo_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_AircraftInfo_UpdatedDate] DEFAULT (getutcdate()) NULL,
    [IsActive]        BIT           CONSTRAINT [DF_AircraftInfo_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_AircraftInfo_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AircraftInfo] PRIMARY KEY CLUSTERED ([AircraftInfoId] ASC)
);

