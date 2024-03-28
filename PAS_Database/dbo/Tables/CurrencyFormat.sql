CREATE TABLE [dbo].[CurrencyFormat] (
    [CurrencyFormatId] INT            IDENTITY (1, 1) NOT NULL,
    [Code]             VARCHAR (10)   NOT NULL,
    [Symbol]           VARCHAR (10)   NOT NULL,
    [DisplayName]      VARCHAR (20)   NOT NULL,
    [Memo]             NVARCHAR (MAX) NULL,
    [MasterCompanyId]  INT            NOT NULL,
    [CreatedBy]        VARCHAR (256)  NOT NULL,
    [UpdatedBy]        VARCHAR (256)  NOT NULL,
    [CreatedDate]      DATETIME2 (7)  CONSTRAINT [DF_CurrencyFormat_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]      DATETIME2 (7)  CONSTRAINT [DF_CurrencyFormat_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]         BIT            CONSTRAINT [D_CurrencyFormat_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]        BIT            CONSTRAINT [D_CurrencyFormat_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CurrencyFormat] PRIMARY KEY CLUSTERED ([CurrencyFormatId] ASC)
);

