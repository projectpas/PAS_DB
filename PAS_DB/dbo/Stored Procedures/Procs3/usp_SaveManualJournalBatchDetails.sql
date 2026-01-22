/*************************************************************           
 ** File:   [usp_SaveManualJournalBatchDetails]           
 ** Author:   Deep Patel
 ** Description: Save Customer Manual JournalBatchDetails
 ** Purpose:         
 ** Date:   28-December-2022
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    28-12-2022    Deep Patel    Created
	2    25-08-2023    Moin Bloch    Added Accounting Batch ManagementStructure Details Entry For Manual Journal
	3    14-09-2023    Moin Bloch    Added ReferenceId and ReferenceTypeId in ManualJournalDetails 
	4    12-01-2024    AMIT GHEDIYA  Added IsReferenceChecked in ManualJournalDetails 
**************************************************************/ 
CREATE     PROCEDURE [dbo].[usp_SaveManualJournalBatchDetails]
@tbl_ManualJournalBatchDetails ManualJournalBatchDetailsType READONLY
AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		BEGIN TRY
				BEGIN TRANSACTION
				BEGIN

				IF OBJECT_ID(N'tempdb..#tmprManualJournalBatchDetails') IS NOT NULL
				BEGIN
					DROP TABLE #tmprManualJournalBatchDetails
				END
				
				DECLARE @ManualJournalDetailsId BIGINT = 0
				DECLARE @ManualJournalHeaderId BIGINT = 0
				DECLARE @ManagementStructureId  BIGINT = 0
				DECLARE @MasterCompanyId INT = 0
				DECLARE @UpdateBy VARCHAR(100)
				DECLARE @MSModuleId INT = 0				
				 SELECT @MSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] ='ManualJournalAccounting';

				--  JournalBatchDetails LIST
					IF((SELECT COUNT(ManualJournalDetailsId) FROM @tbl_ManualJournalBatchDetails) > 0 )
					BEGIN
						MERGE dbo.ManualJournalDetails AS TARGET
						USING @tbl_ManualJournalBatchDetails AS SOURCE ON (TARGET.ManualJournalHeaderId = SOURCE.ManualJournalHeaderId AND TARGET.ManualJournalDetailsId = SOURCE.ManualJournalDetailsId) 
						--WHEN RECORDS ARE MATCHED, UPDATE THE RECORDS IF THEREANY CHANGES
						WHEN MATCHED 				
							THEN UPDATE 						
							SET 							
								 TARGET.[GlAccountId] = SOURCE.GlAccountId
								,TARGET.[Debit] = SOURCE.Debit
								,TARGET.[Credit] =SOURCE.Credit
								,TARGET.[Description] =SOURCE.[Description]
								,TARGET.[ManagementStructureId] = SOURCE.ManagementStructureId								
								,TARGET.[LastMSLevel] = SOURCE.LastMSLevel
								,TARGET.[AllMSlevels] = SOURCE.AllMSlevels
								,TARGET.[UpdatedBy] = SOURCE.UpdatedBy
								,TARGET.[UpdatedDate] = GETUTCDATE()
								,TARGET.[ReferenceId] = SOURCE.ReferenceId
								,TARGET.[ReferenceTypeId] = SOURCE.ReferenceTypeId
								,TARGET.[IsReferenceChecked] = SOURCE.IsReferenceChecked
							
						WHEN NOT MATCHED BY TARGET 
							THEN INSERT (
										 [ManualJournalHeaderId]
										,[GlAccountId]
										,[Debit]
										,[Credit]
										,[Description]
										,[ManagementStructureId]
										,[LastMSLevel]
										,[AllMSlevels]
										,[MasterCompanyId]
										,[CreatedBy]
										,[UpdatedBy]
										,[CreatedDate]
										,[UpdatedDate]
										,[IsActive]
										,[IsDeleted]
										,[ReferenceId]
										,[ReferenceTypeId]
										,[IsReferenceChecked]
								   )
							VALUES (
										 SOURCE.[ManualJournalHeaderId]
										,SOURCE.[GlAccountId]
										,SOURCE.[Debit]
										,SOURCE.[Credit]
										,SOURCE.[Description]
										,SOURCE.[ManagementStructureId]
										,SOURCE.[LastMSLevel]
										,SOURCE.[AllMSlevels]
										,SOURCE.[MasterCompanyId]
										,SOURCE.[UpdatedBy]
										,SOURCE.[UpdatedBy]
										,GETUTCDATE()
										,GETUTCDATE()
										,1
										,SOURCE.[IsDeleted]
										,SOURCE.[ReferenceId]
										,SOURCE.[ReferenceTypeId]
										,SOURCE.[IsReferenceChecked]
										);
					 END

					 DECLARE @TotalRecord int = 0;   
					 DECLARE @MinId BIGINT = 1;    
					 
					 CREATE TABLE #tmprManualJournalBatchDetails
					 (
						[ID] BIGINT NOT NULL IDENTITY, 	
						[ManualJournalHeaderId] BIGINT NULL,
						[ManualJournalDetailsId] BIGINT NULL,
						[ManagementStructureId] BIGINT NULL,
						[MasterCompanyId] INT,
						[UpdateBy] VARCHAR(100)
					 )   

					 SELECT TOP 1 @ManualJournalHeaderId = [ManualJournalHeaderId]  FROM @tbl_ManualJournalBatchDetails;

					 IF(@ManualJournalHeaderId > 0)
					 BEGIN
					        INSERT INTO #tmprManualJournalBatchDetails ([ManualJournalHeaderId],[ManualJournalDetailsId],[ManagementStructureId],[MasterCompanyId],[UpdateBy])
							SELECT [ManualJournalHeaderId],[ManualJournalDetailsId],[ManagementStructureId],[MasterCompanyId],[UpdatedBy] FROM [dbo].[ManualJournalDetails] WITH(NOLOCK) WHERE [ManualJournalHeaderId] = @ManualJournalHeaderId;
														
							SELECT @TotalRecord = COUNT(*), @MinId = MIN(ID) FROM #tmprManualJournalBatchDetails;
							
							WHILE @MinId <= @TotalRecord
							BEGIN				
								SELECT  @ManualJournalDetailsId = [ManualJournalDetailsId],						     
										@ManagementStructureId = [ManagementStructureId],
										@MasterCompanyId = [MasterCompanyId],
										@UpdateBy = [UpdateBy]				    
								 FROM #tmprManualJournalBatchDetails WHERE ID = @MinId
								 
								 IF NOT EXISTS(SELECT 1 FROM [dbo].[AccountingBatchManagementStructureDetails] WHERE [ReferenceId] = @ManualJournalDetailsId AND [ModuleId] = @MSModuleId)								 
								 BEGIN									
									EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @ManualJournalDetailsId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@MSModuleId,1; 
								 END
								 ELSE
								 BEGIN
									EXEC [dbo].[PROCAddUpdateAccountingBatchMSData] @ManualJournalDetailsId,@ManagementStructureId,@MasterCompanyId,@UpdateBy,@MSModuleId,2; 
								 END
						
								SET @MinId = @MinId + 1
							END
					 END					

				COMMIT  TRANSACTION
			END

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
                    ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_SaveManualJournalBatchDetails' 
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