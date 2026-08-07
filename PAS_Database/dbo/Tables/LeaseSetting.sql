CREATE TABLE [dbo].[LeaseSetting] (
    [LeaseSettingId]          INT            IDENTITY (1, 1) NOT NULL,
    [MasterCompanyId]         INT            NOT NULL,
    [FlatRateGLAccountId]     INT            NULL,
    [OverageCycleGLAccountId] INT            NULL,
    [OverageTimeGLAccountId]  INT            NULL,
    [UsageBasedGLAccountId]   INT            NULL,
    [CreatedBy]               NVARCHAR (100) NULL,
    [CreatedDate]             DATETIME       NULL,
    [UpdatedBy]               NVARCHAR (100) NULL,
    [UpdatedDate]             DATETIME       NULL,
    [IsActive]                BIT            DEFAULT ((1)) NULL,
    [IsDeleted]               BIT            DEFAULT ((0)) NULL,
    PRIMARY KEY CLUSTERED ([LeaseSettingId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_LeaseSetting_MasterCompanyId]
    ON [dbo].[LeaseSetting]([MasterCompanyId] ASC) WHERE ([IsDeleted]=(0));

