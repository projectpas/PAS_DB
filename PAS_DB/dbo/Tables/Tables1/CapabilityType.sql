CREATE TABLE [dbo].[CapabilityType] (
    [CapabilityTypeId]   INT            IDENTITY (1, 1) NOT NULL,
    [Description]        VARCHAR (50)   NOT NULL,
    [IsActive]           BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT            DEFAULT ((0)) NOT NULL,
    [SequenceMemo]       NVARCHAR (MAX) NULL,
    [MasterCompanyId]    INT            NOT NULL,
    [CreatedBy]          VARCHAR (256)  NOT NULL,
    [UpdatedBy]          VARCHAR (256)  NOT NULL,
    [CreatedDate]        DATETIME2 (7)  CONSTRAINT [CapabilityType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]        DATETIME2 (7)  CONSTRAINT [CapabilityType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [SequenceNo]         INT            NOT NULL,
    [CapabilityTypeDesc] VARCHAR (256)  NULL,
    [WorkScopeId]        BIGINT         NULL,
    [ConditionId]        INT            NULL,
    CONSTRAINT [PK_CapabilityType] PRIMARY KEY CLUSTERED ([CapabilityTypeId] ASC),
    CONSTRAINT [FK_CapabilityType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_CapabilityType] UNIQUE NONCLUSTERED ([Description] ASC, [MasterCompanyId] ASC),
    CONSTRAINT [Unique_CapabilityTypeSeqNo] UNIQUE NONCLUSTERED ([SequenceNo] ASC, [MasterCompanyId] ASC)
);






GO






CREATE TRIGGER [dbo].[Trg_CapabilityTypeAuditDelete]

   ON  [dbo].[CapabilityType]

   AFTER DELETE

AS 

BEGIN

	INSERT INTO [dbo].[CapabilityTypeAudit]

	SELECT * FROM DELETED



	SET NOCOUNT ON;



END
GO


CREATE TRIGGER [dbo].[Trg_CapabilityType_WorkScope_Insert]

   ON  [dbo].[CapabilityType]

   AFTER INSERT

AS 

BEGIN

	DECLARE @WorkScopeId BIGINT;

	

	INSERT INTO [dbo].[WorkScope](WorkScopeCode,Description,Memo,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate, IsActive, IsDeleted, WorkScopeCodeNew,ConditionId )

	SELECT CapabilityTypeDesc, [Description], SequenceMemo, MasterCompanyId,CreatedBy, UpdatedBy, GETDATE(), GETDATE(), IsActive, IsDeleted,CapabilityTypeDesc,ConditionId FROM INSERTED



	SELECT @WorkScopeId = SCOPE_IDENTITY();



	UPDATE [dbo].[CapabilityType] SET WorkScopeId = @WorkScopeId 
	FROM [dbo].[CapabilityType] WS JOIN INSERTED ins ON ws.CapabilityTypeId = ins.CapabilityTypeId


	SET NOCOUNT ON;



END
GO






CREATE TRIGGER [dbo].[Trg_CapabilityType_WorkScope_Delete]

   ON  [dbo].[CapabilityType]

   FOR DELETE

AS 

BEGIN



	DELETE WS FROM [dbo].[WorkScope] WS JOIN DELETED ins ON ws.WorkScopeId = ins.WorkScopeId

	

	SET NOCOUNT ON;



END
GO








CREATE TRIGGER [dbo].[Trg_CapabilityTypeAudit]

   ON  [dbo].[CapabilityType]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[CapabilityTypeAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
GO

CREATE TRIGGER [dbo].[Trg_CapabilityType_WorkScope_Update]

   ON  [dbo].[CapabilityType]

   AFTER UPDATE

AS 

BEGIN



	UPDATE [dbo].[WorkScope] SET WorkScopeCode = ins.CapabilityTypeDesc, [Description]=ins.Description ,

	Memo = ins.SequenceMemo, IsActive = ins.IsActive, IsDeleted = ins.IsDeleted, ConditionId=ins.ConditionId

	FROM [dbo].[WorkScope] WS JOIN INSERTED ins ON ws.WorkScopeId = ins.WorkScopeId

	

	SET NOCOUNT ON;



END