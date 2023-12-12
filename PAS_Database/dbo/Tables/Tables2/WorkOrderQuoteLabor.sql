CREATE TABLE [dbo].[WorkOrderQuoteLabor] (
    [WorkOrderQuoteLaborId]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderQuoteLaborHeaderId] BIGINT          NOT NULL,
    [ExpertiseId]                 SMALLINT        NOT NULL,
    [Hours]                       DECIMAL (10, 2) NOT NULL,
    [BillableId]                  INT             NOT NULL,
    [CreatedBy]                   VARCHAR (256)   NOT NULL,
    [UpdatedBy]                   VARCHAR (256)   NOT NULL,
    [CreatedDate]                 DATETIME2 (7)   CONSTRAINT [DF_WorkOrderQuoteLabor_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)   CONSTRAINT [DF_WorkOrderQuoteLabor_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT             DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT             DEFAULT ((0)) NOT NULL,
    [TaskId]                      BIGINT          NOT NULL,
    [DirectLaborOHCost]           DECIMAL (20, 2) NOT NULL,
    [MarkupPercentageId]          BIGINT          NULL,
    [BurdenRateAmount]            DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderQuoteLabor_BurdenRateAmount] DEFAULT ((0)) NULL,
    [TotalCostPerHour]            DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderQuoteLabor_TotalCostPerHour] DEFAULT ((0)) NULL,
    [TotalCost]                   DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderQuoteLabor_TotalCost] DEFAULT ((0)) NULL,
    [BillingRate]                 DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderQuoteLabor_BillingRate] DEFAULT ((0)) NULL,
    [BillingAmount]               DECIMAL (20, 2) CONSTRAINT [DF_WorkOrderQuoteLabor_BillingAmount] DEFAULT ((0)) NULL,
    [BurdaenRatePercentageId]     BIGINT          NULL,
    [BillingMethodId]             INT             NULL,
    [MasterCompanyId]             INT             NULL,
    [TaskName]                    VARCHAR (100)   NULL,
    [Expertise]                   VARCHAR (50)    NULL,
    [Billabletype]                VARCHAR (50)    NULL,
    [BurdaenRatePercentage]       VARCHAR (50)    NULL,
    [BillingName]                 VARCHAR (50)    NULL,
    [MarkUp]                      VARCHAR (50)    NULL,
    [EmployeeId]                  BIGINT          NULL,
    CONSTRAINT [PK_WorkOrderQuoteLabor] PRIMARY KEY CLUSTERED ([WorkOrderQuoteLaborId] ASC),
    CONSTRAINT [FK_WorkOrderQuoteLabor_BurdaenRatePercentage] FOREIGN KEY ([BurdaenRatePercentageId]) REFERENCES [dbo].[Percent] ([PercentId]),
    CONSTRAINT [FK_WorkOrderQuoteLabor_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrderQuoteLabor_Expertise] FOREIGN KEY ([ExpertiseId]) REFERENCES [dbo].[EmployeeExpertise] ([EmployeeExpertiseId]),
    CONSTRAINT [FK_WorkOrderQuoteLabor_MarkupPercentage] FOREIGN KEY ([MarkupPercentageId]) REFERENCES [dbo].[Percent] ([PercentId]),
    CONSTRAINT [FK_WorkOrderQuoteLabor_MasterCompanyId] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderQuoteLabor_Task] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkOrderQuoteLabor_WorkOrderQuoteLaborHeader] FOREIGN KEY ([WorkOrderQuoteLaborHeaderId]) REFERENCES [dbo].[WorkOrderQuoteLaborHeader] ([WorkOrderQuoteLaborHeaderId])
);


GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_WorkOrderQuoteLaborAudit]

   ON  [dbo].[WorkOrderQuoteLabor]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[WorkOrderQuoteLaborAudit] 

    SELECT * 

	FROM INSERTED 

	SET NOCOUNT ON;



END