
/*********************           
 ** File:   [USP_GetUserTypePOAddress]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Address Type for Purchage Order Addressed    
 ** Purpose:         
 ** Date:   09/23/2020        
          
 ** PARAMETERS:           
 @AddressType varchar(60)   
         
 ** RETURN VALUE:           
  
 **********************           
  ** Change History           
 **********************           
 ** PR   Date         Author  	Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/23/2020   Hemant Saliya Created
     
 EXECUTE [USP_GetUserTypePOAddress] 'po' 
**********************/

CREATE PROCEDURE [dbo].[USP_GetUserTypePOAddress] (@AddressType varchar(60))
AS
BEGIN

  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

  BEGIN TRY

    IF (@AddressType = 'PO'
      OR @AddressType = 'SOQ'
      OR @AddressType = 'SO'
      OR @AddressType = 'RO'
      OR @AddressType = 'EQ'
      OR @AddressType = 'ExchSO'
	  OR @AddressType = 'VRFQPO'
	  OR @AddressType = 'VRFQRO'	  
	  )
    BEGIN
      SELECT
        ModuleName,
        ModuleId
      FROM dbo.Module WITH (NOLOCK)
      WHERE ModuleId IN (1, 2, 9)
    END
    ELSE
    BEGIN
      SELECT
        *
      FROM dbo.Module WITH (NOLOCK)
    END
  END TRY

  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[USP_GetUserTypePOAddress]',
            @ProcedureParameters varchar(3000) = '@Parameter1= ''' + CAST(ISNULL(@AddressType, '') AS varchar(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

    RETURN (1);
  END CATCH
END