CREATE TABLE [dbo].[GLAccountNode] (
    [GLAccountNodeId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [LedgerName]        VARCHAR (30)   NOT NULL,
    [NodeCode]          VARCHAR (100)  NOT NULL,
    [NodeName]          VARCHAR (100)  NOT NULL,
    [Description]       VARCHAR (2000) NULL,
    [ParentNodeId]      BIGINT         NULL,
    [LeafNodeCheck]     BIT            CONSTRAINT [GLAccountNode_DC_LeafNodeCheck] DEFAULT ((0)) NOT NULL,
    [GLAccountNodeType] VARCHAR (50)   NOT NULL,
    [FSType]            VARCHAR (30)   NOT NULL,
    [LedgerNameId]      BIGINT         NOT NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  CONSTRAINT [GLAccountNode_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  CONSTRAINT [GLAccountNode_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT            DEFAULT ((0)) NOT NULL,
    [NodeTypeId]        BIGINT         NULL,
    CONSTRAINT [PK_GLAccountNode] PRIMARY KEY CLUSTERED ([GLAccountNodeId] ASC),
    CONSTRAINT [FK_GLAccountNode_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_GLAccountNode] UNIQUE NONCLUSTERED ([NodeName] ASC, [MasterCompanyId] ASC)
);


GO






-- =============================================

CREATE TRIGGER [dbo].[Trg_GLAccountNodeAudit]

   ON  [dbo].[GLAccountNode]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO GLAccountNodeAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END