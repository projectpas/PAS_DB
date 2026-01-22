CREATE TABLE [dbo].[CashReceiptEmployeeMapping] (
    [CashReceiptEmployeeMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CashReceiptSearchParamsId]    BIGINT        NOT NULL,
    [EmployeeId]                   BIGINT        NULL,
    [MasterCompanyId]              INT           NOT NULL,
    [CreatedBy]                    VARCHAR (256) NOT NULL,
    [CreatedDate]                  DATETIME2 (7) CONSTRAINT [DF_CashReceiptEmployeeMapping_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                    VARCHAR (256) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7) CONSTRAINT [DF_CashReceiptEmployeeMapping_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                     BIT           CONSTRAINT [DF_CashReceiptEmployeeMapping_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                    BIT           CONSTRAINT [DF_CashReceiptEmployeeMapping_IsDeleted] DEFAULT ((0)) NOT NULL
);

