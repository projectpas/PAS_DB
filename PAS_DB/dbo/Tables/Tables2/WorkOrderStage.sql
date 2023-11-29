CREATE TABLE [dbo].[WorkOrderStage] (
    [WorkOrderStageId]     BIGINT         IDENTITY (1, 1) NOT NULL,
    [Code]                 VARCHAR (10)   NOT NULL,
    [Stage]                VARCHAR (100)  NOT NULL,
    [Sequence]             INT            NOT NULL,
    [StatusId]             BIGINT         NOT NULL,
    [Description]          VARCHAR (500)  NULL,
    [Memo]                 NVARCHAR (MAX) NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [CreatedDate]          DATETIME2 (7)  CONSTRAINT [WorkOrderStage_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  CONSTRAINT [WorkOrderStage_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT            CONSTRAINT [DF_WorkOrderStage_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT            CONSTRAINT [DF_WorkOrderStage_IsDeleted] DEFAULT ((0)) NOT NULL,
    [StageCode]            NVARCHAR (50)  NULL,
    [CodeDescription]      VARCHAR (200)  NULL,
    [IncludeInDashboard]   BIT            DEFAULT ((0)) NULL,
    [ManagerId]            BIGINT         NULL,
    [IsCustAlerts]         BIT            NULL,
    [IncludeInStageReport] BIT            NULL,
    CONSTRAINT [PK_WorkOrderStage] PRIMARY KEY CLUSTERED ([WorkOrderStageId] ASC),
    CONSTRAINT [FK_WorkOrderStage_StatusId] FOREIGN KEY ([StatusId]) REFERENCES [dbo].[WorkOrderStatus] ([Id]),
    CONSTRAINT [FK_WorkOrderStatge_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO
  
  
CREATE   TRIGGER [dbo].[Trg_WorkOrderStageAudit]  
  
   ON  [dbo].[WorkOrderStage]  
  
   AFTER INSERT,DELETE,UPDATE  
  
AS  
BEGIN  
  
   declare @ManagerId BIGINT  
   declare @EmployeeName varchar(100)  
  
   select @ManagerId=ManagerId FROM INSERTED  
   select @EmployeeName=EMP.FirstName + ' ' + EMP.LastName FROM Employee EMP  where EMP.EmployeeId= @ManagerId  
   INSERT INTO WorkOrderStageAudit  
   SELECT WorkOrderStageId,Code,Stage,Sequence,StatusId,Description,Memo,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,StageCode,CodeDescription,IncludeInDashboard,ManagerId,IsCustAlerts,@EmployeeName,IncludeInStageReport FROM INSERTED;  
  
   UPDATE [dbo].[WorkOrderStage] SET CodeDescription = WS.Code + ' - ' + UPPER(WS.Stage)  
   FROM [dbo].[WorkOrderStage] WS JOIN INSERTED ins ON ws.WorkOrderStageId = ins.WorkOrderStageId;  
  
   SET NOCOUNT ON;  
  
END