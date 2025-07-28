/*************************************************************           
 ** File:  [IsExistsInventoryPartForIntegration]  
 ** Author:   Amit Ghediya
 ** Description: Retrieve part is exist or not
 ** Purpose:         
 ** Date:   09-07-2025
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR     Date         Author		     	Change Description            
 ** --    --------     -------			-------------------------------          
    1     09-07-2025   Amit Ghediya		Created
	2     25-07-2025   Amit Ghediya		Added MasterCompanyId

EXEC [IsExistsInventoryPartForIntegration]  'A100,5360002916111,Part9,part7'

**************************************************************/ 

CREATE    PROCEDURE [dbo].[IsExistsInventoryPartForIntegration]
	@PartString NVARCHAR(MAX) = NULL,
	@MasterCompanyId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY 

		DECLARE @AllowUser INT = 0;

		IF EXISTS(SELECT TOP 1 ItemMasterId FROM [DBO].[ItemMaster] WITH(NOLOCK) WHERE [IsActive] = 1 AND [IsDeleted] = 0 AND [MasterCompanyId] = @MasterCompanyId AND [partnumber] IN(SELECT item FROM SplitString(@PartString,',')))
		BEGIN
			 SET @AllowUser = 1;
		END
		ELSE
		BEGIN
			 SET @AllowUser = 0;
		END

		SELECT @AllowUser AS AllowUser;

	END TRY
	BEGIN CATCH
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = '[IsExistsInventoryPartForIntegration]' 
            , @ProcedureParameters VARCHAR(3000)  = ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName			= @DatabaseName
                    , @AdhocComments			= @AdhocComments
                    , @ProcedureParameters		= @ProcedureParameters
                    , @ApplicationName			=  @ApplicationName
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
    END CATCH 
END