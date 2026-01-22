CREATE TABLE [dbo].[CreditMemoApproval] (
    [CreditMemoApprovalId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [CreditMemoHeaderId]   BIGINT         NOT NULL,
    [CreditMemoDetailId]   BIGINT         NOT NULL,
    [Memo]                 NVARCHAR (MAX) NULL,
    [SentDate]             DATETIME2 (7)  NULL,
    [ApprovedDate]         DATETIME2 (7)  NULL,
    [ApprovedById]         BIGINT         NULL,
    [ApprovedByName]       VARCHAR (200)  NULL,
    [InternalSentToId]     BIGINT         NULL,
    [InternalSentToName]   VARCHAR (100)  NULL,
    [InternalSentById]     BIGINT         NULL,
    [RejectedDate]         DATETIME2 (7)  NULL,
    [RejectedBy]           BIGINT         NULL,
    [RejectedByName]       VARCHAR (200)  NULL,
    [StatusId]             INT            NULL,
    [StatusName]           VARCHAR (50)   NULL,
    [ActionId]             INT            NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [CreatedDate]          DATETIME2 (7)  NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  NOT NULL,
    [IsActive]             BIT            CONSTRAINT [DF_CreditMemoApproval_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT            CONSTRAINT [DF_CreditMemoApproval_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CreditMemoApproval] PRIMARY KEY CLUSTERED ([CreditMemoApprovalId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_CreditMemoApprovalAudit]
ON  [dbo].[CreditMemoApproval]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO [dbo].[CreditMemoApprovalAudit]
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END