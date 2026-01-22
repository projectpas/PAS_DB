
/*************************************************************           
 ** File:   [UpdateReceivingCustomerColumnsWithId]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used ID Column Values for Labor OH Settings    
 ** Purpose:         
 ** Date:   12/30/2020        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/20/2020   Hemant Saliya Created
     
--EXEC [UpdateLaborOHSettingsColumnsWithId] 5
**************************************************************/

CREATE PROCEDURE [dbo].[UpdateLaborOHSettingsColumnsWithId]
	@LaborOHSettingsId int
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ManagmnetStructureId as bigInt

	SELECT @ManagmnetStructureId = ManagementStructureId FROM [dbo].[LaborOHSettings] WITH (NOLOCK) WHERE LaborOHSettingsId = @LaborOHSettingsId

	DECLARE @Level1 as varchar(200)
	DECLARE @Level2 as varchar(200)
	DECLARE @Level3 as varchar(200)
	DECLARE @Level4 as varchar(200)

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
			EXEC dbo.GetMSNameandCode @ManagmnetStructureId,
			 @Level1 = @Level1 OUTPUT,
			 @Level2 = @Level2 OUTPUT,
			 @Level3 = @Level3 OUTPUT,
			 @Level4 = @Level4 OUTPUT

			Update LOS SET 
				LOS.Level1 = @Level1,
				LOS.Level2 = @Level2,
				LOS.Level3 = @Level3,
				LOS.Level4 = @Level4
				FROM [dbo].[LaborOHSettings] LOS
				WHERE LOS.LaborOHSettingsId = @LaborOHSettingsId
			END
		COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'UpdateLaborOHSettingsColumnsWithId' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@LaborOHSettingsId, '') + ''
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