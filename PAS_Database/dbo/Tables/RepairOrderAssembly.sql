CREATE TABLE [dbo].[RepairOrderAssembly] (
    [RepairOrderAssemblyId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ItemMasterId]          BIGINT          NOT NULL,
    [VendorId]              BIGINT          NOT NULL,
    [UnitCost]              DECIMAL (18, 2) NULL,
    [NeedByDate]            DATETIME2 (7)   NOT NULL,
    [Quantity]              INT             NOT NULL,
    [ConditionId]           BIGINT          NOT NULL,
    [ProvisionId]           BIGINT          NOT NULL,
    [IsAutoCreateRo]        BIT             NOT NULL,
    [MappingItemMasterId]   BIGINT          NULL,
    [Memo]                  NVARCHAR (MAX)  NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CreatedBy]             VARCHAR (256)   NOT NULL,
    [UpdatedBy]             VARCHAR (256)   NOT NULL,
    [CreatedDate]           DATETIME2 (7)   CONSTRAINT [DF_RepairOrderAssembly_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)   CONSTRAINT [DF_RepairOrderAssembly_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT             CONSTRAINT [DF_RepairOrderAssembly_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT             CONSTRAINT [DF_RepairOrderAssembly_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_RepairOrderAssembly] PRIMARY KEY CLUSTERED ([RepairOrderAssemblyId] ASC)
);

