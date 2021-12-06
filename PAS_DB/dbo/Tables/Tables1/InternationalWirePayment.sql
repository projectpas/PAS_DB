CREATE TABLE [dbo].[InternationalWirePayment] (
    [InternationalWirePaymentId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [SwiftCode]                  VARCHAR (50)  NULL,
    [BeneficiaryBankAccount]     VARCHAR (50)  NULL,
    [BeneficiaryBank]            VARCHAR (100) NULL,
    [BankName]                   VARCHAR (100) NULL,
    [IntermediaryBank]           VARCHAR (100) NULL,
    [BankAddressId]              BIGINT        NULL,
    [BeneficiaryCustomer]        VARCHAR (100) NULL,
    [MasterCompanyId]            INT           NOT NULL,
    [CreatedBy]                  VARCHAR (256) NOT NULL,
    [UpdatedBy]                  VARCHAR (256) NOT NULL,
    [CreatedDate]                DATETIME2 (7) NOT NULL,
    [UpdatedDate]                DATETIME2 (7) NOT NULL,
    [IsActive]                   BIT           NOT NULL,
    [IsDeleted]                  BIT           CONSTRAINT [InternationalwirePayment_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ABA]                        VARCHAR (256) NULL,
    [BeneficiaryCustomerId]      BIGINT        NULL,
    [BankLocation1]              VARCHAR (250) NULL,
    [BankLocation2]              VARCHAR (250) NULL,
    [GLAccountId]                BIGINT        NULL,
    CONSTRAINT [PK_InternationalWirePayment] PRIMARY KEY CLUSTERED ([InternationalWirePaymentId] ASC),
    CONSTRAINT [FK_InternationalWirePayment_Address] FOREIGN KEY ([BankAddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_InternationalWirePayment_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO


CREATE TRIGGER [dbo].[trig_Delete_InternationalWirePayment]

ON [dbo].[InternationalWirePayment]

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

	Select 'InternationalWirePayment',d.InternationalWirePaymentId,'SwiftCode',d.SwiftCode,'',GETDATE(),d.UpdatedBy,d.MasterCompanyId

    from deleted d



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePayment',d.InternationalWirePaymentId,'BeneficiaryBankAccount',d.BeneficiaryBankAccount,'',GETDATE(),d.UpdatedBy,d.MasterCompanyId

    from deleted d



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePayment',d.InternationalWirePaymentId,'BeneficiaryBank',d.BeneficiaryBank,'',GETDATE(),d.UpdatedBy,d.MasterCompanyId

    from deleted d



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePayment',d.InternationalWirePaymentId,'BankAddressId',d.BankAddressId,'',GETDATE(),d.UpdatedBy,d.MasterCompanyId

    from deleted d

   

   Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePayment',d.InternationalWirePaymentId,'BeneficiaryCustomer',d.BeneficiaryCustomer,'',GETDATE(),d.UpdatedBy,d.MasterCompanyId

    from deleted d



End
GO


CREATE TRIGGER [dbo].[trig_Update_InternationalWirePayment]

ON [dbo].[InternationalWirePayment]

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

	Select 'InternationalWirePayment',i.InternationalWirePaymentId,'SwiftCode',d.SwiftCode,i.SwiftCode,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i, deleted d



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePayment',i.InternationalWirePaymentId,'BeneficiaryBankAccount',d.BeneficiaryBankAccount,i.BeneficiaryBankAccount,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i, deleted d



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePayment',i.InternationalWirePaymentId,'BeneficiaryBank',d.BeneficiaryBank,i.BeneficiaryBank,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i, deleted d



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePayment',i.InternationalWirePaymentId,'BankAddressId',d.BankAddressId,i.BankAddressId,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i, deleted d

   

   Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePayment',i.InternationalWirePaymentId,'BeneficiaryCustomer',d.BeneficiaryCustomer,i.BeneficiaryCustomer,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i, deleted d



End
GO


CREATE TRIGGER [dbo].[trig_Insert_InternationalWirePayment]

ON [dbo].[InternationalWirePayment]

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

	Select 'InternationalWirePayment',InternationalWirePaymentId,'SwiftCode','',i.SwiftCode,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePayment',InternationalWirePaymentId,'BeneficiaryBankAccount','',i.BeneficiaryBankAccount,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePayment',InternationalWirePaymentId,'BeneficiaryBank','',i.BeneficiaryBank,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePayment',InternationalWirePaymentId,'BankAddressId','',i.BankAddressId,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i

   

   Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePayment',InternationalWirePaymentId,'BeneficiaryCustomer','',i.BeneficiaryCustomer,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i



End
GO


Create TRIGGER [dbo].[Trg_InternationalWirePaymentAudit] ON [dbo].[InternationalWirePayment]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  

  

 INSERT INTO [dbo].[InternationalWirePaymentAudit]

 SELECT * FROM INSERTED  

  

 SET NOCOUNT ON;  

  

END