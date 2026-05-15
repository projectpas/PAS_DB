/*************************************************************               
 ** File:   [USP_CheckAircraftTailNumberExists]               
 ** Author:  AMIT GHEDIYA    
 ** Description:  This Store Procedure use to check Aircraft TailNumber is exists.   
 ** Purpose:             
 ** Date:   14/05/2026          
              
 ** RETURN VALUE:               
 **********************************************************               
 ** check customer emial & phone exists.             
 **********************************************************               
 ** PR   Date			Author			Change Description                
 ** --   --------		-------			--------------------------------              
    1    14/05/2026  	AMIT GHEDIYA	Created     
 
 EXEC [USP_CheckAircraftTailNumberExists] 'VT-BCL'
********************************************************************/ 
CREATE     PROCEDURE [dbo].[USP_CheckAircraftTailNumberExists]
	@TailNumber   VARCHAR(50)     = NULL
AS
BEGIN
		BEGIN TRY
			
			DECLARE @ReturnStatus INT = 0,
					@ReturnMsg VARCHAR(150) = 'Tail Number does not exist in the system.';
			
			IF EXISTS(SELECT AircraftRegistryId FROM dbo.AircraftRegistryHeader WITH(NOLOCK) WHERE UPPER(LTRIM(RTRIM(TailNum))) = UPPER(LTRIM(RTRIM(@TailNumber))))
			BEGIN
				 SET @ReturnStatus = 1;
				 SET @ReturnMsg = '';
			END
			ELSE
			BEGIN
				SET @ReturnStatus = -1;
				 SET @ReturnMsg = @ReturnMsg;
			END

			SELECT @ReturnStatus AS Status, @ReturnMsg AS Msg;

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CheckAircraftTailNumberExists' 
              , @ProcedureParameters VARCHAR(3000)  = '@TailNumber = '''+ ISNULL(@TailNumber, '') + ''
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