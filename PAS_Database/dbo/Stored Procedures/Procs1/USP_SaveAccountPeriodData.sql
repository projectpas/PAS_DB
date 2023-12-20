
/*************************************************************           
 ** File:   [USP_Open_close_ledgerbyId]           
 ** Author: 
 ** Description: This stored procedure is used to populate Calendar Listing.    
 ** Purpose:         
 ** Date:   
          
 ** PARAMETERS:
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
	1    30/08/2022   subhash saliya Changes ledger id
    -- exec USP_Open_close_ledgerbyId 1,1,2022 
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_SaveAccountPeriodData]
@AccountingCalendarId bigint,
@periodName varchar(50),
@accounttabname  varchar(50),
@statusname varchar(50),
@UpdatedBy varchar(50)

AS
	BEGIN
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		SET NOCOUNT ON;
		DECLARE @RecordFrom int;
		Declare @IsActive bit = 1
		Declare @Count Int;
		Declare @PageSize Int =10

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN

				Declare @ReferenceId bigint,
                --@PeriodName varchar(30),
                @TableName varchar(100),
                @Status varchar(256),
                @LegalEntityId bigint,
                @LegalEntityName varchar(256),
                @ledgerId int,
                @ledgerName varchar(256),
                @CreatedBy varchar(256),
                @MasterCompanyId int

				select @MasterCompanyId = MasterCompanyId from AccountingCalendar WITH(NOLOCK)  where AccountingCalendarId=@AccountingCalendarId
				
				if(Upper(@accounttabname) =Upper('General Ledger'))
				begin
				
				     if(@statusname ='Close All')
				     begin
				        update AccountingCalendar set Status='Closed',isaccStatusName=0,isacpStatusName=0,isacrStatusName=0,isassetStatusName=0,isinventoryStatusName=0 where PeriodName=@periodName and MasterCompanyId= @MasterCompanyId
				     

					     INSERT INTO [dbo].[AccountingCalendarHistory]
                          ([ReferenceId],[PeriodName],[TableName],[StatusName],[LegalEntityId],[LegalEntityName],[ledgerId],[ledgerName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
                          select AccountingCalendarId,PeriodName,'Account Payable',(Case when Acc.isacpStatusName=1 then 'Open' else 'Closed' end),Acc.LegalEntityId,Le.Name,acc.ledgerId,Led.LedgerName,acc.MasterCompanyId,@UpdatedBy,@UpdatedBy,GETDATE(),GETDATE(),Acc.IsActive,Acc.IsDeleted 
						   	
						  from AccountingCalendar Acc WITH(NOLOCK)  
						  inner join LegalEntity Le WITH(NOLOCK) on le.LegalEntityId=Acc.LegalEntityId
						  inner join Ledger Led WITH(NOLOCK) on Led.LedgerId=Acc.LedgerId 
						  where PeriodName=@periodName and Acc.MasterCompanyId= @MasterCompanyId

						  INSERT INTO [dbo].[AccountingCalendarHistory]
                          ([ReferenceId],[PeriodName],[TableName],[StatusName],[LegalEntityId],[LegalEntityName],[ledgerId],[ledgerName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
                          select AccountingCalendarId,PeriodName,'Accounts Receivables',(Case when Acc.isacrStatusName=1 then 'Open' else 'Closed' end),Acc.LegalEntityId,Le.Name,acc.ledgerId,Led.LedgerName,acc.MasterCompanyId,@UpdatedBy,@UpdatedBy,GETDATE(),GETDATE(),Acc.IsActive,Acc.IsDeleted 
						   	
						  from AccountingCalendar Acc WITH(NOLOCK)  
						  inner join LegalEntity Le WITH(NOLOCK) on le.LegalEntityId=Acc.LegalEntityId
						  inner join Ledger Led WITH(NOLOCK) on Led.LedgerId=Acc.LedgerId 
						  where PeriodName=@periodName and Acc.MasterCompanyId= @MasterCompanyId

						  INSERT INTO [dbo].[AccountingCalendarHistory]
                          ([ReferenceId],[PeriodName],[TableName],[StatusName],[LegalEntityId],[LegalEntityName],[ledgerId],[ledgerName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
                          select AccountingCalendarId,PeriodName,'Inventory',(Case when Acc.isinventoryStatusName=1 then 'Open' else 'Closed' end),Acc.LegalEntityId,Le.Name,acc.ledgerId,Led.LedgerName,acc.MasterCompanyId,@UpdatedBy,@UpdatedBy,GETDATE(),GETDATE(),Acc.IsActive,Acc.IsDeleted 
						   	
						  from AccountingCalendar Acc WITH(NOLOCK)  
						  inner join LegalEntity Le WITH(NOLOCK) on le.LegalEntityId=Acc.LegalEntityId
						  inner join Ledger Led WITH(NOLOCK) on Led.LedgerId=Acc.LedgerId 
						   where PeriodName=@periodName and Acc.MasterCompanyId= @MasterCompanyId

						  INSERT INTO [dbo].[AccountingCalendarHistory]
                          ([ReferenceId],[PeriodName],[TableName],[StatusName],[LegalEntityId],[LegalEntityName],[ledgerId],[ledgerName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
                          select AccountingCalendarId,PeriodName,'Fixed Asset',(Case when Acc.isassetStatusName=1 then 'Open' else 'Closed' end),Acc.LegalEntityId,Le.Name,acc.ledgerId,Led.LedgerName,acc.MasterCompanyId,@UpdatedBy,@UpdatedBy,GETDATE(),GETDATE(),Acc.IsActive,Acc.IsDeleted 
						   	
						  from AccountingCalendar Acc WITH(NOLOCK)  
						  inner join LegalEntity Le WITH(NOLOCK) on le.LegalEntityId=Acc.LegalEntityId
						  inner join Ledger Led WITH(NOLOCK) on Led.LedgerId=Acc.LedgerId 
						  where PeriodName=@periodName and Acc.MasterCompanyId= @MasterCompanyId
					 
					 end
				     
				     if(@statusname ='Open All')
				     begin
				        update AccountingCalendar set Status='Open',isaccStatusName=1 where PeriodName=@periodName and MasterCompanyId= @MasterCompanyId
				     end

					 INSERT INTO [dbo].[AccountingCalendarHistory]
                          ([ReferenceId],[PeriodName],[TableName],[StatusName],[LegalEntityId],[LegalEntityName],[ledgerId],[ledgerName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
                          select AccountingCalendarId,PeriodName,'General Ledger',Acc.Status,Acc.LegalEntityId,Le.Name,acc.ledgerId,Led.LedgerName,acc.MasterCompanyId,@UpdatedBy,@UpdatedBy,GETDATE(),GETDATE(),Acc.IsActive,Acc.IsDeleted 
						   	
						  from AccountingCalendar Acc WITH(NOLOCK)  
						  inner join LegalEntity Le WITH(NOLOCK) on le.LegalEntityId=Acc.LegalEntityId
						  inner join Ledger Led WITH(NOLOCK) on Led.LedgerId=Acc.LedgerId 
						  where PeriodName=@periodName and Acc.MasterCompanyId= @MasterCompanyId	  
				  
				end
				else if(Upper(@accounttabname) =Upper('Accounts Receivables'))
				begin
								
				     if(@statusname ='Close All')
				     begin
				        update AccountingCalendar set isacrStatusName=0 where PeriodName=@periodName and MasterCompanyId= @MasterCompanyId
				     end
				     
				     if(@statusname ='Open All')
				     begin
				        update AccountingCalendar set isacrStatusName=1 where PeriodName=@periodName and MasterCompanyId= @MasterCompanyId
				     end

					 INSERT INTO [dbo].[AccountingCalendarHistory]
                          ([ReferenceId],[PeriodName],[TableName],[StatusName],[LegalEntityId],[LegalEntityName],[ledgerId],[ledgerName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
                          select AccountingCalendarId,PeriodName,'Accounts Receivables',(Case when Acc.isacrStatusName=1 then 'Open' else 'Closed' end),Acc.LegalEntityId,Le.Name,acc.ledgerId,Led.LedgerName,acc.MasterCompanyId,@UpdatedBy,@UpdatedBy,GETDATE(),GETDATE(),Acc.IsActive,Acc.IsDeleted 
						   	
						  from AccountingCalendar Acc WITH(NOLOCK)  
						  inner join LegalEntity Le WITH(NOLOCK) on le.LegalEntityId=Acc.LegalEntityId
						  inner join Ledger Led WITH(NOLOCK) on Led.LedgerId=Acc.LedgerId 
						  where PeriodName=@periodName and Acc.MasterCompanyId= @MasterCompanyId

				  				  
				end
				else if(Upper(@accounttabname) =Upper('Account Payable'))
				begin

				     if(@statusname ='Close All')
				     begin
				        update AccountingCalendar set isacpStatusName=0 where PeriodName=@periodName and MasterCompanyId= @MasterCompanyId
				     end
				     
				     if(@statusname ='Open All')
				     begin
				        update AccountingCalendar set isacpStatusName=1 where PeriodName=@periodName and MasterCompanyId= @MasterCompanyId
				     end

					 INSERT INTO [dbo].[AccountingCalendarHistory]
                          ([ReferenceId],[PeriodName],[TableName],[StatusName],[LegalEntityId],[LegalEntityName],[ledgerId],[ledgerName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
                          select AccountingCalendarId,PeriodName,'Account Payable',(Case when Acc.isacpStatusName=1 then 'Open' else 'Closed' end),Acc.LegalEntityId,Le.Name,acc.ledgerId,Led.LedgerName,acc.MasterCompanyId,@UpdatedBy,@UpdatedBy,GETDATE(),GETDATE(),Acc.IsActive,Acc.IsDeleted 
						   	
						  from AccountingCalendar Acc WITH(NOLOCK)  
						  inner join LegalEntity Le WITH(NOLOCK) on le.LegalEntityId=Acc.LegalEntityId
						  inner join Ledger Led WITH(NOLOCK) on Led.LedgerId=Acc.LedgerId 
						  where PeriodName=@periodName and Acc.MasterCompanyId= @MasterCompanyId
				  
				  
				end
				else if(Upper(@accounttabname) =Upper('Fixed Asset'))
				begin
								
				     if(@statusname ='Close All')
				     begin
				        update AccountingCalendar set isassetStatusName=0 where PeriodName=@periodName and MasterCompanyId= @MasterCompanyId
				     end
				     
				     if(@statusname ='Open All')
				     begin
				        update AccountingCalendar set isassetStatusName=1 where PeriodName=@periodName and MasterCompanyId= @MasterCompanyId
				     end

					 INSERT INTO [dbo].[AccountingCalendarHistory]
                          ([ReferenceId],[PeriodName],[TableName],[StatusName],[LegalEntityId],[LegalEntityName],[ledgerId],[ledgerName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
                          select AccountingCalendarId,PeriodName,'Fixed Asset',(Case when Acc.isassetStatusName=1 then 'Open' else 'Closed' end),Acc.LegalEntityId,Le.Name,acc.ledgerId,Led.LedgerName,acc.MasterCompanyId,@UpdatedBy,@UpdatedBy,GETDATE(),GETDATE(),Acc.IsActive,Acc.IsDeleted 
						   	
						  from AccountingCalendar Acc WITH(NOLOCK)  
						  inner join LegalEntity Le WITH(NOLOCK) on le.LegalEntityId=Acc.LegalEntityId
						  inner join Ledger Led WITH(NOLOCK) on Led.LedgerId=Acc.LedgerId 
						  where PeriodName=@periodName and Acc.MasterCompanyId= @MasterCompanyId

				  				  
				end
				else if(Upper(@accounttabname) =Upper('Inventory'))
				begin

				     if(@statusname ='Close All')
				     begin
				        update AccountingCalendar set isinventoryStatusName=0 where PeriodName=@periodName and MasterCompanyId= @MasterCompanyId
				     end
				     
				     if(@statusname ='Open All')
				     begin
				        update AccountingCalendar set isinventoryStatusName=1 where PeriodName=@periodName and MasterCompanyId= @MasterCompanyId
				     end

					 INSERT INTO [dbo].[AccountingCalendarHistory]
                          ([ReferenceId],[PeriodName],[TableName],[StatusName],[LegalEntityId],[LegalEntityName],[ledgerId],[ledgerName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
                          select AccountingCalendarId,PeriodName,'Inventory',(Case when Acc.isinventoryStatusName=1 then 'Open' else 'Closed' end),Acc.LegalEntityId,Le.Name,acc.ledgerId,Led.LedgerName,acc.MasterCompanyId,@UpdatedBy,@UpdatedBy,GETDATE(),GETDATE(),Acc.IsActive,Acc.IsDeleted 
						   	
						  from AccountingCalendar Acc WITH(NOLOCK)  
						  inner join LegalEntity Le WITH(NOLOCK) on le.LegalEntityId=Acc.LegalEntityId
						  inner join Ledger Led WITH(NOLOCK) on Led.LedgerId=Acc.LedgerId 
						  where PeriodName=@periodName and Acc.MasterCompanyId= @MasterCompanyId
				  
				  
				end
				
				IF EXISTS(select * from AccountingCalendar where PeriodName = @periodName and MasterCompanyId = @MasterCompanyId and (isaccStatusName = 1 OR isacpStatusName = 1 OR isacrStatusName = 1 OR isassetStatusName =1 OR isinventoryStatusName =1))
				BEGIN
					update AccountingCalendar set Status='Open' where PeriodName=@periodName and MasterCompanyId= @MasterCompanyId
				END
				ELSE 
				BEGIN
					update AccountingCalendar set Status='Closed' where PeriodName=@periodName and MasterCompanyId= @MasterCompanyId
				END

					
				END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH 

		IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_AccountingCalendarList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '+ ISNULL(@AccountingCalendarId, '') + ', 
													   @Parameter2 = ' + ISNULL(@periodName,'') + '' 
												
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			=  @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH  
END