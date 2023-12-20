CREATE TABLE [dbo].[ApprovalStatus] (
    [ApprovalStatusId] INT           IDENTITY (1, 1) NOT NULL,
    [Name]             VARCHAR (50)  NOT NULL,
    [Description]      VARCHAR (250) NULL,
    [MasterCompanyId]  INT           NOT NULL,
    [CreatedBy]        VARCHAR (50)  NOT NULL,
    [CreatedDate]      DATETIME2 (7) CONSTRAINT [DF_ApprovalStatus_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]        VARCHAR (50)  NOT NULL,
    [UpdatedDate]      DATETIME2 (7) CONSTRAINT [DF_ApprovalStatus_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]         BIT           CONSTRAINT [DF_ApprovalStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]        BIT           CONSTRAINT [DF_ApprovalStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ApprovalStatus] PRIMARY KEY CLUSTERED ([ApprovalStatusId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_ApprovalStatusAudit]

   ON  [dbo].[ApprovalStatus]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO ApprovalStatusAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END