CREATE TABLE [dbo].[WorkOrderDocuments] (
    [WorkOrderDocumentId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]         BIGINT         NOT NULL,
    [WorkFlowWorkOrderId] BIGINT         NOT NULL,
    [AttachmentId]        BIGINT         NOT NULL,
    [Name]                VARCHAR (100)  NOT NULL,
    [Memo]                NVARCHAR (MAX) NULL,
    [Description]         VARCHAR (100)  NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  CONSTRAINT [DF_WorkOrderDocuments_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  CONSTRAINT [DF_WorkOrderDocuments_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT            CONSTRAINT [WorkOrderDocuments_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT            CONSTRAINT [WorkOrderDocuments_DC_Delete] DEFAULT ((0)) NOT NULL,
    [TypeId]              BIGINT         NOT NULL,
    [WOPartNoId]          BIGINT         DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderDocuments] PRIMARY KEY CLUSTERED ([WorkOrderDocumentId] ASC),
    CONSTRAINT [FK_WorkOrderDocuments_Attachment] FOREIGN KEY ([AttachmentId]) REFERENCES [dbo].[Attachment] ([AttachmentId]),
    CONSTRAINT [FK_WorkOrderDocuments_DocumentType] FOREIGN KEY ([TypeId]) REFERENCES [dbo].[DocumentType] ([DocumentTypeId]),
    CONSTRAINT [FK_WorkOrderDocuments_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderDocuments_WorkFlowWorkOrderId] FOREIGN KEY ([WorkFlowWorkOrderId]) REFERENCES [dbo].[WorkOrderWorkFlow] ([WorkFlowWorkOrderId]),
    CONSTRAINT [FK_WorkOrderDocuments_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId]),
    CONSTRAINT [UQ_WorkOrderDocumentDeatails] UNIQUE NONCLUSTERED ([WorkOrderId] ASC, [MasterCompanyId] ASC, [AttachmentId] ASC)
);


GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_WorkOrderDocumentsAudit]

   ON  [dbo].[WorkOrderDocuments]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[WorkOrderDocumentsAudit] 

    SELECT * 

	FROM INSERTED 

	SET NOCOUNT ON;



END