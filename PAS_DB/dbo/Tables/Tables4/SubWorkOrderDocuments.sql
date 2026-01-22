CREATE TABLE [dbo].[SubWorkOrderDocuments] (
    [SubWorkOrderDocumentId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]            BIGINT         NOT NULL,
    [SubWorkOrderId]         BIGINT         NOT NULL,
    [SubWOPartNoId]          BIGINT         NOT NULL,
    [AttachmentId]           BIGINT         NOT NULL,
    [Name]                   VARCHAR (100)  NOT NULL,
    [Memo]                   NVARCHAR (MAX) NULL,
    [Description]            VARCHAR (250)  NULL,
    [TypeId]                 BIGINT         NOT NULL,
    [MasterCompanyId]        INT            NOT NULL,
    [CreatedBy]              VARCHAR (256)  NOT NULL,
    [UpdatedBy]              VARCHAR (256)  NOT NULL,
    [CreatedDate]            DATETIME2 (7)  CONSTRAINT [DF_SubWorkOrderDocuments_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  CONSTRAINT [DF_SubWorkOrderDocuments_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT            CONSTRAINT [SubWorkOrderDocuments_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT            CONSTRAINT [SubWorkOrderDocuments_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SubWorkOrderDocuments] PRIMARY KEY CLUSTERED ([SubWorkOrderDocumentId] ASC),
    CONSTRAINT [FK_SubWorkOrderDocuments_Attachment] FOREIGN KEY ([AttachmentId]) REFERENCES [dbo].[Attachment] ([AttachmentId]),
    CONSTRAINT [FK_SubWorkOrderDocuments_DocumentType] FOREIGN KEY ([TypeId]) REFERENCES [dbo].[DocumentType] ([DocumentTypeId]),
    CONSTRAINT [FK_SubWorkOrderDocuments_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SubWorkOrderDocuments_SubWorkOrder] FOREIGN KEY ([SubWorkOrderId]) REFERENCES [dbo].[SubWorkOrder] ([SubWorkOrderId]),
    CONSTRAINT [FK_SubWorkOrderDocuments_SubWorkOrderPartNumber] FOREIGN KEY ([SubWOPartNoId]) REFERENCES [dbo].[SubWorkOrderPartNumber] ([SubWOPartNoId]),
    CONSTRAINT [FK_SubWorkOrderDocuments_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId]),
    CONSTRAINT [UQ_SubWorkOrderDocumentDeatails] UNIQUE NONCLUSTERED ([SubWorkOrderId] ASC, [MasterCompanyId] ASC, [AttachmentId] ASC)
);


GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_SubWorkOrderDocumentsAudit]

   ON  [dbo].[SubWorkOrderDocuments]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[SubWorkOrderDocumentsAudit] 

    SELECT * 

	FROM INSERTED 

	SET NOCOUNT ON;



END