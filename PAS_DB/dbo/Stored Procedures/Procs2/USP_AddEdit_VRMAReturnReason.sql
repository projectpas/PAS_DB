/*************************************************************             
 ** File:   [USP_AddEdit_VRMAReturnReason]             
 ** Author:   Devendra Shekh    
 ** Description: to add / edit vendor rma return reason 
 ** Purpose:            
 ** Date:   11-July-2022        
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date				  Author			 Change Description              
 ** --   --------			 -------			 --------------------------------            
    1    11-July-2022		Devendra Shekh		 Created  

**************************************************************/  
Create   PROCEDURE [dbo].[USP_AddEdit_VRMAReturnReason]
@VendorRMAReturnReasonId bigint,
@Reason varchar(256),
@Memo varchar(1000) = NULL,
@CreatedBy varchar(50),
@UpdatedBy  varchar(50),
@MasterCompanyId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  

			IF(@VendorRMAReturnReasonId = 0)
			BEGIN
       			INSERT INTO [dbo].[VendorRMAReturnReason] ([Reason], [Memo], [MasterCompanyId], [CreatedBy], [CreatedDate],[UpdatedBy] ,[UpdatedDate] ,[IsActive] ,[IsDeleted])
				VALUES(@Reason , @Memo, @MasterCompanyId, @CreatedBy ,GETUTCDATE() , @CreatedBy ,GETUTCDATE() ,1 ,0)
			END
			ELSE
			BEGIN

			    UPDATE [dbo].[VendorRMAReturnReason]
                SET [Reason] = @Reason
					,[Memo] = @Memo
					,[UpdatedBy] = @CreatedBy
					,[UpdatedDate] = GETUTCDATE()
              WHERE VendorRMAReturnReasonId= @VendorRMAReturnReasonId
			END			
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_AddEdit_VRMAReturnReason' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@VendorRMAReturnReasonId, '') + ''
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