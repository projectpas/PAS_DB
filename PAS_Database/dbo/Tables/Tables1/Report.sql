CREATE TABLE [dbo].[Report] (
    [ReportId]        BIGINT         IDENTITY (1, 1) NOT NULL,
    [ReportName]      VARCHAR (256)  NOT NULL,
    [Description]     VARCHAR (MAX)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [Report_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [Report_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [Report_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [Report_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Report] PRIMARY KEY CLUSTERED ([ReportId] ASC),
    CONSTRAINT [FK_Report_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_Report] UNIQUE NONCLUSTERED ([ReportName] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_ReportAudit]

   ON  [dbo].[Report]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN



INSERT INTO ReportAudit

SELECT * FROM INSERTED



SET NOCOUNT ON;



END