CREATE TABLE [dbo].[FieldsMaster] (
    [FieldAutoId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [ModuleId]        BIGINT          NOT NULL,
    [FieldName]       NVARCHAR (100)  NOT NULL,
    [HeaderName]      NVARCHAR (100)  NOT NULL,
    [FieldGridWidth]  VARCHAR (10)    NOT NULL,
    [FieldPDFWidth]   DECIMAL (10, 2) NOT NULL,
    [FieldExcelWidth] DECIMAL (10, 2) NOT NULL,
    [FieldSortOrder]  SMALLINT        NULL,
    [IsActive]        BIT             DEFAULT ((1)) NULL,
    [MasterCompanyId] INT             DEFAULT ((0)) NULL,
    [IsNumString]     BIT             DEFAULT ((0)) NULL,
    [IsRightAlign]    BIT             CONSTRAINT [DF_FieldsMaster_IsRightAlign] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_FieldsMaster] PRIMARY KEY CLUSTERED ([FieldAutoId] ASC)
);



