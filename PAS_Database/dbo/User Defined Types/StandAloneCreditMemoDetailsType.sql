CREATE TYPE [dbo].[StandAloneCreditMemoDetailsType] AS TABLE (
    [StandAloneCreditMemoDetailId]  BIGINT          NULL,
    [CreditMemoHeaderId]            BIGINT          NULL,
    [GlAccountId]                   BIGINT          NOT NULL,
    [Reason]                        VARCHAR (MAX)   NOT NULL,
    [Qty]                           DECIMAL (18, 6) NOT NULL,
    [Rate]                          DECIMAL (18, 6) NOT NULL,
    [Amount]                        DECIMAL (18, 6) NOT NULL,
    [IsDeleted]                     BIT             NOT NULL,
    [ManagementStructureId]         BIGINT          NULL,
    [LastMSLevel]                   VARCHAR (256)   NULL,
    [AllMSlevels]                   VARCHAR (256)   NULL,
    [CustomerCreditPaymentDetailId] BIGINT          NULL);

