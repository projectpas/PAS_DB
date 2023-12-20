CREATE TABLE [dbo].[MasterSalesOrderStatus] (
    [Id]                INT           NOT NULL,
    [Name]              VARCHAR (50)  NOT NULL,
    [Description]       VARCHAR (250) NULL,
    [DisplayInDropdown] BIT           NULL,
    [MasterCompanyId]   INT           NOT NULL,
    [CreatedBy]         VARCHAR (50)  NOT NULL,
    [CreatedOn]         DATETIME      NOT NULL,
    [UpdatedBy]         VARCHAR (50)  NULL,
    [UpdatedOn]         DATETIME      NULL,
    [IsActive]          BIT           NOT NULL,
    [IsDeleted]         BIT           NOT NULL,
    CONSTRAINT [PK_MasterSalesOrderStatus] PRIMARY KEY CLUSTERED ([Id] ASC)
);

