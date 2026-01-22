CREATE TABLE [dbo].[MROPriceMasterAudit] (
    [MROPriceMasterAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [MROPriceMasterId]      BIGINT          NOT NULL,
    [ItemMasterId]          BIGINT          NOT NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CustomerId]            BIGINT          NULL,
    [WorkscopeId]           BIGINT          NOT NULL,
    [FlatRatePrice]         DECIMAL (18, 2) NOT NULL,
    [CurrencyId]            INT             NOT NULL,
    [StartDate]             DATETIME2 (7)   NOT NULL,
    [CreatedBy]             VARCHAR (50)    NOT NULL,
    [CreatedDate]           DATETIME2 (7)   NOT NULL,
    [UpdatedBy]             VARCHAR (50)    NOT NULL,
    [UpdatedDate]           DATETIME2 (7)   NOT NULL,
    [IsActive]              BIT             NOT NULL,
    [IsDeleted]             BIT             NOT NULL,
    [EndDate]               DATETIME2 (7)   NULL,
    CONSTRAINT [PK_MROPriceMasterAudit] PRIMARY KEY CLUSTERED ([MROPriceMasterAuditId] ASC),
    CONSTRAINT [FK_MROPriceMasterAudit_MROPriceMaster] FOREIGN KEY ([MROPriceMasterId]) REFERENCES [dbo].[MROPriceMaster] ([MROPriceMasterId])
);

