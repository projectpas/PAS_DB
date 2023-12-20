CREATE TABLE [dbo].[Percent] (
    [PercentId]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [PercentValue]    DECIMAL (18, 2) NOT NULL,
    [MasterCompanyId] INT             NOT NULL,
    [CreatedBy]       NVARCHAR (256)  NOT NULL,
    [UpdatedBy]       NVARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)   CONSTRAINT [DF_Percent_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)   CONSTRAINT [DF_Percent_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT             DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT             DEFAULT ((0)) NOT NULL,
    [Memo]            NVARCHAR (MAX)  NULL,
    [Description]     VARCHAR (500)   NULL,
    CONSTRAINT [PK__Percent__E43F6D963F493CDE] PRIMARY KEY CLUSTERED ([PercentId] ASC),
    CONSTRAINT [FK_Percent_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_Percent] UNIQUE NONCLUSTERED ([PercentValue] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_PercentAudit]

   ON  [dbo].[Percent]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO PercentAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END