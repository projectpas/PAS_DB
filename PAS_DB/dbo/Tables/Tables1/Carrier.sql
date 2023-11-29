CREATE TABLE [dbo].[Carrier] (
    [CarrierId]       BIGINT        IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (400) NULL,
    [Code]            VARCHAR (50)  NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (50)  NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_Carrier_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (50)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_Carrier_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF__Carrier__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF__Carrier__IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Carrier] PRIMARY KEY CLUSTERED ([CarrierId] ASC)
);




GO
