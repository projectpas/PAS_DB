CREATE TABLE [dbo].[LeaseRateUnit] (
    [LeaseRateUnitId] INT            IDENTITY (1, 1) NOT NULL,
    [LeaseRateUnit]   NVARCHAR (100) NOT NULL,
    [Description]     NVARCHAR (500) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (100)  NULL,
    [UpdatedBy]       VARCHAR (100)  NULL,
    [CreatedDate]     DATETIME       CONSTRAINT [DF_LeaseRateUnit_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]     DATETIME       CONSTRAINT [DF_LeaseRateUnit_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_LeaseRateUnit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_LeaseRateUnit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LeaseRateUnit] PRIMARY KEY CLUSTERED ([LeaseRateUnitId] ASC)
);

