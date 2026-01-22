/*************************************************************           
 ** File:   [dbo].[USP_CreateShippingViaFromAddressTab]            
 ** Author:   Amit Ghediya
 ** Description: This stored procedure is used save ship via from address tab
 ** Purpose:         
 ** Date:   18/04/2025       
         
 ** RETURN VALUE:              
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    18/04/2025   Amit Ghediya		Created
     
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateShippingViaFromAddressTab]    
(    
  @ShippingViaName NVARCHAR(400),
  @MasterCompanyId INT,
  @CreatedBy VARCHAR(256),
  @UpdatedBy VARCHAR(256)
)    
AS    
BEGIN   
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
	BEGIN TRANSACTION 
			DECLARE @ShippingViaId BIGINT = 0;


			--Insert new ShippingVia from Address tab.
			INSERT INTO [dbo].[ShippingVia]([Name],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])
									 VALUES(@ShippingViaName,NULL,@MasterCompanyId,@CreatedBy,@UpdatedBy,GETUTCDATE(),GETUTCDATE(),1,0);

			SET @ShippingViaId = SCOPE_IDENTITY();

			SELECT @ShippingViaId As ShippingViaId;

		COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CreateShippingViaFromAddressTab' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ShippingViaName, '') + ''',													   
													   @Parameter2 = ' + ISNULL(CAST(@MasterCompanyId AS varchar(10)) ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN
		END CATCH
END