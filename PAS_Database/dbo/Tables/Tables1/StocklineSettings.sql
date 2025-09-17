CREATE TABLE [dbo].[StocklineSettings] (
    [Id]                BIGINT         IDENTITY (1, 1) NOT NULL,
    [RedIndicator]      INT            NOT NULL,
    [YellowIndicator]   INT            NOT NULL,
    [GreenIndicator]    INT            NOT NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  CONSTRAINT [DF_StocklineSettings_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  CONSTRAINT [DF_StocklineSettings_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT            CONSTRAINT [DF_StocklineSettings_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT            CONSTRAINT [DF_StocklineSettings_IsDelete] DEFAULT ((0)) NOT NULL,
    [IsPNSNWarning]     BIT            NULL,
    [IsPNSNRestriction] BIT            NULL,
    [SiteId]            BIGINT         NULL,
    [Site]              VARCHAR (100)  NULL,
    [WarehouseId]       BIGINT         NULL,
    [Warehouse]         VARCHAR (100)  NULL,
    [LocationId]        BIGINT         NULL,
    [Location]          VARCHAR (100)  NULL,
    [ShelfId]           BIGINT         NULL,
    [Shelf]             VARCHAR (100)  NULL,
    [BinId]             BIGINT         NULL,
    [Bin]               VARCHAR (100)  NULL,
    [IsWeeklyOrMonthly] INT            NULL,
    [ExecutionDate]     DATETIME2 (7)  NULL,
    [WeeklyName]        VARCHAR (10)   NULL,
    [ExcludedLocations] NVARCHAR (500) NULL,
    CONSTRAINT [PK_StocklineSettings] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_StocklineSettings_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);



