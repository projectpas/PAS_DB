CREATE TABLE [dbo].[CRMDeal] (
    [CRMDealId]            BIGINT          IDENTITY (1, 1) NOT NULL,
    [PrimarySalesPersonId] BIGINT          NULL,
    [DealNumber]           VARCHAR (30)    NOT NULL,
    [DealName]             VARCHAR (50)    NOT NULL,
    [DealOwnerId]          BIGINT          NULL,
    [DealSource]           VARCHAR (50)    NULL,
    [OpenDate]             DATETIME2 (7)   NOT NULL,
    [ClosingDate]          DATETIME2 (7)   NULL,
    [ExpectedRevenue]      DECIMAL (18, 2) NULL,
    [Competitors]          VARCHAR (256)   NULL,
    [Probability]          NUMERIC (18)    NULL,
    [IsDealOutComeWon]     BIT             CONSTRAINT [CRMDeal_DC_IsDealOutComeWon] DEFAULT ((0)) NOT NULL,
    [OutCome]              DECIMAL (18, 2) NULL,
    [Memo]                 NVARCHAR (MAX)  NULL,
    [MasterCompanyId]      INT             NOT NULL,
    [CreatedBy]            VARCHAR (256)   NOT NULL,
    [UpdatedBy]            VARCHAR (256)   NOT NULL,
    [CreatedDate]          DATETIME2 (7)   CONSTRAINT [DF_CRMDeal_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7)   CONSTRAINT [DF_CRMDeal_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT             CONSTRAINT [CRMDeal_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT             CONSTRAINT [CRMDeal_DC_Delete] DEFAULT ((0)) NOT NULL,
    [DealStageId]          BIGINT          NOT NULL,
    [DealLossReasonId]     BIGINT          NULL,
    [CustomerId]           BIGINT          NOT NULL,
    CONSTRAINT [PK_CRMDeal] PRIMARY KEY CLUSTERED ([CRMDealId] ASC),
    CONSTRAINT [FK_CRMDeal_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CRMDeal_DealLoss] FOREIGN KEY ([DealLossReasonId]) REFERENCES [dbo].[DealLossReason] ([DealLossReasonId]),
    CONSTRAINT [FK_CRMDeal_DealStage] FOREIGN KEY ([DealStageId]) REFERENCES [dbo].[DealStage] ([DealStageId]),
    CONSTRAINT [FK_CRMDeal_Employee] FOREIGN KEY ([PrimarySalesPersonId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_CRMDeal_Employee_Owner] FOREIGN KEY ([DealOwnerId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_CRMDeal_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_CRMDeal] UNIQUE NONCLUSTERED ([DealNumber] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_CRMDealAudit]

   ON  [dbo].[CRMDeal]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO CRMDealAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END