/*************************************************************           
 ** File:   [UpdateAddressDetails]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used Update address details.    
 ** Purpose:      
 ** Date:   05/12/2023        
          
 ** PARAMETERS:           
 @AssetRecordId BIGINT
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/12/2023   Vishal Suthar Created
     
**************************************************************/
CREATE   PROCEDURE [dbo].[UpdateAddressDetails]
	@AddressId bigint,
	@Line1 VARCHAR(50),
	@Line2 VARCHAR(50),
	@Line3 VARCHAR(50),
	@PostalCode VARCHAR(20),
	@StateOrProvince VARCHAR(50),
	@City VARCHAR(20),
	@CountryId SMALLINT,
	@CreatedBy VARCHAR(256),
	@CreatedDate datetime2(7),
	@UpdatedBy VARCHAR(256),
	@UpdatedDate datetime2(7)
AS
BEGIN
	   SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	   SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN  
					Update A SET 
						A.Line1 = @Line1,
						A.Line2 = @Line2,
						A.Line3 = @Line3,
						A.PostalCode = @PostalCode,
						A.StateOrProvince = @StateOrProvince,
						A.City = @City,
						A.CountryId = @CountryId,
						A.CreatedBy = @CreatedBy,
						A.CreatedDate = @CreatedDate,
						A.UpdatedBy = @UpdatedBy,
						A.UpdatedDate = @UpdatedDate
					FROM [dbo].[Address] A WITH (NOLOCK)
					WHERE A.AddressId = @AddressId
				END
			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateAddressDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@AddressId, '') + ''
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