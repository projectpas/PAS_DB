CREATE TABLE [dbo].[TaxRate] (
    [TaxRateId]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [TaxRate]         NUMERIC (18, 2) NOT NULL,
    [Memo]            NVARCHAR (MAX)  NULL,
    [MasterCompanyId] INT             NOT NULL,
    [CreatedBy]       VARCHAR (256)   NOT NULL,
    [UpdatedBy]       VARCHAR (256)   NOT NULL,
    [CreatedDate]     DATETIME2 (7)   CONSTRAINT [TaxRate_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)   CONSTRAINT [TaxRate_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT             CONSTRAINT [TaxRate_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT             CONSTRAINT [TaxRate_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_TaxRate] PRIMARY KEY CLUSTERED ([TaxRateId] ASC),
    CONSTRAINT [FK_TaxRate_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_TaxRate] UNIQUE NONCLUSTERED ([TaxRate] ASC, [MasterCompanyId] ASC)
);


GO


CREATE Trigger [dbo].[trg_TaxRate]



on [dbo].[TaxRate]



 AFTER INSERT,UPDATE



As 



Begin 



 



SET NOCOUNT ON



INSERT INTO TaxRateAudit



SELECT * FROM INSERTED



 



End