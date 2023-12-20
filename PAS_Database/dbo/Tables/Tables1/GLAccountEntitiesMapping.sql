CREATE TABLE [dbo].[GLAccountEntitiesMapping] (
    [GLAccountEntitiesMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [EntitiesId]                 BIGINT        NOT NULL,
    [GlAccountId]                BIGINT        NOT NULL,
    [CreatedBy]                  VARCHAR (256) NOT NULL,
    [UpdatedBy]                  VARCHAR (256) NOT NULL,
    [CreatedDate]                DATETIME2 (7) NOT NULL,
    [UpdatedDate]                DATETIME2 (7) NOT NULL,
    [IsActive]                   BIT           NOT NULL,
    [IsDeleted]                  BIT           NOT NULL,
    [MasterCompanyId]            INT           NULL,
    CONSTRAINT [PK_GLAccountEntitiesMapping] PRIMARY KEY CLUSTERED ([GLAccountEntitiesMappingId] ASC),
    CONSTRAINT [FK_GLAccountEntitiesMapping_GLAccount] FOREIGN KEY ([GlAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_GLAccountEntitiesMapping_MasterCompnay] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO








CREATE TRIGGER [dbo].[Trg_GLAccountEntitiesMappingAudit]

   ON  [dbo].[GLAccountEntitiesMapping]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN



INSERT INTO [dbo].[GLAccountEntitiesMappingAudit]

SELECT * FROM INSERTED



SET NOCOUNT ON;



END