CREATE TABLE [dbo].[IntegrationEmailProcessHistory] (
    [IntegrationEmailProcessHistoryId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [IntegrationEmailID]               BIGINT          NOT NULL,
    [EmailStatusId]                    INT             NULL,
    [ErrorMessage]                     NVARCHAR (1000) NULL,
    [RfqType]                          VARCHAR (50)    NULL,
    [ExtractedData]                    NVARCHAR (MAX)  NULL,
    [AttemptCount]                     INT             NULL,
    [ProcessSource]                    VARCHAR (50)    NOT NULL,
    [MasterCompanyId]                  INT             NOT NULL,
    [CreatedBy]                        VARCHAR (256)   NOT NULL,
    [CreatedDate]                      DATETIME2 (7)   CONSTRAINT [DF_IntegrationEmailProcessHistory_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_IntegrationEmailProcessHistory] PRIMARY KEY CLUSTERED ([IntegrationEmailProcessHistoryId] ASC),
    CONSTRAINT [FK_IntegrationEmailProcessHistory_IntegrationEmail] FOREIGN KEY ([IntegrationEmailID]) REFERENCES [dbo].[IntegrationEmail] ([IntegrationEmailID])
);
GO

CREATE NONCLUSTERED INDEX [IX_IntegrationEmailProcessHistory_IntegrationEmailID]
    ON [dbo].[IntegrationEmailProcessHistory]([IntegrationEmailID] ASC);
