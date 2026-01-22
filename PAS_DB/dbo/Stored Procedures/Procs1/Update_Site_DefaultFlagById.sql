/*************************************************************           
 ** File:   [Update_Site_DefaultFlagById]           
 ** Author:  
 ** Description: This stored procedure is used to update site default flag by id
 ** Purpose:         
 ** Date:       
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
	1    25/10/2023   Devendra Shekh	 created

**************************************************************/
CREATE   PROCEDURE [dbo].[Update_Site_DefaultFlagById]
@SiteId BIGINT = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY

	SET @SiteId = ISNULL(@SiteId, 0)

	IF(@SiteId = 0)
	BEGIN
		UPDATE [dbo].[Site]
		SET IsDefault = 0
		WHERE IsDefault = 1
	END
	ELSE
	BEGIN
		UPDATE [dbo].[Site]
		SET IsDefault = 0
		WHERE IsDefault = 1 AND [SiteId] != @SiteId
	END

    END TRY
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'Update_Site_DefaultFlagById' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SiteId, '') + ''
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