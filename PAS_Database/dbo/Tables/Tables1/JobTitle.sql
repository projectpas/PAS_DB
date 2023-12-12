CREATE TABLE [dbo].[JobTitle] (
    [JobTitleId]      SMALLINT       IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (30)   NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [JobTitle_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [JobTitle_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [JobTitle_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [JobTitle_DC_Delete] DEFAULT ((0)) NOT NULL,
    [JobTitleCode]    VARCHAR (50)   NULL,
    CONSTRAINT [PK_JobTitle] PRIMARY KEY CLUSTERED ([JobTitleId] ASC),
    CONSTRAINT [FK_JobTitle_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UQ_JobTitle_codes] UNIQUE NONCLUSTERED ([Description] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[trig_delete_JobTitle]

ON [dbo].[JobTitle]

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

	Select 'JobTitle',JobTitleId,'Description',[Description],'',GETDATE(),UpdatedBy,MasterCompanyId

    from deleted 



	Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'JobTitle',JobTitleId,'Memo',Memo,'',GETDATE(),UpdatedBy,MasterCompanyId

    from deleted 

    

End
GO




CREATE TRIGGER [dbo].[Trg_JobTitleAudit] ON [dbo].[JobTitle]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  

  

 INSERT INTO [dbo].[JobTitleAudit]  

 SELECT * FROM INSERTED  

  

 SET NOCOUNT ON;  

  

END
GO




CREATE TRIGGER [dbo].[trig_Update_JobTitle]

ON [dbo].[JobTitle]

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

	Select 'JobTitle',i.JobTitleId,'Description',d.[Description],i.[Description],GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i,deleted d



	  Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'JobTitle',i.JobTitleId,'Memo',d.Memo,i.Memo,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i,deleted d

    

End
GO




CREATE TRIGGER [dbo].[trig_Insert_JobTitle]

ON [dbo].[JobTitle]

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

	Select 'JobTitle',JobTitleId,'Description','',i.[Description],GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i



	    Insert into AuditHistory([TableName]

		   ,[TableRecordId]

           ,[ColumnName]

           ,[PreviousValue]

           ,[NewValue]

           ,[UpdatedDate]

           ,[UpdatedBy]

           ,[MasterCompanyId])

	Select 'JobTitle',JobTitleId,'Memo','',i.Memo,GETDATE(),i.UpdatedBy,i.MasterCompanyId

    from inserted i

    

End