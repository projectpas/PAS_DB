CREATE TABLE [dbo].[TaskStatus] (
    [TaskStatusId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (200)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NULL,
    [CreatedBy]       VARCHAR (256)  NULL,
    [UpdatedBy]       VARCHAR (256)  NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_TaskStatus_CreatedDate] DEFAULT (getdate()) NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_TaskStatus_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]        BIT            CONSTRAINT [DF_TaskStatus_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_TaskStatus_IsDeleted] DEFAULT ((0)) NULL,
    [StatusCode]      VARCHAR (25)   NULL,
    PRIMARY KEY CLUSTERED ([TaskStatusId] ASC)
);


GO




----------------------------------------------

CREATE TRIGGER [dbo].[Trg_TaskStatusAudit]

   ON  [dbo].[TaskStatus]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[TaskStatusAudit] 

    SELECT * 

	FROM INSERTED 

	SET NOCOUNT ON;



END