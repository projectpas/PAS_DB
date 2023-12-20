/*************************************************************           
 ** File:   [AccountingBatchManagementStructureDetails]           
 ** Author:  Moin Bloch
 ** Description: This stored procedure is used to store Common Accounting Batch Management Structure Details
 ** Purpose:         
 ** Date:   08/17/2023        
          
 ** PARAMETERS: @CommonJournalBatchDetailId bigint,@EntityStructureId bigint,@MasterCompanyId int,@CreatedBy varchar,@UpdatedBy varchar,@ModuleId bigint,@Opr int
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/17/2023   Moin Bloch     Created
	2    08/25/2023   Moin Bloch     UPDATED ADDED UPDATE PART
     
-- EXEC PROCAddUpdateAccountingBatchMSData 1,1,1,'moin','moin',1,1

************************************************************************/
CREATE   PROCEDURE [dbo].[PROCAddUpdateAccountingBatchMSData]
@CommonJournalBatchDetailId bigint,
@EntityMSID BIGINT,
@MasterCompanyId INT,
@CreatedBy VARCHAR(50),
@ModuleId INT,
@Opr INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		IF(@Opr = 1)
		BEGIN
			  INSERT INTO [dbo].[AccountingBatchManagementStructureDetails]					
                         ([ReferenceId]
                         ,[ModuleId]
						 ,[EntityMSID]
                         ,[Level1Id]
                         ,[Level2Id]
                         ,[Level3Id]
                         ,[Level4Id]
                         ,[Level5Id]
                         ,[Level6Id]
                         ,[Level7Id]
                         ,[Level8Id]
                         ,[Level9Id]
                         ,[Level10Id]
                         ,[MasterCompanyId]
                         ,[CreatedBy]
                         ,[UpdatedBy]
                         ,[CreatedDate]
                         ,[UpdatedDate]
                         ,[IsActive]
                         ,[IsDeleted])
			        SELECT @CommonJournalBatchDetailId				
					      ,@ModuleId
						  ,@EntityMSID													        
						  ,EST.Level1Id
					      ,EST.Level2Id
					      ,EST.Level3Id
					      ,EST.Level4Id
					      ,EST.Level5Id
					      ,EST.Level6Id
					      ,EST.Level7Id
					      ,EST.Level8Id
					      ,EST.Level9Id
					      ,EST.Level10Id
						  ,@MasterCompanyId
						  ,@CreatedBy
						  ,@CreatedBy
						  ,GETUTCDATE()
						  ,GETUTCDATE()
						  ,1
						  ,0
		 			  FROM [dbo].[EntityStructureSetup] EST WITH(NOLOCK) 													  																	   
					  WHERE EST.[EntityStructureId] = @EntityMSID; 

			  --SELECT @MSDetailsId = IDENT_CURRENT('AccountingBatchManagementStructureDetails');			        
		END	
		IF(@Opr = 2)
		BEGIN
				UPDATE [dbo].[AccountingBatchManagementStructureDetails]
				   SET [EntityMSID] = @EntityMSID, 
					   [UpdatedBy] = @CreatedBy,
					   [Level1Id] = EST.[Level1Id],							
					   [Level2Id] = EST.[Level2Id],							
					   [Level3Id] = EST.[Level3Id],
					   [Level4Id] = EST.[Level4Id],
					   [Level5Id] = EST.[Level5Id],	
					   [Level6Id] = EST.[Level6Id],
					   [Level7Id] = EST.[Level7Id],
					   [Level8Id] = EST.[Level8Id],
					   [Level9Id] = EST.[Level9Id],
					   [Level10Id] = EST.[Level10Id]							
				  FROM [dbo].[EntityStructureSetup] EST WITH(NOLOCK)
				  LEFT JOIN [dbo].[ManagementStructureLevel] MSL1 WITH (NOLOCK) ON  EST.[Level1Id] = MSL1.ID
				  LEFT JOIN [dbo].[ManagementStructureLevel] MSL2 WITH (NOLOCK) ON  EST.[Level2Id] = MSL2.ID
				  LEFT JOIN [dbo].[ManagementStructureLevel] MSL3 WITH (NOLOCK) ON  EST.[Level3Id] = MSL3.ID
				  LEFT JOIN [dbo].[ManagementStructureLevel] MSL4 WITH (NOLOCK) ON  EST.[Level4Id] = MSL4.ID
				  LEFT JOIN [dbo].[ManagementStructureLevel] MSL5 WITH (NOLOCK) ON  EST.[Level5Id] = MSL5.ID
				  LEFT JOIN [dbo].[ManagementStructureLevel] MSL6 WITH (NOLOCK) ON  EST.[Level6Id] = MSL6.ID
				  LEFT JOIN [dbo].[ManagementStructureLevel] MSL7 WITH (NOLOCK) ON  EST.[Level7Id] = MSL7.ID
				  LEFT JOIN [dbo].[ManagementStructureLevel] MSL8 WITH (NOLOCK) ON  EST.[Level8Id] = MSL8.ID
				  LEFT JOIN [dbo].[ManagementStructureLevel] MSL9 WITH (NOLOCK) ON  EST.[Level9Id] = MSL9.ID
				  LEFT JOIN [dbo].[ManagementStructureLevel] MSL10 WITH (NOLOCK) ON EST.[Level10Id] = MSL10.ID													   
				WHERE [ModuleID] = @ModuleId 
				  AND [ReferenceID] = @CommonJournalBatchDetailId 
				  AND EST.[EntityStructureId]=@EntityMSID;
		END		 
	END	
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0		
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'PROCAddUpdateAccountingBatchMSData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@CommonJournalBatchDetailId, '') AS VARCHAR(100))
			                                        + '@Parameter2 = ''' + CAST(ISNULL(@EntityMSID, '') AS VARCHAR(100)) 
													+ '@Parameter3 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)) 
													+ '@Parameter4 = ''' + CAST(ISNULL(@CreatedBy, '') AS VARCHAR(100)) 
													+ '@Parameter5 = ''' + CAST(ISNULL(@ModuleId, '') AS VARCHAR(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END