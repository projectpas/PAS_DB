CREATE TABLE [dbo].[CommonTeardownType] (
    [CommonTeardownTypeId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Name]                 VARCHAR (256) NOT NULL,
    [Description]          VARCHAR (MAX) NULL,
    [IsTechnician]         BIT           NULL,
    [IsDate]               BIT           NULL,
    [IsInspector]          BIT           NULL,
    [IsInspectorDate]      BIT           NULL,
    [IsDocument]           BIT           NULL,
    [TearDownCode]         VARCHAR (200) NULL,
    [Sequence]             INT           NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [DF_CommonTeardowntype_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [DF_CommonTeardowntype_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [CommonTeardownType_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [CommonTeardownType_DC_Delete] DEFAULT ((0)) NOT NULL,
    [DocumentModuleName]   VARCHAR (100) NULL,
    CONSTRAINT [PK_CommonTeardownType] PRIMARY KEY CLUSTERED ([CommonTeardownTypeId] ASC),
    CONSTRAINT [Unique_CommonTeardowntype] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);


GO

CREATE TRIGGER [dbo].[Trg_CommonTeardownTypeAudit]
   ON  [dbo].[CommonTeardownType]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO CommonTeardownTypeAudit
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END