CREATE TABLE [dbo].[VendorReadyToPayHeader] (
    [ReadyToPayId]          BIGINT          IDENTITY (1, 1) NOT NULL,
    [APGlAccountId]         VARCHAR (100)   NULL,
    [CashGLAccountId]       BIGINT          NULL,
    [BankId]                INT             NULL,
    [BankAccountId]         INT             NULL,
    [BankAccountNumber]     VARCHAR (50)    NULL,
    [OpenDate]              DATETIME        NULL,
    [AccountingPeriodId]    INT             NULL,
    [Balance]               DECIMAL (18, 2) NULL,
    [CumulativeAmount]      DECIMAL (18, 2) NULL,
    [ManagementStructureId] BIGINT          NULL,
    [MasterCompanyId]       INT             NULL,
    [CreatedBy]             VARCHAR (100)   NULL,
    [CreatedDate]           DATETIME        NULL,
    [UpdatedBy]             VARCHAR (100)   NULL,
    [UpdatedDate]           DATETIME        NULL,
    [IsActive]              BIT             CONSTRAINT [DF_VendorReadyToPayHeader_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT             CONSTRAINT [DF_VendorReadyToPayHeader_IsDeleted] DEFAULT ((0)) NOT NULL,
    [PrintCheck_Wire_Num]   VARCHAR (50)    NULL,
    [LegalEntityId]         BIGINT          NULL,
    CONSTRAINT [PK_VendorReadyToPayHeader] PRIMARY KEY CLUSTERED ([ReadyToPayId] ASC)
);



