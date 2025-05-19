/*************************************************************           
 ** File:  [USP_GetContactsByVendorId]       
 ** Author:   Ayushi Patel
 ** Description: Get Contacts By VendorId
 ** Purpose:         
 ** Date:  19/05/2025 
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1	 19-MAY-2025   AYUSHI PATEL 		Created
	exec [USP_GetContactsByVendorId] 4784
**************************************************************/ 
CREATE PROCEDURE [dbo].[USP_GetContactsByVendorId]
    @VendorId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY
        SELECT 
            c.ContactId,
            c.FirstName,
            c.LastName
        FROM dbo.Contact c WITH (NOLOCK) 
        INNER JOIN dbo.VendorContact vc WITH (NOLOCK) ON c.ContactId = vc.ContactId
        WHERE vc.VendorId = @VendorId
          AND ISNULL(vc.IsDeleted, 0) = 0
    END TRY
    BEGIN CATCH      
	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetContactsByVendorId'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = '', '
			,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);           
	END CATCH
END