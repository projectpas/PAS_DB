CREATE TABLE [dbo].[ContactTag] (
    [ContactTagId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [TagName]         VARCHAR (100)  NOT NULL,
    [Description]     VARCHAR (500)  NULL,
    [SequenceNo]      INT            NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_ContactTag_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_ContactTag_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [ContactTag_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [ContactTag_IsDeleted] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId] INT            NULL,
    CONSTRAINT [PK_ContactTag] PRIMARY KEY CLUSTERED ([ContactTagId] ASC),
    CONSTRAINT [FK_ContactTag_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UC_ContactTag_TagName] UNIQUE NONCLUSTERED ([TagName] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_ContactTagAudit]

   ON  [dbo].[ContactTag]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO ContactTagAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END