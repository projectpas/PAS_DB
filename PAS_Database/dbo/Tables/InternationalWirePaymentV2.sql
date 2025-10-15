CREATE TABLE [dbo].[InternationalWirePaymentV2] (
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
    [IsDeleted]                  BIT           CONSTRAINT [InternationalWirePaymentV2_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ABA]                        VARCHAR (256) NULL,
    [BeneficiaryCustomerId]      BIGINT        NULL,
    [BankLocation1]              VARCHAR (250) NULL,
    [BankLocation2]              VARCHAR (250) NULL,
    [GLAccountId]                BIGINT        NULL,
    [VendorBankAccountTypeId]    INT           NULL,
    CONSTRAINT [PK_InternationalWirePaymentV2] PRIMARY KEY CLUSTERED ([InternationalWirePaymentId] ASC),
    CONSTRAINT [FK_InternationalWirePaymentV2_Address] FOREIGN KEY ([BankAddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_InternationalWirePaymentV2_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO
CREATE TRIGGER [dbo].[trig_Update_InternationalWirePaymentV2]

ON [dbo].[InternationalWirePaymentV2]

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

	Select 'InternationalWirePaymentV2',i.InternationalWirePaymentId,'SwiftCode',d.SwiftCode,i.SwiftCode,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i, deleted d



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePaymentV2',i.InternationalWirePaymentId,'BeneficiaryBankAccount',d.BeneficiaryBankAccount,i.BeneficiaryBankAccount,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i, deleted d



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePaymentV2',i.InternationalWirePaymentId,'BeneficiaryBank',d.BeneficiaryBank,i.BeneficiaryBank,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i, deleted d



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePaymentV2',i.InternationalWirePaymentId,'BankAddressId',d.BankAddressId,i.BankAddressId,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i, deleted d

   

   Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePaymentV2',i.InternationalWirePaymentId,'BeneficiaryCustomer',d.BeneficiaryCustomer,i.BeneficiaryCustomer,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i, deleted d



End
GO
CREATE TRIGGER [dbo].[trig_Insert_InternationalWirePaymentV2]

ON [dbo].[InternationalWirePaymentV2]

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

	Select 'InternationalWirePaymentV2',InternationalWirePaymentId,'SwiftCode','',i.SwiftCode,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePaymentV2',InternationalWirePaymentId,'BeneficiaryBankAccount','',i.BeneficiaryBankAccount,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePaymentV2',InternationalWirePaymentId,'BeneficiaryBank','',i.BeneficiaryBank,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePaymentV2',InternationalWirePaymentId,'BankAddressId','',i.BankAddressId,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i

   

   Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePaymentV2',InternationalWirePaymentId,'BeneficiaryCustomer','',i.BeneficiaryCustomer,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i



End
GO
CREATE TRIGGER [dbo].[trig_Delete_InternationalWirePaymentV2]

ON [dbo].[InternationalWirePaymentV2]

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

	Select 'InternationalWirePaymentV2',d.InternationalWirePaymentId,'SwiftCode',d.SwiftCode,'',GETDATE(),d.UpdatedBy,d.MasterCompanyId

    from deleted d



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePaymentV2',d.InternationalWirePaymentId,'BeneficiaryBankAccount',d.BeneficiaryBankAccount,'',GETDATE(),d.UpdatedBy,d.MasterCompanyId

    from deleted d



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePaymentV2',d.InternationalWirePaymentId,'BeneficiaryBank',d.BeneficiaryBank,'',GETDATE(),d.UpdatedBy,d.MasterCompanyId

    from deleted d



    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePaymentV2',d.InternationalWirePaymentId,'BankAddressId',d.BankAddressId,'',GETDATE(),d.UpdatedBy,d.MasterCompanyId

    from deleted d

   

   Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'InternationalWirePaymentV2',d.InternationalWirePaymentId,'BeneficiaryCustomer',d.BeneficiaryCustomer,'',GETDATE(),d.UpdatedBy,d.MasterCompanyId

    from deleted d



End
GO



Create TRIGGER [dbo].[Trg_InternationalWirePaymentAuditV2] ON [dbo].[InternationalWirePaymentV2]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  

  

 INSERT INTO [dbo].[InternationalWirePaymentAuditV2]

 SELECT * FROM INSERTED  

  

 SET NOCOUNT ON;  

  

END