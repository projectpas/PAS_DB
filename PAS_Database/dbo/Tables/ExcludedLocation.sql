CREATE TABLE [dbo].[ExcludedLocation] (
    [ExcludedLocationId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [MainLocationId]     BIGINT         NULL,
    [WarehouseId]        BIGINT         NOT NULL,
    [Name]               VARCHAR (50)   NOT NULL,
    [Memo]               NVARCHAR (MAX) NULL,
    [MasterCompanyId]    INT            NOT NULL,
    [CreatedBy]          VARCHAR (256)  NOT NULL,
    [UpdatedBy]          VARCHAR (256)  NOT NULL,
    [CreatedDate]        DATETIME2 (7)  NOT NULL,
    [UpdatedDate]        DATETIME2 (7)  NOT NULL,
    [IsActive]           BIT            NOT NULL,
    [IsDeleted]          BIT            NOT NULL,
    CONSTRAINT [PK_ExcludedLocation] PRIMARY KEY CLUSTERED ([ExcludedLocationId] ASC),
    CONSTRAINT [Unique_ExcludedLocation] UNIQUE NONCLUSTERED ([Name] ASC, [WarehouseId] ASC, [MasterCompanyId] ASC)
);

