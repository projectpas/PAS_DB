CREATE TABLE [dbo].[TeardownReason] (
    [TeardownReasonId]     BIGINT         IDENTITY (1, 1) NOT NULL,
    [Reason]               VARCHAR (1000) NOT NULL,
    [Memo]                 NVARCHAR (MAX) NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [CreatedDate]          DATETIME2 (7)  CONSTRAINT [TeardownReason_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  CONSTRAINT [TeardownReason_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT            CONSTRAINT [TeardwonReason_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT            CONSTRAINT [TeardwonReason_DC_Delete] DEFAULT ((0)) NOT NULL,
    [CommonTeardownTypeId] BIGINT         DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_TeardwonReason] PRIMARY KEY CLUSTERED ([TeardownReasonId] ASC),
    CONSTRAINT [FK_TeardwonReason_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UC_TeardwonReason] UNIQUE NONCLUSTERED ([Reason] ASC, [MasterCompanyId] ASC)
);




GO


CREATE TRIGGER [dbo].[Trg_TeardownReasonAudit]

   ON  [dbo].[TeardownReason]

   AFTER INSERT,UPDATE

AS 

BEGIN



	DECLARE @TeardownTypeId BIGINT,@TeardownType VARCHAR(256)



	SELECT @TeardownTypeId=CommonTeardownTypeId FROM INSERTED

	SELECT @TeardownType=Name FROM CommonTeardownType WHERE CommonTeardownTypeId=@TeardownTypeId

	INSERT INTO [dbo].[TeardownReasonAudit]

	SELECT *,@TeardownType FROM INSERTED

	SET NOCOUNT ON;



END