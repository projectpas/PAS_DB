CREATE TABLE [dbo].[CustomerWarnings] (
    [CustomerWarningsId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerId]         BIGINT        NOT NULL,
    [IsAllow]            BIT           NOT NULL,
    [IsWarning]          BIT           NOT NULL,
    [IsRestrict]         BIT           NOT NULL,
    [MasterCompanyId]    INT           CONSTRAINT [CustomerWarnings_MasterCompanyId] DEFAULT ((1)) NOT NULL,
    [CreatedBy]          VARCHAR (256) CONSTRAINT [CustomerWarnings_CreatedBy] DEFAULT ('admin') NOT NULL,
    [UpdatedBy]          VARCHAR (256) CONSTRAINT [CustomerWarnings_UpdatedBy] DEFAULT ('admin') NOT NULL,
    [CreatedDate]        DATETIME2 (7) CONSTRAINT [CustomerWarnings_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]        DATETIME2 (7) CONSTRAINT [CustomerWarnings_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]           BIT           CONSTRAINT [CustomerWarnings_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT           CONSTRAINT [CustomerWarnings_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CustomerWarnings] PRIMARY KEY CLUSTERED ([CustomerWarningsId] ASC),
    CONSTRAINT [FK_CustomerWarnings_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CustomerWarnings_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UC_CustomerWarnings_CustomerId] UNIQUE NONCLUSTERED ([CustomerId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_CustomerWarningsAudit]

   ON  [dbo].[CustomerWarnings]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO CustomerWarningsAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END