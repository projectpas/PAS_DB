CREATE TABLE [dbo].[StockInventoryEmployeeMapping] (
    [StockInventoryEmployeeMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [StockInventorySearchParamsId]    BIGINT        NOT NULL,
    [EmployeeId]                      BIGINT        NULL,
    [MasterCompanyId]                 INT           NOT NULL,
    [CreatedBy]                       VARCHAR (50)  NOT NULL,
    [CreatedDate]                     DATETIME2 (7) CONSTRAINT [DF_StockInventoryEmployeeMapping_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                       VARCHAR (50)  NOT NULL,
    [UpdatedDate]                     DATETIME2 (7) CONSTRAINT [DF_StockInventoryEmployeeMapping_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                        BIT           CONSTRAINT [DF_StockInventoryEmployeeMapping_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                       BIT           CONSTRAINT [DF_StockInventoryEmployeeMapping_IsDeleted] DEFAULT ((0)) NOT NULL
);

