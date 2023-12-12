CREATE TABLE [dbo].[POStatus] (
    [POStatusId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (MAX)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [POStatus_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [POStatus_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [POStatuss_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [POStatuss_DC_Delete] DEFAULT ((0)) NOT NULL,
    [Status]          VARCHAR (256)  NOT NULL,
    [SequenceNo]      INT            NULL,
    CONSTRAINT [PK_POStatus] PRIMARY KEY CLUSTERED ([POStatusId] ASC),
    CONSTRAINT [Unique_POStatus] UNIQUE NONCLUSTERED ([Status] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_POStatusAudit]

   ON  [dbo].[POStatus]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO POStatusAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END