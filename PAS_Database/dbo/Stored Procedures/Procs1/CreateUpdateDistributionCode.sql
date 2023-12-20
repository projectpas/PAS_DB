
/*************************************************************           
 ** File:   [CreateUpdateDistributionCode]           
 ** Author:   Subhash Saliya
 ** Description: Create Update account DistributionCode
 ** Purpose:         
 ** Date:   07/28/2022         
          
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/28/2022   Subhash Saliya Created
	
 -- exec CreateUpdateDistributionCode 92,1    
**************************************************************/ 
Create   PROCEDURE [dbo].[CreateUpdateDistributionCode]
@DistributionId bigint = NULL,
@JournalTypeID bigint = NULL,
@CodeName  varchar(100) = NULL,
@Description varchar(500) = NULL,  
@GLAccountId bigint = NULL,
@Level1Id int = NULL,
@Level2Id int= NULL,
@Level3Id int = NULL,
@Level4Id int = NULL,  
@Level5Id int = NULL,
@Level6Id int = NULL,
@Level7Id int = NULL,
@Level8Id int = NULL,
@Level9Id int= NULL,
@Level10Id int = NULL,
@MasterCompanyId int,
@CreatedBy varchar(256),  
@UpdatedBy varchar(256),  
@Result bigint =1 OUTPUT

AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
		BEGIN TRANSACTION
		BEGIN

		    DECLARE @RC int
			DECLARE @Opr int
			DECLARE @MSDetailsId bigint
			IF (@DistributionId IS NULL OR @DistributionId=0)
			BEGIN
				INSERT INTO [dbo].[DistributionCodeEntry]
                                  ([JournalTypeID]
                                  ,[CodeName]
                                  ,[Description]
                                  ,[GLAccountId]
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
                   VALUES
                                  (@JournalTypeID
                                  ,@CodeName
                                  ,@Description
                                  ,@GLAccountId
                                  ,@Level1Id
                                  ,@Level2Id
                                  ,@Level3Id
                                  ,@Level4Id
                                  ,@Level5Id
                                  ,@Level6Id
                                  ,@Level7Id
                                  ,@Level8Id
                                  ,@Level9Id
                                  ,@Level10Id
                                  ,@MasterCompanyId
                                  ,@CreatedBy
                                  ,@UpdatedBy
                                  ,GETDATE()
                                  ,GETDATE()
                                  ,1
                                  ,0)

				SELECT	@Result = IDENT_CURRENT('DistributionCodeEntry');
			    SELECT @Result as DistributionId
				EXEC [DBO].[UpdateDistributionCodeEntryDetails] @Result;

				
			END
			ELSE
			BEGIN

			 UPDATE [dbo].[DistributionCodeEntry]
				   SET     [JournalTypeID] = @JournalTypeID
				          ,[CodeName] = @CodeName
				          ,[Description] = @Description
				          ,[GLAccountId] = @GLAccountId
				          ,[Level1Id] = @Level1Id
				          ,[Level2Id] = @Level2Id
				          ,[Level3Id] = @Level3Id
				          ,[Level4Id] = @Level4Id
				          ,[Level5Id] = @Level5Id
				          ,[Level6Id] = @Level6Id
				          ,[Level7Id] = @Level7Id
				          ,[Level8Id] = @Level8Id
				          ,[Level9Id] = @Level9Id
				          ,[Level10Id] =@Level10Id
				          ,[UpdatedBy] =@updatedBy
				          ,[UpdatedDate] = getdate()
								
                 WHERE DistributionId = @DistributionId

				 SELECT @DistributionId as DistributionId
				 set @Result= @DistributionId
				 EXEC [DBO].[UpdateDistributionCodeEntryDetails] @DistributionId;


			END
		END
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'CreateUpdateDistributionCode' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@DistributionId, '') AS varchar(100))
													+ '@Parameter2 = ''' + CAST(ISNULL(@JournalTypeID, '') AS varchar(100)) 
													+ '@Parameter3 = ''' + CAST(ISNULL(@CodeName, '') AS varchar(100)) 
													+ '@Parameter4 = ''' + CAST(ISNULL(@Description, '') AS varchar(100)) 
													+ '@Parameter5 = ''' + CAST(ISNULL(@GLAccountId, '') AS varchar(100)) 
													+ '@Parameter6 = ''' + CAST(ISNULL(@Level1Id, '') AS varchar(100)) 
													+ '@Parameter7 = ''' + CAST(ISNULL(@Level2Id, '') AS varchar(100)) 
													+ '@Parameter8 = ''' + CAST(ISNULL(@Level3Id, '') AS varchar(100)) 
													+ '@Parameter9 = ''' + CAST(ISNULL(@Level4Id, '') AS varchar(100)) 
													+ '@Parameter10 = ''' + CAST(ISNULL(@Level5Id, '') AS varchar(100)) 
													+ '@Parameter11 = ''' + CAST(ISNULL(@Level6Id, '') AS varchar(100)) 
													+ '@Parameter2 = ''' + CAST(ISNULL(@Level7Id, '') AS varchar(100)) 
													+ '@Parameter3 = ''' + CAST(ISNULL(@Level8Id, '') AS varchar(100)) 
													+ '@Parameter4 = ''' + CAST(ISNULL(@Level9Id, '') AS varchar(100)) 
													+ '@Parameter5 = ''' + CAST(ISNULL(@Level10Id, '') AS varchar(100)) 
													+ '@Parameter6 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) 
													+ '@Parameter7 = ''' + CAST(ISNULL(@CreatedBy, '') AS varchar(100)) 
													+ '@Parameter8 = ''' + CAST(ISNULL(@UpdatedBy, '') AS varchar(100)) 
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
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