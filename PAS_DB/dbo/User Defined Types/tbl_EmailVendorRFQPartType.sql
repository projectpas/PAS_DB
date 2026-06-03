CREATE TYPE [dbo].[tbl_EmailVendorRFQPartType] AS TABLE (
    [PartNumber]   NVARCHAR (100)  NULL,
    [Description]  NVARCHAR (500)  NULL,
    [Condition]    NVARCHAR (50)   NULL,
    [Qty]          INT             NULL,
    [RequestedQty] INT             NULL,
    [Price]        DECIMAL (18, 4) NULL,
    [Notes]        NVARCHAR (MAX)  NULL);

