CREATE TABLE [dbo].[SalesOrderQuoteApproverList] (
    [SalesOrderQuoteApproverListId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuoteId]             BIGINT        NULL,
    [EmployeeId]                    BIGINT        NULL,
    [Level]                         INT           NULL,
    [StatusId]                      INT           NULL,
    [MasterCompanyId]               INT           NULL,
    [CreatedBy]                     VARCHAR (256) NULL,
    [UpdatedBy]                     VARCHAR (256) NULL,
    [CreatedDate]                   DATETIME2 (7) CONSTRAINT [DF_SalesOrderQuoteApproverList_CreatedDate] DEFAULT (getdate()) NULL,
    [UpdatedDate]                   DATETIME2 (7) CONSTRAINT [DF_SalesOrderQuoteApproverList_UpdatedDate] DEFAULT (getdate()) NULL,
    CONSTRAINT [PK_SalesOrderQuoteApproverList] PRIMARY KEY CLUSTERED ([SalesOrderQuoteApproverListId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_SalesOrderQuoteApproverListAudit]

   ON  [dbo].[SalesOrderQuoteApproverList]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO SalesOrderQuoteApproverListAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END