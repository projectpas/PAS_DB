CREATE TABLE [dbo].[WorkOrderMain] (
    [WorkOrderId]             BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderNum]            VARCHAR (20)   NULL,
    [CustomerId]              BIGINT         NULL,
    [CustomerName]            VARCHAR (100)  NULL,
    [CustomerCode]            VARCHAR (20)   NULL,
    [CustomerRef]             VARCHAR (20)   NULL,
    [CustomerContact]         VARCHAR (50)   NULL,
    [CustomerPhone]           VARCHAR (20)   NULL,
    [CustomerFax]             VARCHAR (20)   NULL,
    [CustomerContractRef]     VARCHAR (20)   NULL,
    [WorkOrderType]           VARCHAR (20)   NULL,
    [WorkOrderQuantity]       VARCHAR (20)   NULL,
    [OpenDate]                DATETIME2 (7)  NULL,
    [CustomerRequestDate]     DATETIME2 (7)  NULL,
    [PromiseDate]             DATETIME2 (7)  NULL,
    [EstimatedCompletionDate] DATETIME2 (7)  NULL,
    [WorkScope]               VARCHAR (20)   NULL,
    [WorkOrderProcessRef]     VARCHAR (20)   NULL,
    [PartNumber]              BIGINT         NULL,
    [PartNumberDescription]   VARCHAR (50)   NULL,
    [RevisedPartNumber]       BIGINT         NULL,
    [SerialNumber]            BIGINT         NULL,
    [PMA]                     VARCHAR (20)   NULL,
    [DER]                     VARCHAR (20)   NULL,
    [CMMPubRefNumber]         VARCHAR (30)   NULL,
    [Priority]                VARCHAR (20)   NULL,
    [ManagementStructureId]   BIGINT         NOT NULL,
    [EmployeeId]              INT            NULL,
    [Notes]                   NVARCHAR (MAX) NULL,
    [MasterCompanyId]         INT            NOT NULL,
    [CreatedBy]               VARCHAR (256)  NOT NULL,
    [UpdatedBy]               VARCHAR (256)  NOT NULL,
    [CreatedDate]             DATETIME2 (7)  CONSTRAINT [DF_WorkOrderMain_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)  CONSTRAINT [DF_WorkOrderMain_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT            CONSTRAINT [DF_WorkOrderMain_IsActive] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_WorkOrderMain] PRIMARY KEY CLUSTERED ([WorkOrderId] ASC),
    CONSTRAINT [FK_WorkOrderMain_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_WorkOrderMain_ManagementStructure] FOREIGN KEY ([ManagementStructureId]) REFERENCES [dbo].[ManagementStructure] ([ManagementStructureId]),
    CONSTRAINT [FK_WorkOrderMain_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO




CREATE TRIGGER [dbo].[Trg_WorkOrderMainAudit]

   ON  [dbo].[WorkOrderMain]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderMainAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END