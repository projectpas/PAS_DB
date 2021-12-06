CREATE TABLE [dbo].[TeardownType] (
    [TeardownTypeId]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (256) NOT NULL,
    [Description]     VARCHAR (MAX) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_Teardowntype_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_Teardowntype_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [TeardownType_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [TeardownType_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_TeardownType] PRIMARY KEY CLUSTERED ([TeardownTypeId] ASC),
    CONSTRAINT [Unique_Teardowntype] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_TeardownTypeAudit]

   ON  [dbo].[TeardownType]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	

	INSERT INTO TeardownTypeAudit

	SELECT * FROM INSERTED



SET NOCOUNT ON;

END