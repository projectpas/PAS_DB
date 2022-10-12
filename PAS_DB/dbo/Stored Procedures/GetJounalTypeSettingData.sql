
/*************************************************************           
 ** File:   [GetJounalTypeSettingData]           
 ** Author:   Subhash Saliya
 ** Description: Get Data for GetJounalTypeSettingData
 ** Purpose:         
 ** Date:   08/08/2022    
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/08/2022   Subhash Saliya Created

     
 EXECUTE [GetJounalTypeSettingData] 1
**************************************************************/ 

CREATE   PROCEDURE [dbo].GetJounalTypeSettingData
	@masterCompanyId bigint = null
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				Select	
					jt.JournalTypeCode,
					jt.ID as JournalTypeID,
                    jt.JournalTypeName,
                    jts.ID,
					jts.IsEnforcePrint,
                    jts.MasterCompanyId,
                    jts.CreatedBy,
                    jts.UpdatedBy,
                    isnull(jts.UpdatedDate,GETUTCDATE()) as UpdatedDate,
                    isnull(jts.CreatedDate,GETUTCDATE()) as CreatedDate,
                    jts.IsActive,
                    jts.IsDeleted
                    
				FROM dbo.JournalType jt  WITH(NOLOCK)
				left join JournalTypeSetting jts   WITH(NOLOCK) on jt.ID=jts.JournalTypeID and jts.MasterCompanyId= @masterCompanyId
				WHERE  jt.IsDeleted = 0
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetJounalTypeSettingData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@masterCompanyId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH	
			            
END