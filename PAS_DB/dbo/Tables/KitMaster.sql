CREATE TABLE [dbo].[KitMaster] (
    [KitId]           BIGINT          IDENTITY (1, 1) NOT NULL,
    [KitNumber]       VARCHAR (100)   NULL,
    [ItemMasterId]    BIGINT          NULL,
    [ManufacturerId]  BIGINT          NULL,
    [PartNumber]      VARCHAR (200)   NOT NULL,
    [PartDescription] VARCHAR (500)   NOT NULL,
    [Manufacturer]    VARCHAR (100)   NOT NULL,
    [MasterCompanyId] INT             NULL,
    [CreatedBy]       VARCHAR (256)   NULL,
    [UpdatedBy]       VARCHAR (256)   NULL,
    [CreatedDate]     DATETIME2 (7)   NULL,
    [UpdatedDate]     DATETIME2 (7)   NULL,
    [IsActive]        BIT             NULL,
    [IsDeleted]       BIT             NULL,
    [CustomerId]      BIGINT          NULL,
    [CustomerName]    VARCHAR (250)   NULL,
    [KitCost]         DECIMAL (18, 2) NOT NULL,
    [KitDescription]  VARCHAR (250)   NULL,
    [WorkScopeId]     BIGINT          NULL,
    [WorkScopeName]   VARCHAR (250)   NULL,
    [Memo]            VARCHAR (MAX)   NULL
);

