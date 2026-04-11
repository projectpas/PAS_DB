CREATE TABLE [dbo].[PositionCode] (
    [PositionCodeId]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [Code]            VARCHAR (256) NOT NULL,
    [Description]     VARCHAR (MAX) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_PositionCode_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_PositionCode_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_PositionCode_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_PositionCode_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_PositionCode] PRIMARY KEY CLUSTERED ([PositionCodeId] ASC)
);

