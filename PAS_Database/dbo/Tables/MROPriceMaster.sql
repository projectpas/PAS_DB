CREATE TABLE [dbo].[MROPriceMaster] (
    [MROPriceMasterId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ItemMasterId]     BIGINT          NOT NULL,
    [MasterCompanyId]  INT             NOT NULL,
    [CustomerId]       BIGINT          NULL,
    [WorkscopeId]      BIGINT          NOT NULL,
    [FlatRatePrice]    DECIMAL (18, 6) NOT NULL,
    [CurrencyId]       INT             NOT NULL,
    [StartDate]        DATETIME2 (7)   NOT NULL,
    [CreatedBy]        VARCHAR (50)    NOT NULL,
    [CreatedDate]      DATETIME2 (7)   CONSTRAINT [DF_MROPriceMaster_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]        VARCHAR (50)    NOT NULL,
    [UpdatedDate]      DATETIME2 (7)   CONSTRAINT [DF_MROPriceMaster_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]         BIT             CONSTRAINT [DF__MROPriceMaster__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]        BIT             CONSTRAINT [DF__MROPriceMaster__IsDeleted] DEFAULT ((0)) NOT NULL,
    [EndDate]          DATETIME2 (7)   NULL,
    [EffectiveDate]    DATETIME2 (7)   NULL,
    CONSTRAINT [PK_MROPriceMaster] PRIMARY KEY CLUSTERED ([MROPriceMasterId] ASC),
    CONSTRAINT [FK_MROPriceMaster_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_MROPriceMaster_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_MROPriceMaster_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_MROPriceMaster_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_MROPriceMaster_WorkScope] FOREIGN KEY ([WorkscopeId]) REFERENCES [dbo].[WorkScope] ([WorkScopeId]),
    CONSTRAINT [Unique_MROPriceMaster] UNIQUE NONCLUSTERED ([ItemMasterId] ASC, [CustomerId] ASC, [MasterCompanyId] ASC, [WorkscopeId] ASC, [IsDeleted] ASC)
);




GO


CREATE TRIGGER [dbo].[Trg_MROPriceMasterAudit]

   ON  [dbo].[MROPriceMaster]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[MROPriceMasterAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END