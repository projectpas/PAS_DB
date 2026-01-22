CREATE TABLE [dbo].[CycleCountApproval] (
    [CycleCountApprovalId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [CycleCountId]         BIGINT         NOT NULL,
    [CycleCountDetailId]   BIGINT         NOT NULL,
    [InternalSentToId]     BIGINT         NULL,
    [InternalSentToName]   VARCHAR (100)  NULL,
    [InternalSentById]     BIGINT         NULL,
    [SentDate]             DATETIME2 (7)  NULL,
    [ApprovedDate]         DATETIME2 (7)  NULL,
    [ApprovedById]         BIGINT         NULL,
    [ApprovedByName]       VARCHAR (200)  NULL,
    [RejectedDate]         DATETIME2 (7)  NULL,
    [RejectedBy]           BIGINT         NULL,
    [RejectedByName]       VARCHAR (200)  NULL,
    [StatusId]             INT            NULL,
    [StatusName]           VARCHAR (50)   NULL,
    [ActionId]             INT            NULL,
    [Memo]                 NVARCHAR (MAX) NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [CreatedDate]          DATETIME2 (7)  NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  NOT NULL,
    [IsActive]             BIT            CONSTRAINT [DF_CycleCountApproval_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT            CONSTRAINT [DF_CycleCountApproval_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CycleCountApproval] PRIMARY KEY CLUSTERED ([CycleCountApprovalId] ASC),
    CONSTRAINT [FK_CycleCountApproval_CycleCount] FOREIGN KEY ([CycleCountId]) REFERENCES [dbo].[CycleCount] ([CycleCountId]),
    CONSTRAINT [FK_CycleCountApproval_CycleCountDetail] FOREIGN KEY ([CycleCountDetailId]) REFERENCES [dbo].[CycleCountDetail] ([CycleCountDetailId]),
    CONSTRAINT [FK_CycleCountApproval_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO
/*************************************************************             
 ** File:  Trg_CycleCountApprovalAudit      
 ** Author:   Moin Bloch
 ** Description: Trigger For Audit Table
 ** Purpose:           
 ** Date:   07/11/2024         
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author		Change Description              
 ** --   --------     -------		-------------------------------            
    1    07/11/2024   Moin Bloch    Created
**************************************************************/
CREATE   TRIGGER [dbo].[Trg_CycleCountApprovalAudit] ON [dbo].[CycleCountApproval]
AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	INSERT INTO [dbo].[CycleCountApprovalAudit]
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END