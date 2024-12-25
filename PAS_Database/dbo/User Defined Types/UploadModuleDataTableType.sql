CREATE TYPE [dbo].[UploadModuleDataTableType] AS TABLE (
    [ModuleId]        BIGINT        NULL,
    [UserName]        VARCHAR (100) NULL,
    [MasterCompanyId] INT           NULL,
    [UploadRecord]    VARCHAR (MAX) NULL);

