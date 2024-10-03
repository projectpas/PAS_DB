CREATE TABLE [dbo].[GeneralLedgerEmployeeMapping] (
    [GeneralLedgerEmployeeMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [GeneralLedgerSearchParamsId]    BIGINT        NOT NULL,
    [EmployeeId]                     BIGINT        NULL,
    [MasterCompanyId]                INT           NOT NULL,
    [CreatedBy]                      VARCHAR (50)  NOT NULL,
    [CreatedDate]                    DATETIME2 (7) CONSTRAINT [DF_GeneralLedgerEmployeeMapping_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                      VARCHAR (50)  NOT NULL,
    [UpdatedDate]                    DATETIME2 (7) CONSTRAINT [DF_GeneralLedgerEmployeeMapping_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                       BIT           CONSTRAINT [DF__GeneralLedgerEmployeeMapping__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                      BIT           CONSTRAINT [DF__GeneralLedgerEmployeeMapping__IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_GeneralLedgerEmployeeMapping] PRIMARY KEY CLUSTERED ([GeneralLedgerEmployeeMappingId] ASC)
);

