CREATE TABLE [dbo].[CreditCardPayment] (
    [CreditCardPaymentId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerId]          BIGINT        NOT NULL,
    [CustomerFinancialId] BIGINT        NOT NULL,
    [PaymentMethodId]     BIGINT        NOT NULL,
    [CardNumber]          VARCHAR (100) NULL,
    [CardHolderName]      VARCHAR (100) NULL,
    [Address]             VARCHAR (250) NULL,
    [State]               VARCHAR (100) NULL,
    [PostalCode]          VARCHAR (100) NULL,
    [InActive]            BIT           NOT NULL,
    [IsDefault]           BIT           NOT NULL,
    [ExpirationDate]      DATETIME2 (7) NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [CreatedDate]         DATETIME2 (7) CONSTRAINT [DF_CreditCardPayment_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) CONSTRAINT [DF_CreditCardPayment_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]            BIT           CONSTRAINT [DF_CreditCardPayment_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT           CONSTRAINT [DF_CreditCardPayment_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CreditCardPayment] PRIMARY KEY CLUSTERED ([CreditCardPaymentId] ASC),
    CONSTRAINT [FK_CreditCardPayment_customerFinancialId] FOREIGN KEY ([CustomerFinancialId]) REFERENCES [dbo].[CustomerFinancial] ([CustomerFinancialId]),
    CONSTRAINT [FK_CreditCardPayment_customerId] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId])
);




GO
/****************************   
** Author:  Devendra Shekh
** Create date:  25-08-2023
** Description: this trigger is used to insert data into [CreditCardPaymentAudit]
  
EXEC [Trg_CreditCardPaymentAudit] 
******** 
** Change History 
********   
** PR   Date			Author				  Change Description  
** --   --------		-------				--------------------------------
** 1    21-07-2023      Devendra Shekh          created
 
****************************/
CREATE   TRIGGER [dbo].[Trg_CreditCardPaymentAudit]

   ON  [dbo].[CreditCardPayment]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[CreditCardPaymentAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END
GO
   
     CREATE     TRIGGER [dbo].[trg_Audit_dbo_CreditCardPayment]
        ON [dbo].[CreditCardPayment]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[CreditCardPaymentId],d.[CustomerId],d.[CustomerFinancialId],d.[PaymentMethodId],d.[CardNumber],d.[CardHolderName],d.[Address],d.[State],d.[PostalCode],d.[InActive],d.[IsDefault],d.[ExpirationDate],d.[MasterCompanyId],d.[CreatedBy],d.[CreatedDate],d.[UpdatedBy],d.[UpdatedDate],d.[IsActive],d.[IsDeleted] FROM deleted d),
            i AS (SELECT i.[CreditCardPaymentId],i.[CustomerId],i.[CustomerFinancialId],i.[PaymentMethodId],i.[CardNumber],i.[CardHolderName],i.[Address],i.[State],i.[PostalCode],i.[InActive],i.[IsDefault],i.[ExpirationDate],i.[MasterCompanyId],i.[CreatedBy],i.[CreatedDate],i.[UpdatedBy],i.[UpdatedDate],i.[IsActive],i.[IsDeleted] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.CreditCardPaymentId, d.CreditCardPaymentId ) AS CreditCardPaymentId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.CreditCardPaymentId IS NOT NULL AND d.CreditCardPaymentId IS NOT NULL THEN 'U'
                        WHEN i.CreditCardPaymentId IS NOT NULL AND d.CreditCardPaymentId IS NULL     THEN 'I'
                        WHEN i.CreditCardPaymentId IS NULL     AND d.CreditCardPaymentId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.CreditCardPaymentId, d.CreditCardPaymentId) AS CreditCardPaymentId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.CreditCardPaymentId = d.CreditCardPaymentId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.CreditCardPaymentId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'CreditCardPayment'
                      AND ign.ColumnName = N'CreditCardPaymentId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.CreditCardPaymentId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'CreditCardPayment'
                      AND ign.ColumnName = N'CreditCardPaymentId'
                )),
            merged AS (
                SELECT
                    COALESCE(n.PKJson, o.PKJson)                AS PKJson,
                    COALESCE(n.ColumnName, o.ColumnName)        AS ColumnName,
                    o.OldValue,
                    n.NewValue,
                    p.Action
                FROM paired p
                LEFT JOIN oldv o
                    ON o.CreditCardPaymentId = p.CreditCardPaymentId
                LEFT JOIN newv n
                    ON n.CreditCardPaymentId = p.CreditCardPaymentId
                   AND n.ColumnName = o.ColumnName
                UNION ALL
                SELECT
                    n.PKJson,
                    n.ColumnName,
                    NULL AS OldValue,
                    n.NewValue,
                    p.Action
                FROM paired p
                LEFT JOIN newv n
                    ON n.CreditCardPaymentId = p.CreditCardPaymentId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.CreditCardPaymentId = p.CreditCardPaymentId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'CreditCardPayment' AS TableName,
                m.PKJson,
                m.ColumnName,
                m.Action,
                m.OldValue,
                m.NewValue
            FROM merged m
            WHERE
                m.ColumnName <> '<Enter your PrimaryKEY>' and (
                (m.Action = 'U' AND (
                     (m.OldValue IS NULL AND m.NewValue IS NOT NULL)
                  OR (m.OldValue IS NOT NULL AND m.NewValue IS NULL)
                  OR (m.OldValue <> m.NewValue)
                ))
                OR
                (m.Action = 'I' AND m.NewValue IS NOT NULL)
                OR
                (m.Action = 'D' AND m.OldValue IS NOT NULL));
        END;