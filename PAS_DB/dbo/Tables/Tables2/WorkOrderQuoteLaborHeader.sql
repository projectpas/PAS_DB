CREATE TABLE [dbo].[WorkOrderQuoteLaborHeader] (
    [WorkOrderQuoteLaborHeaderId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderQuoteDetailsId]     BIGINT        NOT NULL,
    [DataEnteredBy]               BIGINT        NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) CONSTRAINT [DF_WorkOrderQuoteLaborHeader_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) CONSTRAINT [DF_WorkOrderQuoteLaborHeader_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT           DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT           DEFAULT ((0)) NOT NULL,
    [MarkupFixedPrice]            VARCHAR (15)  NULL,
    [HeaderMarkupId]              BIGINT        NULL,
    CONSTRAINT [PK_WorkOrderQuoteLaborHeader] PRIMARY KEY CLUSTERED ([WorkOrderQuoteLaborHeaderId] ASC),
    CONSTRAINT [FK_WorkOrderQuoteLaborHeader_DataEnteredBy] FOREIGN KEY ([DataEnteredBy]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrderQuoteLaborHeader_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderQuoteLaborHeader_WorkOrderQuoteDetails] FOREIGN KEY ([WorkOrderQuoteDetailsId]) REFERENCES [dbo].[WorkOrderQuoteDetails] ([WorkOrderQuoteDetailsId])
);


GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_WorkOrderQuoteLaborHeaderAudit]

   ON  [dbo].[WorkOrderQuoteLaborHeader]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[WorkOrderQuoteLaborHeaderAudit] 

    SELECT * 

	FROM INSERTED 

	SET NOCOUNT ON;



END