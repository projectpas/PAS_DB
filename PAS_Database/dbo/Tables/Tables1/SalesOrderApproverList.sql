CREATE TABLE [dbo].[SalesOrderApproverList] (
    [SalesOrderApproverListId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [SalesOrderId]             BIGINT        NOT NULL,
    [EmployeeId]               BIGINT        NOT NULL,
    [Level]                    INT           NOT NULL,
    [MasterCompanyId]          INT           NOT NULL,
    [CreatedBy]                VARCHAR (256) NOT NULL,
    [UpdatedBy]                VARCHAR (256) NOT NULL,
    [CreatedDate]              DATETIME2 (7) CONSTRAINT [DF_SalesOrderApproverList_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7) CONSTRAINT [DF_SalesOrderApproverList_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_SalesOrderApproverList] PRIMARY KEY CLUSTERED ([SalesOrderApproverListId] ASC),
    CONSTRAINT [FK_SalesOrderApproverList_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrderApproverList_SalesOrderId] FOREIGN KEY ([SalesOrderId]) REFERENCES [dbo].[SalesOrder] ([SalesOrderId])
);


GO




CREATE TRIGGER [dbo].[Trg_SalesOrderApproverListAudit]

   ON  [dbo].[SalesOrderApproverList]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO SalesOrderApproverListAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END