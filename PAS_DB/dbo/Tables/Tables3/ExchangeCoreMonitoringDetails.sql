CREATE TABLE [dbo].[ExchangeCoreMonitoringDetails] (
    [ExchangeCoreMonitoringDetailsId] BIGINT       IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderId]            BIGINT       NULL,
    [LetterTypeId]                    INT          NULL,
    [LetterSentDate]                  DATETIME     NULL,
    [MasterCompanyId]                 INT          NOT NULL,
    [CreatedBy]                       VARCHAR (50) NOT NULL,
    [CreatedDate]                     DATETIME     CONSTRAINT [DF_ExchangeCoreMonitoringDetails_CreatedOn] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                       VARCHAR (50) NULL,
    [UpdatedDate]                     DATETIME     CONSTRAINT [DF_ExchangeCoreMonitoringDetails_UpdatedOn] DEFAULT (getdate()) NULL,
    [IsActive]                        BIT          CONSTRAINT [DF_ExchangeCoreMonitoringDetails_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                       BIT          CONSTRAINT [DF_ExchangeCoreMonitoringDetails_IsDeleted] DEFAULT ((0)) NOT NULL,
    [SequenceNo]                      INT          NULL,
    CONSTRAINT [PK_ExchangeCoreMonitoringDetails] PRIMARY KEY CLUSTERED ([ExchangeCoreMonitoringDetailsId] ASC)
);

