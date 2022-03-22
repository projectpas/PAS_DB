CREATE TABLE [dbo].[TaskAttribute] (
    [TaskAttributeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (100)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_TaskAttribute_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_TaskAttribute_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_TaskAttribute_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_TaskAttribute_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Sequence]        BIGINT         DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_TaskAttribute] PRIMARY KEY CLUSTERED ([TaskAttributeId] ASC),
    CONSTRAINT [UQ_TaskAttribute_codes] UNIQUE NONCLUSTERED ([Description] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_TaskAttributeAudit]

   ON  [dbo].[TaskAttribute]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[TaskAttributeAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END