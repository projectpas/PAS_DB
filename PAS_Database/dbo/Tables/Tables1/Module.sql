CREATE TABLE [dbo].[Module] (
    [ModuleId]        INT           IDENTITY (1, 1) NOT NULL,
    [ModuleName]      VARCHAR (100) NOT NULL,
    [CodePrefix]      VARCHAR (10)  NOT NULL,
    [CodeSufix]       VARCHAR (10)  NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [Module_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [Module_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [Module_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [Module_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Module] PRIMARY KEY CLUSTERED ([ModuleId] ASC),
    CONSTRAINT [Un_ModuleName] UNIQUE NONCLUSTERED ([ModuleName] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_ModuleAudit]

   ON  [dbo].[Module]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[ModuleAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END