/*************************************************************           
 ** File:   [GenerateNachaFileID]           
 ** Author:   MOIN BLOCH
 ** Description: This stored procedure is used Get Nacha File ID
 ** Purpose:         
 ** Date:   09/26/2023
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/26/2023   MOIN BLOCH    CREATED 

-- EXEC GenerateNachaFileID 1,GETUTCDATE(),1,'ADMIN'
**************************************************************/
CREATE   PROCEDURE [dbo].[GenerateNachaFileID]
@LegalEntityId INT,
@CalendarDay DATE,
@MasterCompanyId INT,
@CreatedBy VARCHAR(256),
@Fileid VARCHAR(10) OUTPUT
AS  
BEGIN 
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 BEGIN TRY 
   
	IF NOT EXISTS(SELECT 1 FROM [dbo].[NachaFileIDDetails] WITH(NOLOCK) WHERE [CalendarDay] = CAST(@CalendarDay AS DATE) AND [LegalEntityId] = @LegalEntityId AND [MasterCompanyId] = @MasterCompanyId)
	BEGIN	
		SET @Fileid = CHAR(65);
		INSERT INTO [dbo].[NachaFileIDDetails]([FileId],[FieldNumber],[LegalEntityId],[CalendarDay],[MasterCompanyId],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate])
			 VALUES(@Fileid,65,@LegalEntityId,@CalendarDay,@MasterCompanyId,@CreatedBy,GETUTCDATE(),@CreatedBy,GETUTCDATE())
		SELECT @Fileid = CHAR(65);
	END
	ELSE
	BEGIN
		DECLARE @FieldNumber INT;
		DECLARE @NachaId BIGINT;

		SELECT @FieldNumber = [FieldNumber], 
		       @NachaId = [NachaId] 
		  FROM [dbo].[NachaFileIDDetails] WITH(NOLOCK) 
		 WHERE [CalendarDay] = CAST(@CalendarDay AS DATE) AND [LegalEntityId]=@LegalEntityId AND [MasterCompanyId] = @MasterCompanyId;

		IF(@FieldNumber = 90)
		BEGIN			
			 UPDATE [dbo].[NachaFileIDDetails]
			    SET [FileId] = CHAR(65)
                   ,[FieldNumber] = 65 
				   ,[UpdatedBy] = @CreatedBy
				   ,[UpdatedDate] = GETUTCDATE()
			  WHERE [NachaId] = @NachaId;

			  SELECT @Fileid = CHAR(65);
		END
		ELSE
		BEGIN	
			SET @FieldNumber = @FieldNumber + 1;
			 UPDATE [dbo].[NachaFileIDDetails]
			    SET [FileId] = CHAR(@FieldNumber)
                   ,[FieldNumber] = @FieldNumber 
				   ,[UpdatedBy] = @CreatedBy
				   ,[UpdatedDate] = GETUTCDATE()
			  WHERE [NachaId] = @NachaId;

			SELECT @Fileid = CHAR(@FieldNumber);
		END	
		
	END
 END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'      
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'GenerateNachaFileID'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL('', '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END