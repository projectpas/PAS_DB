CREATE TYPE [dbo].[FieldSettingTableType] AS TABLE (
    [FieldMasterId]  BIGINT        NULL,
    [ModuleId]       BIGINT        NULL,
    [HeaderName]     VARCHAR (200) NULL,
    [FieldWidth]     VARCHAR (20)  NULL,
    [FieldAlign]     INT           NULL,
    [FieldSortOrder] INT           NULL,
    [IsMobileView]   BIT           NULL,
    [IsActive]       BIT           NULL);

