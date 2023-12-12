CREATE TABLE [dbo].[Task] (
    [TaskId]          BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (200)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NULL,
    [CreatedBy]       VARCHAR (256)  NULL,
    [UpdatedBy]       VARCHAR (256)  NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Task_CreatedDate] DEFAULT (getdate()) NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Task_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]        BIT            DEFAULT ((1)) NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_Task_IsDeleted] DEFAULT ((0)) NULL,
    [Sequence]        BIGINT         NOT NULL,
    [IsTravelerTask]  BIT            NULL,
    PRIMARY KEY CLUSTERED ([TaskId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_TaskAudit] ON [dbo].[Task]

   AFTER INSERT,UPDATE  

AS   

BEGIN  



 INSERT INTO [dbo].[TaskAudit]  

 SELECT * FROM INSERTED  



 SET NOCOUNT ON;  



END