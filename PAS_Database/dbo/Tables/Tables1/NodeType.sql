CREATE TABLE [dbo].[NodeType] (
    [NodeTypeId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [NodeTypeName]    VARCHAR (256)  NOT NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [NodeType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [NodeType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [NodeType_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [NodeType_DC_Delete] DEFAULT ((0)) NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [Description]     VARCHAR (256)  NOT NULL,
    CONSTRAINT [PK_NodeType] PRIMARY KEY CLUSTERED ([NodeTypeId] ASC),
    CONSTRAINT [FK_NodeType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_NodeType] UNIQUE NONCLUSTERED ([NodeTypeName] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_NodeTypeAudit]

   ON  [dbo].[NodeType]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[NodeTypeAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END