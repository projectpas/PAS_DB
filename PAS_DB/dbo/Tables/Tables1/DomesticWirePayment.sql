CREATE TABLE [dbo].[DomesticWirePayment] (
    [DomesticWirePaymentId]   BIGINT        IDENTITY (1, 1) NOT NULL,
    [ABA]                     VARCHAR (50)  NOT NULL,
    [AccountNumber]           VARCHAR (50)  NOT NULL,
    [BankName]                VARCHAR (100) NOT NULL,
    [BenificiaryBankName]     VARCHAR (100) NULL,
    [IntermediaryBankName]    VARCHAR (100) NULL,
    [BankAddressId]           BIGINT        NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [DF_DomesticWirePayment_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [DF_DomesticWirePayment_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]                BIT           CONSTRAINT [DF_DomesticWirePayment_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           CONSTRAINT [DF_DomesticWirePayment_IsDeleted] DEFAULT ((0)) NOT NULL,
    [AccountNameId]           BIGINT        NULL,
    [VendorBankAccountTypeId] INT           NULL,
    CONSTRAINT [PK_DomesticWirePaymentId] PRIMARY KEY CLUSTERED ([DomesticWirePaymentId] ASC),
    CONSTRAINT [FK_DomesticWirePaymentId_Address] FOREIGN KEY ([BankAddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_DomesticWirePaymentId_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO


CREATE TRIGGER [dbo].[trig_Insert_DomesticWirePayment]

ON [dbo].[DomesticWirePayment]

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

	Select 'DomesticWirePayment',DomesticWirePaymentId,'ABA','',i.ABA,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'DomesticWirePayment',DomesticWirePaymentId,'AccountNumber','',i.AccountNumber,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'DomesticWirePayment',DomesticWirePaymentId,'BankName','',i.BankName,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'DomesticWirePayment',DomesticWirePaymentId,'BankAddressId','',i.BankAddressId,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i



End
GO


CREATE TRIGGER [dbo].[trig_Update_DomesticWirePayment]

ON [dbo].[DomesticWirePayment]

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

	Select 'DomesticWirePayment',i.DomesticWirePaymentId,'ABA',d.ABA,i.ABA,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i, deleted d



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'DomesticWirePayment',i.DomesticWirePaymentId,'AccountNumber',d.AccountNumber,i.AccountNumber,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i, deleted d



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'DomesticWirePayment',i.DomesticWirePaymentId,'BankName',d.BankName,i.BankName,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i, deleted d



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'DomesticWirePayment',i.DomesticWirePaymentId,'BankAddressId',d.BankAddressId,i.BankAddressId,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i, deleted d



End
GO






Create TRIGGER [dbo].[Trg_DomesticWirePaymentAudit] ON [dbo].[DomesticWirePayment]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  

  

 INSERT INTO [dbo].[DomesticWirePaymentAudit]

 SELECT * FROM INSERTED  

  

 SET NOCOUNT ON;  

  

END
GO


CREATE TRIGGER [dbo].[trig_Delete_DomesticWirePayment]

ON [dbo].[DomesticWirePayment]

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

	Select 'DomesticWirePayment',d.DomesticWirePaymentId,'ABA',d.ABA,'',GETDATE(),d.UpdatedBy,d.MasterCompanyId

    from deleted d



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'DomesticWirePayment',d.DomesticWirePaymentId,'AccountNumber',d.AccountNumber,'',GETDATE(),d.UpdatedBy,d.MasterCompanyId

    from deleted d



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'DomesticWirePayment',d.DomesticWirePaymentId,'BankName',d.BankName,'',GETDATE(),d.UpdatedBy,d.MasterCompanyId

    from deleted d



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'DomesticWirePayment',d.DomesticWirePaymentId,'BankAddressId',d.BankAddressId,'',GETDATE(),d.UpdatedBy,d.MasterCompanyId

    from deleted d



End