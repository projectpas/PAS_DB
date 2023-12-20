CREATE TABLE [dbo].[ManualJournalApproval] (
    [ManualJournalApprovalId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ManualJournalHeaderId]   BIGINT         NOT NULL,
    [ManualJournalDetailsId]  BIGINT         NOT NULL,
    [Memo]                    NVARCHAR (MAX) NULL,
    [SentDate]                DATETIME2 (7)  NULL,
    [ApprovedDate]            DATETIME2 (7)  NULL,
    [ApprovedById]            BIGINT         NULL,
    [ApprovedByName]          VARCHAR (200)  NULL,
    [RejectedDate]            DATETIME2 (7)  NULL,
    [RejectedBy]              BIGINT         NULL,
    [RejectedByName]          VARCHAR (200)  NULL,
    [StatusId]                INT            NULL,
    [StatusName]              VARCHAR (50)   NULL,
    [ActionId]                INT            NULL,
    [MasterCompanyId]         INT            NOT NULL,
    [CreatedBy]               VARCHAR (256)  NOT NULL,
    [UpdatedBy]               VARCHAR (256)  NOT NULL,
    [CreatedDate]             DATETIME2 (7)  NOT NULL,
    [UpdatedDate]             DATETIME2 (7)  NOT NULL,
    [IsActive]                BIT            CONSTRAINT [DF_ManualJournalApproval_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT            CONSTRAINT [DF_ManualJournalApproval_IsDeleted] DEFAULT ((0)) NOT NULL,
    [InternalSentToId]        BIGINT         NULL,
    [InternalSentToName]      VARCHAR (100)  NULL,
    [InternalSentById]        BIGINT         NULL,
    CONSTRAINT [PK_ManualJournalApproval] PRIMARY KEY CLUSTERED ([ManualJournalApprovalId] ASC)
);


GO
--=============================================
CREATE TRIGGER [dbo].[Trg_ManualJournalApprovalAudit]
   ON  [dbo].[ManualJournalApproval]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	INSERT INTO ManualJournalApprovalAudit
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END