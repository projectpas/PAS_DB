CREATE TABLE [dbo].[Workflow] (
    [WorkflowId]                   BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkflowDescription]          VARCHAR (500)   NULL,
    [Version]                      VARCHAR (10)    NULL,
    [WorkScopeId]                  BIGINT          NULL,
    [ItemMasterId]                 BIGINT          NULL,
    [PartNumberDescription]        VARCHAR (MAX)   NULL,
    [CustomerId]                   BIGINT          NULL,
    [CurrencyId]                   INT             NULL,
    [WorkflowExpirationDate]       DATETIME2 (7)   NULL,
    [IsCalculatedBERThreshold]     BIT             NULL,
    [IsFixedAmount]                BIT             NULL,
    [FixedAmount]                  NUMERIC (18, 2) NULL,
    [IsPercentageOfNew]            BIT             NULL,
    [CostOfNew]                    NUMERIC (18, 2) NULL,
    [PercentageOfNew]              INT             NULL,
    [IsPercentageOfReplacement]    BIT             NULL,
    [CostOfReplacement]            NUMERIC (18, 2) NULL,
    [PercentageOfReplacement]      INT             NULL,
    [Memo]                         NVARCHAR (MAX)  NULL,
    [ManagementStructureId]        BIGINT          NULL,
    [MasterCompanyId]              INT             NOT NULL,
    [CreatedBy]                    VARCHAR (256)   NULL,
    [UpdatedBy]                    VARCHAR (256)   NULL,
    [CreatedDate]                  DATETIME2 (7)   CONSTRAINT [DF_Workflow_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7)   CONSTRAINT [DF_Workflow_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                     BIT             CONSTRAINT [DF_Workflow_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]                    BIT             CONSTRAINT [DF_Workflow_IsDelete] DEFAULT ((0)) NULL,
    [PartNumber]                   VARCHAR (256)   NULL,
    [CustomerName]                 VARCHAR (256)   NULL,
    [FlatRate]                     NUMERIC (18, 2) NULL,
    [BERThresholdAmount]           NUMERIC (18, 2) NULL,
    [WorkOrderNumber]              VARCHAR (256)   NULL,
    [CustomerCode]                 VARCHAR (100)   NULL,
    [OtherCost]                    NUMERIC (18, 2) NULL,
    [WorkflowCreateDate]           DATETIME2 (7)   NULL,
    [ChangedPartNumberId]          BIGINT          NULL,
    [PercentageOfMaterial]         INT             NULL,
    [PercentageOfExpertise]        INT             NULL,
    [PercentageOfCharges]          INT             NULL,
    [PercentageOfOthers]           INT             NULL,
    [PercentageOfTotal]            DECIMAL (18, 2) NULL,
    [RevisedPartNumber]            VARCHAR (200)   NULL,
    [changedPartNumberDescription] VARCHAR (200)   NULL,
    [ChangedPartNumber]            VARCHAR (200)   NULL,
    [WorkScope]                    VARCHAR (100)   NULL,
    [Currency]                     VARCHAR (100)   NULL,
    [WFParentId]                   BIGINT          NULL,
    [IsVersionIncrease]            BIT             NULL,
    CONSTRAINT [PK_Process] PRIMARY KEY CLUSTERED ([WorkflowId] ASC),
    FOREIGN KEY ([ChangedPartNumberId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK__Workflow__WorkSc__6BDB799E] FOREIGN KEY ([WorkScopeId]) REFERENCES [dbo].[WorkScope] ([WorkScopeId]),
    CONSTRAINT [FK_Workflow_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_WorkFlow_WFParentId] FOREIGN KEY ([WFParentId]) REFERENCES [dbo].[Workflow] ([WorkflowId])
);


GO








Create TRIGGER [dbo].[Trg_WorkflowAudit] ON [dbo].[Workflow]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  



 INSERT INTO [dbo].[WorkflowAudit]  

 SELECT * FROM INSERTED  



 SET NOCOUNT ON;  



END