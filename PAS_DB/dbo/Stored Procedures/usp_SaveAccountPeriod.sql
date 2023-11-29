/*************************************************************           
 ** File:     [usp_SaveWorkOrderMaterialKit]           
 ** Author:	  Vishal Suthar
 ** Description: This SP is Used to save material KITs    
 ** Purpose:         
 ** Date:   03/24/2023
          
 ** PARAMETERS:             
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------     
	1    03/24/2023   Vishal Suthar		Created

**************************************************************/ 
CREATE       PROCEDURE [dbo].[usp_SaveAccountPeriod]
	@tbl_AccountPeriodType AccountPeriodType READONLY,
	@MasterCompanyId int
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY
		BEGIN TRANSACTION
		BEGIN
			DECLARE @InsertedWorkOrderMaterialsKitMappingId BIGINT;
			DECLARE @Main_LoopID AS INT;
			DECLARE @LoopID AS INT;
			DECLARE @UpdatedBy varchar(50)
	        DECLARE @periodName varchar(50)

			IF OBJECT_ID(N'tempdb..#AccountPeriodType') IS NOT NULL
			BEGIN
				DROP TABLE #AccountPeriodType 
			END
			
			CREATE TABLE #AccountPeriodType 
			(
				ID BIGINT NOT NULL IDENTITY, 
				[ACCReferenceId] [bigint] NULL,
				[ACPReferenceId] [bigint] NULL,
				[ACRReferenceId] [bigint] NULL,
				[AssetReferenceId] [bigint] NULL,
				[InventoryReferenceId] [bigint] NULL,
				[IsACCStatusName] bit NULL,
				[IsACPStatusName] bit NULL,
				[IsACRStatusName] bit NULL,
				[IsAssetStatusName] bit NULL,
				[IsInventoryStatusName] bit NULL,
				[UpdatedBy] [varchar](256) NULL,
				[PeriodName] [varchar](256) NULL
			)
				
			INSERT INTO #AccountPeriodType 
			(ACCReferenceId, [ACPReferenceId], [ACRReferenceId], [AssetReferenceId], [InventoryReferenceId], [IsACCStatusName], [IsACPStatusName], [IsACRStatusName], 
			[IsAssetStatusName], [IsInventoryStatusName], UpdatedBy, [PeriodName])
			SELECT ACCReferenceId, [ACPReferenceId], [ACRReferenceId], [AssetReferenceId], [InventoryReferenceId], [IsACCStatusName], [IsACPStatusName], [IsACRStatusName], 
			[IsAssetStatusName], [IsInventoryStatusName], UpdatedBy, [PeriodName]
			FROM @tbl_AccountPeriodType

			DECLARE @TotMainCount AS INT;
			SELECT @TotMainCount = COUNT(*), @Main_LoopID = MIN(ID) FROM #AccountPeriodType;

			WHILE (@Main_LoopID <= @TotMainCount)
			BEGIN
				DECLARE @IsACCStatusName bit;
				DECLARE @IsACPStatusName bit;
				DECLARE @IsACRStatusName bit;
				DECLARE @IsAssetStatusName bit;
				DECLARE @IsInventoryStatusName bit;

				DECLARE @IsACCStatusNameold bit;
				DECLARE @IsACPStatusNameold bit;
				DECLARE @IsACRStatusNameold bit;
				DECLARE @IsAssetStatusNameold bit;
				DECLARE @IsInventoryStatusNameold bit;

				DECLARE @ACCReferenceId bigint;
				DECLARE @ACPReferenceId bigint;
				DECLARE @ACRReferenceId bigint;
				DECLARE @AssetReferenceId bigint;
				DECLARE @InventoryReferenceId bigint;
				SELECT @ACCReferenceId=ACCReferenceId,@ACPReferenceId=ACPReferenceId,@ACRReferenceId= ACRReferenceId,@AssetReferenceId= AssetReferenceId,@InventoryReferenceId= InventoryReferenceId,@IsACCStatusName = isnull(IsACCStatusName,0),@IsACPStatusName = isnull(IsACPStatusName,0),
				       @IsACRStatusName = isnull(IsACRStatusName,0),@IsAssetStatusName = isnull(IsAssetStatusName,0),@IsInventoryStatusName = isnull(IsInventoryStatusName,0),
					   @UpdatedBy = UpdatedBy,@periodName=PeriodName FROM #AccountPeriodType WHERE ID = @Main_LoopID;

					   select * FROM #AccountPeriodType WHERE ID = @Main_LoopID;

					   select @MasterCompanyId=MasterCompanyId,@IsACCStatusNameold = isnull(IsACCStatusName,0),@IsACPStatusNameold = isnull(IsACPStatusName,0), @IsACRStatusNameold = isnull(IsACRStatusName,0),@IsAssetStatusNameold = isnull(IsAssetStatusName,0),@IsInventoryStatusNameold = isnull(IsInventoryStatusName,0) from AccountingCalendar where AccountingCalendarId=@ACCReferenceId


					 if(@IsACPStatusName != @IsACPStatusNameold)
				     begin

					   update AccountingCalendar set isacpStatusName=@IsACPStatusName where AccountingCalendarId=@ACCReferenceId 

						INSERT INTO [dbo].[AccountingCalendarHistory]
                          ([ReferenceId],[PeriodName],[TableName],[StatusName],[LegalEntityId],[LegalEntityName],[ledgerId],[ledgerName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
                          select AccountingCalendarId,PeriodName,'Account Payable',(Case when Acc.isacpStatusName=1 then 'Open' else 'Closed' end),Acc.LegalEntityId,Le.Name,acc.ledgerId,Led.LedgerName,acc.MasterCompanyId,@UpdatedBy,@UpdatedBy,GETDATE(),GETDATE(),Acc.IsActive,Acc.IsDeleted 
						   	
						  from AccountingCalendar Acc WITH(NOLOCK)  
						  inner join LegalEntity Le WITH(NOLOCK) on le.LegalEntityId=Acc.LegalEntityId
						  inner join Ledger Led WITH(NOLOCK) on Led.LedgerId=Acc.LedgerId 
						  where AccountingCalendarId=@ACCReferenceId

				     end
					 
					 IF(@IsACRStatusName != @IsACRStatusNameold)
				     begin
				        update AccountingCalendar set isacrStatusName=@IsACRStatusName where AccountingCalendarId=@ACCReferenceId and MasterCompanyId= @MasterCompanyId

						INSERT INTO [dbo].[AccountingCalendarHistory]
                          ([ReferenceId],[PeriodName],[TableName],[StatusName],[LegalEntityId],[LegalEntityName],[ledgerId],[ledgerName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
                          select AccountingCalendarId,PeriodName,'Accounts Receivables',(Case when Acc.isacrStatusName=1 then 'Open' else 'Closed' end),Acc.LegalEntityId,Le.Name,acc.ledgerId,Led.LedgerName,acc.MasterCompanyId,@UpdatedBy,@UpdatedBy,GETDATE(),GETDATE(),Acc.IsActive,Acc.IsDeleted 
						   	
						  from AccountingCalendar Acc WITH(NOLOCK)  
						  inner join LegalEntity Le WITH(NOLOCK) on le.LegalEntityId=Acc.LegalEntityId
						  inner join Ledger Led WITH(NOLOCK) on Led.LedgerId=Acc.LedgerId 
						  where AccountingCalendarId=@ACCReferenceId and Acc.MasterCompanyId= @MasterCompanyId 

				     end


					 IF(@IsAssetStatusName != @IsAssetStatusNameold)
				     begin
				        update AccountingCalendar set isassetStatusName=@IsAssetStatusName where AccountingCalendarId=@ACCReferenceId and MasterCompanyId= @MasterCompanyId

						INSERT INTO [dbo].[AccountingCalendarHistory]
                          ([ReferenceId],[PeriodName],[TableName],[StatusName],[LegalEntityId],[LegalEntityName],[ledgerId],[ledgerName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
                          select AccountingCalendarId,PeriodName,'Fixed Asset',(Case when Acc.isassetStatusName=1 then 'Open' else 'Closed' end),Acc.LegalEntityId,Le.Name,acc.ledgerId,Led.LedgerName,acc.MasterCompanyId,@UpdatedBy,@UpdatedBy,GETDATE(),GETDATE(),Acc.IsActive,Acc.IsDeleted 
						   	
						  from AccountingCalendar Acc WITH(NOLOCK)  
						  inner join LegalEntity Le WITH(NOLOCK) on le.LegalEntityId=Acc.LegalEntityId
						  inner join Ledger Led WITH(NOLOCK) on Led.LedgerId=Acc.LedgerId 
						  where AccountingCalendarId=@ACCReferenceId and Acc.MasterCompanyId= @MasterCompanyId 

				     end

					 IF(@IsInventoryStatusName != @IsInventoryStatusNameold)
				     begin
				        update AccountingCalendar set isinventoryStatusName=@IsInventoryStatusName where AccountingCalendarId=@ACCReferenceId and MasterCompanyId= @MasterCompanyId

						INSERT INTO [dbo].[AccountingCalendarHistory]
                          ([ReferenceId],[PeriodName],[TableName],[StatusName],[LegalEntityId],[LegalEntityName],[ledgerId],[ledgerName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
                          select AccountingCalendarId,PeriodName,'Inventory',(Case when Acc.isinventoryStatusName=1 then 'Open' else 'Closed' end),Acc.LegalEntityId,Le.Name,acc.ledgerId,Led.LedgerName,acc.MasterCompanyId,@UpdatedBy,@UpdatedBy,GETDATE(),GETDATE(),Acc.IsActive,Acc.IsDeleted 
						   	
						  from AccountingCalendar Acc WITH(NOLOCK)  
						  inner join LegalEntity Le WITH(NOLOCK) on le.LegalEntityId=Acc.LegalEntityId
						  inner join Ledger Led WITH(NOLOCK) on Led.LedgerId=Acc.LedgerId 
						  where AccountingCalendarId=@ACCReferenceId and Acc.MasterCompanyId= @MasterCompanyId 

				     end

				     if(@IsACCStatusName =0 and @IsACCStatusName != @IsACCStatusNameold)
				     begin

					    update AccountingCalendar set Status='Closed',isaccStatusName=0,isacpStatusName=0,isacrStatusName=0,isassetStatusName=0,isinventoryStatusName=0 where AccountingCalendarId=@ACCReferenceId and MasterCompanyId= @MasterCompanyId
				     

					     INSERT INTO [dbo].[AccountingCalendarHistory]
                          ([ReferenceId],[PeriodName],[TableName],[StatusName],[LegalEntityId],[LegalEntityName],[ledgerId],[ledgerName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
                          select AccountingCalendarId,PeriodName,'Account Payable',(Case when Acc.isacpStatusName=1 then 'Open' else 'Closed' end),Acc.LegalEntityId,Le.Name,acc.ledgerId,Led.LedgerName,acc.MasterCompanyId,@UpdatedBy,@UpdatedBy,GETDATE(),GETDATE(),Acc.IsActive,Acc.IsDeleted 
						   	
						  from AccountingCalendar Acc WITH(NOLOCK)  
						  inner join LegalEntity Le WITH(NOLOCK) on le.LegalEntityId=Acc.LegalEntityId
						  inner join Ledger Led WITH(NOLOCK) on Led.LedgerId=Acc.LedgerId 
						  where AccountingCalendarId=@ACCReferenceId and Acc.MasterCompanyId= @MasterCompanyId

						  INSERT INTO [dbo].[AccountingCalendarHistory]
                          ([ReferenceId],[PeriodName],[TableName],[StatusName],[LegalEntityId],[LegalEntityName],[ledgerId],[ledgerName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
                          select AccountingCalendarId,PeriodName,'Accounts Receivables',(Case when Acc.isacrStatusName=1 then 'Open' else 'Closed' end),Acc.LegalEntityId,Le.Name,acc.ledgerId,Led.LedgerName,acc.MasterCompanyId,@UpdatedBy,@UpdatedBy,GETDATE(),GETDATE(),Acc.IsActive,Acc.IsDeleted 
						   	
						  from AccountingCalendar Acc WITH(NOLOCK)  
						  inner join LegalEntity Le WITH(NOLOCK) on le.LegalEntityId=Acc.LegalEntityId
						  inner join Ledger Led WITH(NOLOCK) on Led.LedgerId=Acc.LedgerId 
						  where AccountingCalendarId=@ACCReferenceId and Acc.MasterCompanyId= @MasterCompanyId

						   INSERT INTO [dbo].[AccountingCalendarHistory]
                          ([ReferenceId],[PeriodName],[TableName],[StatusName],[LegalEntityId],[LegalEntityName],[ledgerId],[ledgerName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
                          select AccountingCalendarId,PeriodName,'General Ledger',Acc.Status,Acc.LegalEntityId,Le.Name,acc.ledgerId,Led.LedgerName,acc.MasterCompanyId,@UpdatedBy,@UpdatedBy,GETDATE(),GETDATE(),Acc.IsActive,Acc.IsDeleted 
						   	
						  from AccountingCalendar Acc WITH(NOLOCK)  
						  inner join LegalEntity Le WITH(NOLOCK) on le.LegalEntityId=Acc.LegalEntityId
						  inner join Ledger Led WITH(NOLOCK) on Led.LedgerId=Acc.LedgerId 
						  where AccountingCalendarId=@ACCReferenceId and Acc.MasterCompanyId= @MasterCompanyId

						  INSERT INTO [dbo].[AccountingCalendarHistory]
                          ([ReferenceId],[PeriodName],[TableName],[StatusName],[LegalEntityId],[LegalEntityName],[ledgerId],[ledgerName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
                          select AccountingCalendarId,PeriodName,'Inventory',(Case when Acc.isinventoryStatusName=1 then 'Open' else 'Closed' end),Acc.LegalEntityId,Le.Name,acc.ledgerId,Led.LedgerName,acc.MasterCompanyId,@UpdatedBy,@UpdatedBy,GETDATE(),GETDATE(),Acc.IsActive,Acc.IsDeleted 
						   	
						  from AccountingCalendar Acc WITH(NOLOCK)  
						  inner join LegalEntity Le WITH(NOLOCK) on le.LegalEntityId=Acc.LegalEntityId
						  inner join Ledger Led WITH(NOLOCK) on Led.LedgerId=Acc.LedgerId 
						  where AccountingCalendarId=@ACCReferenceId and Acc.MasterCompanyId= @MasterCompanyId 

						  INSERT INTO [dbo].[AccountingCalendarHistory]
                          ([ReferenceId],[PeriodName],[TableName],[StatusName],[LegalEntityId],[LegalEntityName],[ledgerId],[ledgerName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
                          select AccountingCalendarId,PeriodName,'Fixed Asset',(Case when Acc.isassetStatusName=1 then 'Open' else 'Closed' end),Acc.LegalEntityId,Le.Name,acc.ledgerId,Led.LedgerName,acc.MasterCompanyId,@UpdatedBy,@UpdatedBy,GETDATE(),GETDATE(),Acc.IsActive,Acc.IsDeleted 
						   	
						  from AccountingCalendar Acc WITH(NOLOCK)  
						  inner join LegalEntity Le WITH(NOLOCK) on le.LegalEntityId=Acc.LegalEntityId
						  inner join Ledger Led WITH(NOLOCK) on Led.LedgerId=Acc.LedgerId 
						  where AccountingCalendarId=@ACCReferenceId and Acc.MasterCompanyId= @MasterCompanyId 
				     end
						 	
				     if(@IsACCStatusName =1 and @IsACCStatusName != @IsACCStatusNameold)
				     begin
				        update AccountingCalendar set Status='Open',isaccStatusName=1 where AccountingCalendarId=@ACCReferenceId and MasterCompanyId= @MasterCompanyId

						INSERT INTO [dbo].[AccountingCalendarHistory]
                          ([ReferenceId],[PeriodName],[TableName],[StatusName],[LegalEntityId],[LegalEntityName],[ledgerId],[ledgerName],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
                          select AccountingCalendarId,PeriodName,'General Ledger',Acc.Status,Acc.LegalEntityId,Le.Name,acc.ledgerId,Led.LedgerName,acc.MasterCompanyId,@UpdatedBy,@UpdatedBy,GETDATE(),GETDATE(),Acc.IsActive,Acc.IsDeleted 
						   	
						  from AccountingCalendar Acc WITH(NOLOCK)  
						  inner join LegalEntity Le WITH(NOLOCK) on le.LegalEntityId=Acc.LegalEntityId
						  inner join Ledger Led WITH(NOLOCK) on Led.LedgerId=Acc.LedgerId 
						  where AccountingCalendarId=@ACCReferenceId and Acc.MasterCompanyId= @MasterCompanyId

				     end


				SET @Main_LoopID = @Main_LoopID + 1;
			END
		END
		COMMIT TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_SaveWorkOrderMaterialKit' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH     
END