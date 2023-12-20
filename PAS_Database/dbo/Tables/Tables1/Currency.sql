CREATE TABLE [dbo].[Currency] (
    [CurrencyId]      INT            IDENTITY (1, 1) NOT NULL,
    [Code]            VARCHAR (10)   NOT NULL,
    [Symbol]          VARCHAR (10)   NOT NULL,
    [DisplayName]     VARCHAR (20)   NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Currency_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Currency_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [D_Currency_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [D_Currency_Delete] DEFAULT ((0)) NOT NULL,
    [CountryId]       SMALLINT       NOT NULL,
    CONSTRAINT [PK__Currency__A25C5AA686726683] PRIMARY KEY CLUSTERED ([CurrencyId] ASC),
    CONSTRAINT [FK_Currency_Country] FOREIGN KEY ([CountryId]) REFERENCES [dbo].[Countries] ([countries_id]),
    CONSTRAINT [FK_Currency_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_CurrencyName] UNIQUE NONCLUSTERED ([DisplayName] ASC, [MasterCompanyId] ASC),
    CONSTRAINT [UQ_Currency_codes] UNIQUE NONCLUSTERED ([Code] ASC, [MasterCompanyId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_Currency]
    ON [dbo].[Currency]([CurrencyId] ASC);


GO




CREATE TRIGGER [dbo].[Trg_CurrencyAudit]

   ON  [dbo].[Currency]

   AFTER INSERT,UPDATE

AS 

BEGIN



	DECLARE @CountryId BIGINT

	DECLARE @Country VARCHAR(100)



	SELECT @CountryId=CountryId FROM INSERTED

	SELECT @Country=nice_name FROM Countries WHERE countries_id=@CountryId



	INSERT INTO [dbo].[CurrencyAudit]

	SELECT *,@Country FROM INSERTED



	SET NOCOUNT ON;



END
GO




CREATE TRIGGER [dbo].[trig_delete_Currency]

ON [dbo].[Currency]

FOR delete

AS

Begin

    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'Currency',CurrencyId,'Code',[Code],'',GETDATE(),UpdatedBy,MasterCompanyId

    from deleted 



	Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'Currency',CurrencyId,'Symbol',[Symbol],'',GETDATE(),UpdatedBy,MasterCompanyId

    from deleted 

    

		Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'Currency',CurrencyId,'DisplayName',[DisplayName],'',GETDATE(),UpdatedBy,MasterCompanyId

    from deleted 

	--

			Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'Currency',CurrencyId,'Memo',Memo,'',GETDATE(),UpdatedBy,MasterCompanyId

    from deleted 

			

End
GO




CREATE TRIGGER [dbo].[trig_Update_Currency]

ON [dbo].[Currency]

FOR update

AS

Begin

    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'Currency',i.CurrencyId,'Code',d.[Code],i.[Code],GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i,deleted d



	Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'Currency',i.CurrencyId,'Symbol',d.[Symbol],i.[Symbol],GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i,deleted d



	Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'Currency',i.CurrencyId,'DisplayName',d.[DisplayName],i.[DisplayName],GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i,deleted d



	--FunctionalCurrencyId

    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'Currency',i.CurrencyId,'Memo',d.Memo,i.Memo,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i,deleted d





End
GO




CREATE TRIGGER [dbo].[trig_Insert_Currency]

ON [dbo].[Currency]

FOR insert

AS

Begin

    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'Currency',CurrencyId,'Code','',i.[Code],GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i

    

	Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'Currency',CurrencyId,'Symbol','',i.[Symbol],GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i



		Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'Currency',CurrencyId,'DisplayName','',i.[DisplayName],GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i



	Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'Currency',CurrencyId,'Memo','',i.Memo,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i

End