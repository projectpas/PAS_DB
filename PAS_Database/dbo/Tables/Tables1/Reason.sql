CREATE TABLE [dbo].[Reason] (
    [ReasonId]         BIGINT         IDENTITY (1, 1) NOT NULL,
    [ReasonCode]       VARCHAR (30)   NOT NULL,
    [ReasonForRemoval] VARCHAR (256)  NOT NULL,
    [Memo]             NVARCHAR (MAX) NULL,
    [MasterCompanyId]  INT            NOT NULL,
    [CreatedBy]        VARCHAR (256)  NOT NULL,
    [UpdatedBy]        VARCHAR (256)  NOT NULL,
    [CreatedDate]      DATETIME2 (7)  CONSTRAINT [Reason_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]      DATETIME2 (7)  CONSTRAINT [Reason_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]         BIT            CONSTRAINT [Reason_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]        BIT            CONSTRAINT [Reason_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Reason] PRIMARY KEY CLUSTERED ([ReasonId] ASC),
    CONSTRAINT [FK_Reason_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_Reason] UNIQUE NONCLUSTERED ([ReasonCode] ASC, [MasterCompanyId] ASC)
);


GO




-- =============================================

CREATE TRIGGER [dbo].[Trg_Reason]

   ON  [dbo].[Reason]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN



INSERT INTO ReasonAudit

SELECT * FROM INSERTED



SET NOCOUNT ON;



END