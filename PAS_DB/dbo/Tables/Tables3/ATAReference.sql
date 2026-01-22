CREATE TABLE [dbo].[ATAReference] (
    [ATAReferenceId]  INT           IDENTITY (1, 1) NOT NULL,
    [ATAReference]    VARCHAR (256) NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [IsActive]        BIT           CONSTRAINT [ATAReference_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [ATAReference_DC_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [ATAReference_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [ATAReference_DC_UDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_ATAReference] PRIMARY KEY CLUSTERED ([ATAReferenceId] ASC),
    CONSTRAINT [FK_ATAReference_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO
CREATE   TRIGGER [dbo].[Trg_ATAReference]
   ON  [dbo].[ATAReference]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	INSERT INTO ATAReferenceAudit 
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END