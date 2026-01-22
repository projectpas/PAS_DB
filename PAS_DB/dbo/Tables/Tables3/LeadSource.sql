CREATE TABLE [dbo].[LeadSource] (
    [LeadSourceId]    INT            IDENTITY (1, 1) NOT NULL,
    [Description]     NVARCHAR (MAX) NULL,
    [LeadSources]     VARCHAR (50)   NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF__LeadSource_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_LeadSource_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [LeadSource_DC_Active] DEFAULT ((1)) NOT NULL,
    [MasterCompanyId] INT            NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [LeadSource_DC_Delete] DEFAULT ((0)) NOT NULL,
    [SequenceNo]      INT            NULL,
    CONSTRAINT [PK_LeadSource] PRIMARY KEY CLUSTERED ([LeadSourceId] ASC),
    CONSTRAINT [FK_LeadSource_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO


-------------------

CREATE TRIGGER [dbo].[Trg_LeadSourceAudit]

   ON  [dbo].[LeadSource]

   AFTER INSERT,UPDATE

AS

BEGIN



INSERT INTO [dbo].[LeadSourceAudit]

SELECT * FROM INSERTED



SET NOCOUNT ON;



END