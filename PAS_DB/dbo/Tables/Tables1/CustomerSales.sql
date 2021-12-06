CREATE TABLE [dbo].[CustomerSales] (
    [CustomerSalesId]        BIGINT          IDENTITY (1, 1) NOT NULL,
    [CustomerId]             BIGINT          NOT NULL,
    [PrimarySalesPersonId]   BIGINT          NOT NULL,
    [SecondarySalesPersonId] BIGINT          NULL,
    [CsrId]                  BIGINT          NULL,
    [SaId]                   BIGINT          NULL,
    [AnnualRevenuePotential] DECIMAL (16, 2) NOT NULL,
    [AnnualQuota]            DECIMAL (16, 2) NOT NULL,
    [MasterCompanyId]        INT             CONSTRAINT [CustomerSales_MasterCompanyId] DEFAULT ((1)) NOT NULL,
    [CreatedBy]              VARCHAR (256)   CONSTRAINT [CustomerSales_CreatedBy] DEFAULT ('admin') NOT NULL,
    [UpdatedBy]              VARCHAR (256)   CONSTRAINT [CustomerSales_UpdatedBy] DEFAULT ('admin') NOT NULL,
    [CreatedDate]            DATETIME2 (7)   CONSTRAINT [CustomerSales_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)   CONSTRAINT [CustomerSales_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT             CONSTRAINT [CustomerSales_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT             CONSTRAINT [CustomerSales_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CustomerSales] PRIMARY KEY CLUSTERED ([CustomerSalesId] ASC),
    CONSTRAINT [FK_CustomerSales_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CustomerSales_Employee_CsrId] FOREIGN KEY ([CsrId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_CustomerSales_Employee_PrimarySalesPersonId] FOREIGN KEY ([PrimarySalesPersonId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_CustomerSales_Employee_SaId] FOREIGN KEY ([SaId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_CustomerSales_Employee_SecondarySalesPersonId] FOREIGN KEY ([SecondarySalesPersonId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_CustomerSales_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UC_CustomerSales_CustomerId] UNIQUE NONCLUSTERED ([CustomerId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_CustomerSalesAudit]

   ON  [dbo].[CustomerSales]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO CustomerSalesAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END