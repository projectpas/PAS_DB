-----------------------------------------------------------------------------------------------------

/*************************************************************           
 ** File:   [USP_GetTravelerSetupList]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Create Stockline ForCustomer RMA   
 ** Purpose:         
 ** Date:   01/03/2023        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    01/03/2023   Subhash Saliya		Created
     
-- EXEC [USP_GetTravelerSetupList] 44
**************************************************************/

CREATE       PROCEDURE [dbo].[USP_AddEditTraveler_Setup_Task]
 @Traveler_Setup_TaskId bigint,
 @Traveler_SetupId bigint,
 @TaskId bigint,
 @Notes nvarchar(max)= null,
 @Sequence bigint =0,
 @MasterCompanyId bigint,
 @CreatedBy varchar(100),
 @IsDeleted bit=0,
 @IsVersionIncrease bit=0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
			  declare @TaskName varchar(100)
			  declare @PartNumber varchar(100)
			  declare @TeardownTypeName varchar(100)
			  select top 1 @TaskName=Description from Task  where TaskId=@TaskId
			  --select top 1 @TeardownTypeName=Description from CommonTeardownType  where CommonTeardownTypeId=@TeardownTypeId

			

			If(@IsVersionIncrease=1)
			BEGIN
			  
			   declare @WorkScopeId bigint  
               declare @ItemMasterId bigint = null
			   declare @OldtaskId bigint = null
			   declare @Traveler_SetupIdNew bigint = null
			   Select @OldtaskId= TaskId from  Traveler_Setup_Task WHERE Traveler_Setup_TaskId= @Traveler_Setup_TaskId

			   select @WorkScopeId=WorkScopeId,@ItemMasterId=ItemMasterId from Traveler_Setup   where Traveler_SetupId=@Traveler_SetupId
			   update Traveler_Setup set  IsVersionIncrease= 1  where Traveler_SetupId=@Traveler_SetupId
			   EXEC USP_AddUpdateTravelerSetupHeader @WorkScopeId,@MasterCompanyId,@CreatedBy,0,@ItemMasterId,@IsVersionIncrease,@Traveler_SetupId 

			   select top 1 @Traveler_SetupIdNew= Traveler_SetupId from Traveler_Setup  where WorkScopeId= @WorkScopeId and IsVersionIncrease=0 order by Traveler_SetupId desc

			   INSERT INTO [dbo].[Traveler_Setup_Task]
                  ([Traveler_SetupId]
                  ,[TaskId]
                  ,[TaskName]
                  ,[Notes]
                  ,[Sequence]
                  ,[MasterCompanyId]
                  ,[CreatedBy]
                  ,[UpdatedBy]
                  ,[CreatedDate]
                  ,[UpdatedDate]
                  ,[IsActive]
                  ,[IsDeleted]
				  ,IsVersionIncrease
				  )
            Select
                  @Traveler_SetupIdNew
                  ,TaskId
                  ,TaskName
                  ,Notes
                  ,Sequence
                  ,@MasterCompanyId
                  ,@CreatedBy
                  ,@CreatedBy
                  ,GETUTCDATE()
                  ,GETUTCDATE()
                  ,1
                  ,0,0  from Traveler_Setup_Task where Traveler_SetupId=@Traveler_SetupId and IsDeleted=0

               If(@Traveler_Setup_TaskId = 0)
			  BEGIN
       			INSERT INTO [dbo].[Traveler_Setup_Task]
                  ([Traveler_SetupId]
                  ,[TaskId]
                  ,[TaskName]
                  ,[Notes]
                  ,[Sequence]
                  ,[MasterCompanyId]
                  ,[CreatedBy]
                  ,[UpdatedBy]
                  ,[CreatedDate]
                  ,[UpdatedDate]
                  ,[IsActive]
                  ,[IsDeleted]
				  ,IsVersionIncrease
				  )
            VALUES
                  (@Traveler_SetupIdNew
                  ,@TaskId
                  ,@TaskName
                  ,@Notes
                  ,@Sequence
                  ,@MasterCompanyId
                  ,@CreatedBy
                  ,@CreatedBy
                  ,GETUTCDATE()
                  ,GETUTCDATE()
                  ,1
                  ,0
				  ,0
				  )
			END
			else
			Begin
			    UPDATE [dbo].[Traveler_Setup_Task]
                SET 
                    [TaskId] = @TaskId
                   ,[TaskName] = @TaskName
                   ,[Notes] = @Notes
                   ,[Sequence] = @Sequence
                   ,[UpdatedBy] = @CreatedBy
                   ,[UpdatedDate] = GETUTCDATE()
                   ,[IsDeleted] = @IsDeleted
              WHERE Traveler_SetupId=@Traveler_SetupIdNew and TaskId= @OldtaskId
			END
			END
			ELSE
			BEGIN

			  If(@Traveler_Setup_TaskId = 0)
			  BEGIN
       			INSERT INTO [dbo].[Traveler_Setup_Task]
                  ([Traveler_SetupId]
                  ,[TaskId]
                  ,[TaskName]
                  ,[Notes]
                  ,[Sequence]
                  ,[MasterCompanyId]
                  ,[CreatedBy]
                  ,[UpdatedBy]
                  ,[CreatedDate]
                  ,[UpdatedDate]
                  ,[IsActive]
                  ,[IsDeleted]
				  ,IsVersionIncrease
				  )
            VALUES
                  (@Traveler_SetupId
                  ,@TaskId
                  ,@TaskName
                  ,@Notes
                  ,@Sequence
                  ,@MasterCompanyId
                  ,@CreatedBy
                  ,@CreatedBy
                  ,GETUTCDATE()
                  ,GETUTCDATE()
                  ,1
                  ,0
				  ,0
				  )

				  update Traveler_Setup set  UpdatedBy=@CreatedBy,UpdatedDate= GETUTCDATE()  where Traveler_SetupId=@Traveler_SetupId
			END
			else
			Begin
			    UPDATE [dbo].[Traveler_Setup_Task]
                SET 
                    [TaskId] = @TaskId
                   ,[TaskName] = @TaskName
                   ,[Notes] = @Notes
                   ,[Sequence] = @Sequence
                   ,[UpdatedBy] = @CreatedBy
                   ,[UpdatedDate] = GETUTCDATE()
                   ,[IsDeleted] = @IsDeleted
              WHERE Traveler_Setup_TaskId= @Traveler_Setup_TaskId
			   update Traveler_Setup set  UpdatedBy=@CreatedBy,UpdatedDate= GETUTCDATE()  where Traveler_SetupId=@Traveler_SetupId
			END

		    END
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetTraveler_Setup_TaskList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@Traveler_SetupId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END