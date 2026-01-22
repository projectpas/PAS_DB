CREATE TABLE [dbo].[RMAReason] (
    [RMAReasonId]     BIGINT         IDENTITY (1, 1) NOT NULL,
    [Reason]          VARCHAR (1000) NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [RMAReason_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [RMAReason_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [RMAReason_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [RMAReason_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_RMAReason] PRIMARY KEY CLUSTERED ([RMAReasonId] ASC),
    CONSTRAINT [FK_RMAReason_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UC_RMAReason] UNIQUE NONCLUSTERED ([Reason] ASC, [MasterCompanyId] ASC)
);


GO



CREATE TRIGGER [dbo].[Trg_RMAReasonAudit]

   ON  [dbo].[RMAReason]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[RMAReasonAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;



END