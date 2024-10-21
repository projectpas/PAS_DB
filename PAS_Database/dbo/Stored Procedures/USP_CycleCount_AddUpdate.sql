/*************************************************************           
 ** File:   [USP_CycleCount_AddUpdate]           
 ** Author: Moin Bloch
 ** Description: This stored procedure is used to INSERT AND UPDATE Cycle Count Header Details
 ** Purpose:         
 ** Date:   16/10/2024     
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    16/10/2024   Moin Bloch    Created

  EXEC [dbo].[USP_CycleCount_AddUpdate] 1,'2024-10-15','19:36',1,1,1,1,'ADMIN User','ADMIN User'    
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CycleCount_AddUpdate]
@CycleCountId BIGINT,
@EntryDate DATETIME2(7),
@EntryTime TIME(7),
@StatusId INT,
@ManagementStructureId BIGINT,  
@IsEnforce BIT,
@MasterCompanyId INT,
@CreatedBy VARCHAR(200),
@UpdatedBy VARCHAR(200)
AS  
BEGIN  
	SET NOCOUNT ON;	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	    
		DECLARE @MSModuleId INT;
		SELECT @MSModuleId = [ManagementStructureModuleId] FROM [dbo].[ManagementStructureModule] WITH(NOLOCK) WHERE [ModuleName] = 'CycleCount'
		
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					IF(@CycleCountId = 0)
					BEGIN
						DECLARE @CycleCountNumber VARCHAR(50);    
						DECLARE @CurrentNummber BIGINT;
						DECLARE @CodeTypeId INT;
						DECLARE @CodePrefix VARCHAR(50);    
						DECLARE @CodeSufix VARCHAR(50);  
						
						SELECT @CodeTypeId = [CodeTypeId] FROM [dbo].[CodeTypes] WITH(NOLOCK) WHERE [CodeType] = 'CycleCount'
					    
						SELECT @CurrentNummber = [CurrentNummber],
					           @CodePrefix = [CodePrefix],
							   @CodeSufix = [CodeSufix] 
					      FROM [dbo].[CodePrefixes] WITH(NOLOCK)    
						 WHERE [CodeTypeId] = @CodeTypeId 
						   AND [MasterCompanyId] = @MasterCompanyId; 
						
					    SET @CycleCountNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(CAST(@CurrentNummber AS BIGINT) + 1, @CodePrefix, @CodeSufix));    
    			
						INSERT INTO [dbo].[CycleCount]
						           ([CycleCountNumber],
								    [EntryDate],
									[EntryTime],
									[StatusId],
									[ManagementStructureId], 
								    [IsEnforce],
									[MasterCompanyId],
									[CreatedBy],
									[UpdatedBy],
									[CreatedDate],
									[UpdatedDate],
									[IsActive],
									[IsDeleted])
							 VALUES (@CycleCountNumber,
							         @EntryDate,
									 @EntryTime,
									 @StatusId,
									 @ManagementStructureId,
							         @IsEnforce,
									 @MasterCompanyId,
									 @CreatedBy,
									 @UpdatedBy,
									 GETUTCDATE(),
									 GETUTCDATE(),
									 1,
									 0);
							
							UPDATE [dbo].[CodePrefixes] SET [CurrentNummber] = CAST(@CurrentNummber AS BIGINT) + 1 WHERE [CodeTypeId] = @CodeTypeId AND [MasterCompanyId] = @MasterCompanyId;    
    
							SET @CycleCountId = SCOPE_IDENTITY();	

							EXEC [dbo].[USP_CycleCount_AddUpdateMSDetails] @CycleCountId,@ManagementStructureId,@MSModuleId,@MasterCompanyId,@CreatedBy,@UpdatedBy,1,1;							
					END
					ELSE
					BEGIN
						UPDATE [dbo].[CycleCount]
						   SET [EntryDate] = @EntryDate, 
							   [EntryTime] = @EntryTime, 
							   [StatusId] = @StatusId, 
							   [ManagementStructureId] = @ManagementStructureId, 
							   [IsEnforce] = @IsEnforce, 							   
							   [UpdatedBy] = @UpdatedBy, 
							   [UpdatedDate] = GETUTCDATE() 							
                         WHERE [CycleCountId] = @CycleCountId;	
						 
						 EXEC [dbo].[USP_CycleCount_AddUpdateMSDetails] @CycleCountId,@ManagementStructureId,@MSModuleId,@MasterCompanyId,@CreatedBy,@UpdatedBy,1,1;							
					END					

					SELECT @CycleCountId AS CycleCountId

				END
			COMMIT  TRANSACTION
		END TRY  
		BEGIN CATCH      
			IF @@trancount > 0
			PRINT 'ROLLBACK'
            ROLLBACK TRAN;
            DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CycleCount_AddUpdate' 
			  , @ProcedureParameters VARCHAR(3000) = '@CycleCountId = ''' + CAST(ISNULL(@CycleCountId, '') AS VARCHAR(100))  
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