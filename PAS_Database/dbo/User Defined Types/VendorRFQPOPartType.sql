CREATE TYPE [dbo].[VendorRFQPOPartType] AS TABLE (
    [MasterCompanyId] INT             NULL,
    [VendorRFQPartId] BIGINT          NULL,
    [VendorId]        BIGINT          NULL,
    [EmployeeId]      BIGINT          NULL,
    [ItemMasterId]    BIGINT          NULL,
    [Condition]       VARCHAR (256)   NULL,
    [Qty]             INT             NULL,
    [UnitCost]        DECIMAL (18, 2) NULL);

