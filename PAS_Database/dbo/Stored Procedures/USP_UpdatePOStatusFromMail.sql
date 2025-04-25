/*************************************************************             
 ** File:   [USP_UpdatePOStatusFromMail]            
 ** Author:   Amit Ghediya    
 ** Description: to update the po header status from if enforce approve not available.
 ** Purpose:           
 ** Date:   25-04-2025    
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 **	 S NO   Date			 Author				Change Description              
 **	 --   --------			-------				--------------------------------            
	1	 25-04-2025			Amit Ghediya		created  
       
EXECUTE   [dbo].[USP_UpdatePOStatusFromMail] 6760,'admin'  
*************************************************************/      
CREATE     PROCEDURE [dbo].[USP_UpdatePOStatusFromMail]
	@PurchaseOrderId BIGINT,
	@MasterCompanyId BIGINT,
	@UpdatedBy VARCHAR(100)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				IF(@PurchaseOrderId > 0)
				BEGIN
					DECLARE @StatusId INT,
							@StatusName VARCHAR(100),
							@IsEnforceApproval BIT,
							@IsAutoUpdatePOStatus BIT;

					SELECT @StatusId = [POStatusId], @StatusName = [Status] FROM [dbo].[POStatus] WITH(NOLOCK) WHERE UPPER([Status]) = UPPER('Fulfilling');

					SELECT @IsEnforceApproval = [IsEnforceApproval], @IsAutoUpdatePOStatus = [IsAutoUpdatePOStatus] FROM [dbo].[PurchaseOrderSettingMaster] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;
			
					IF(ISNULL(@IsEnforceApproval,0) = 0 AND ISNULL(@IsAutoUpdatePOStatus,0) = 1)
					BEGIN
						 UPDATE [dbo].[PurchaseOrder]  
						 SET StatusId = @StatusId 
						 , [Status] = @StatusName
						 , [UpdatedBy] = @UpdatedBy 
						 , [UpdatedDate] = GETUTCDATE()
						 WHERE [PurchaseOrderId] = @PurchaseOrderId;
					END
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
              , @AdhocComments     VARCHAR(150)    = '[USP_UpdatePOStatusFromMail]'               
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PurchaseOrderId, '') AS VARCHAR(100))
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