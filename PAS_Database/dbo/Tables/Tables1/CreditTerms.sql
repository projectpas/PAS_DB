﻿CREATE TABLE [dbo].[CreditTerms] (
    [CreditTermsId]   INT             IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (30)    NOT NULL,
    [PercentId]       DECIMAL (18, 2) NOT NULL,
    [Days]            TINYINT         NOT NULL,
    [NetDays]         TINYINT         NOT NULL,
    [Memo]            NVARCHAR (MAX)  NULL,
    [MasterCompanyId] INT             NOT NULL,
    [CreatedBy]       VARCHAR (256)   NOT NULL,
    [UpdatedBy]       VARCHAR (256)   NOT NULL,
    [CreatedDate]     DATETIME2 (7)   CONSTRAINT [DF_CreditTerms_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)   CONSTRAINT [DF_CreditTerms_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT             CONSTRAINT [DF_CreditTerms_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT             CONSTRAINT [DF_CreditTerms_IsDelete] DEFAULT ((0)) NOT NULL,
    [Code]            VARCHAR (50)    NULL,
    CONSTRAINT [PK_CreditTerm] PRIMARY KEY CLUSTERED ([CreditTermsId] ASC),
    CONSTRAINT [FK_CreditTerms_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_CreditTerms] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);




GO






-- =============================================

CREATE TRIGGER [dbo].[Trg_CreditTermsAudit]

   ON  [dbo].[CreditTerms]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[CreditTermsAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END