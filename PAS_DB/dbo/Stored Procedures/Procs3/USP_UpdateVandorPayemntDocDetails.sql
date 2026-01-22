/*************************************************************           
 ** File:   [USP_UpdateVandorPayemntDocDetails]           
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used UpdateVandorPayemntDocDetails
 ** Purpose:         
 ** Date:   29/03/2024      
          
 ** PARAMETERS:           
 @ReadyToPayId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    29/03/2024   AMIT GHEDIYA		Created


	EXEC [USP_UpdateVandorPayemntDocDetails] 120
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_UpdateVandorPayemntDocDetails]  
@ReadyToPayId BIGINT = NULL
AS  
BEGIN  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON;  
	BEGIN TRY  

			DECLARE @readyPayId BIGINT,
					@ReadyToPayDetailsId BIGINT,
					@ReceivingReconciliationId BIGINT,
					@NonPOInvoiceId BIGINT,
					@MasterLoopID INT,
					@ChildMasterLoopID INT,
					@VPModuleID BIGINT,
					@RRModuleID BIGINT,
					@NPModuleID BIGINT,
					@ModuleID BIGINT,
					@AttachmentId BIGINT,
					@CommonDocumentDetailId BIGINT,
					@AttachmentDetailId BIGINT,
					@ChildAttachmentId BIGINT,
					@ReferenceId BIGINT;

			SELECT @VPModuleID = [AttachmentModuleId] FROM [DBO].[AttachmentModule] WITH(NOLOCK) WHERE [Name] = 'VendorPayment';
			SELECT @RRModuleID = [AttachmentModuleId] FROM [DBO].[AttachmentModule] WITH(NOLOCK) WHERE [Name] = 'ReceivingReconciliation';
			SELECT @NPModuleID = [AttachmentModuleId] FROM [DBO].[AttachmentModule] WITH(NOLOCK) WHERE [Name] = 'NonPOInvoice';
			SELECT @readyPayId = [ReadyToPayId] FROM [DBO].[VendorReadyToPayHeader] WITH(NOLOCK) WHERE [ReadyToPayId] = @ReadyToPayId;

			--Get FROM DOC Table
			IF OBJECT_ID(N'tempdb..#tmpVendorReadyToPayDetails') IS NOT NULL
			BEGIN
				DROP TABLE #tmpVendorReadyToPayDetails
			END
					  	  
			CREATE TABLE #tmpVendorReadyToPayDetails
			(
				ID BIGINT NOT NULL IDENTITY, 
				ReadyToPayDetailsId BIGINT NULL,
				ReadyToPayId BIGINT NULL,
				ReceivingReconciliationId BIGINT NULL,
				NonPOInvoiceId BIGINT NULL
			)   
			
			-- GET FROM AttachmentDetails Table
			IF OBJECT_ID(N'tempdb..#tmpAttachmentDetails') IS NOT NULL
			BEGIN
				DROP TABLE #tmpAttachmentDetails
			END
					  	  
			CREATE TABLE #tmpAttachmentDetails
			(
				ChildID BIGINT NOT NULL IDENTITY, 
				AttachmentDetailId BIGINT NULL,
				AttachmentId BIGINT NULL
			)  

			IF(@readyPayId > 0)
			BEGIN
				
				INSERT INTO #tmpVendorReadyToPayDetails (ReadyToPayDetailsId,ReadyToPayId,ReceivingReconciliationId,NonPOInvoiceId) 
						SELECT ReadyToPayDetailsId,ReadyToPayId,ReceivingReconciliationId,NonPOInvoiceId
				FROM [DBO].[VendorReadyToPayDetails] VRPD WITH(NOLOCK) 
				WHERE VRPD.ReadyToPayId = @ReadyToPayId;

				SELECT  @MasterLoopID = MAX(ID) FROM #tmpVendorReadyToPayDetails;

				WHILE(@MasterLoopID > 0)
				BEGIN
					 SELECT @ReceivingReconciliationId = ReceivingReconciliationId,
							@ReadyToPayDetailsId = ReadyToPayDetailsId,
							@NonPOInvoiceId = NonPOInvoiceId
					 FROM #tmpVendorReadyToPayDetails WITH(NOLOCK) WHERE [ID] = @MasterLoopID;

					 IF(@ReceivingReconciliationId = 0)
					 BEGIN
						  SET @ReferenceId = @NonPOInvoiceId;
						  SET @ModuleID = @NPModuleID;
					 END
					 ELSE
					 BEGIN
						  SET @ReferenceId = @ReceivingReconciliationId;
						  SET @ModuleID = @RRModuleID;
					 END

					 IF(@ReferenceId > 0)
					 BEGIN
						 --CommonDocumentDetails
						 INSERT INTO [DBO].[CommonDocumentDetails] (ModuleId,ReferenceId,AttachmentId,DocName,DocMemo,DocDescription,MasterCompanyId,
															CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,DocumentTypeId,
															ExpirationDate,ReferenceIndex,ModuleType)
												  SELECT @VPModuleID,@ReadyToPayDetailsId,AttachmentId,DocName,DocMemo,DocDescription,MasterCompanyId,
															CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,DocumentTypeId,
															ExpirationDate,ReferenceIndex,ModuleType 
								FROM [DBO].[CommonDocumentDetails] WITH(NOLOCK) 
								WHERE ReferenceId = @ReferenceId AND ModuleId = @ModuleID;
					 
						 SET @CommonDocumentDetailId = SCOPE_IDENTITY();

						 SELECT @AttachmentId = AttachmentId FROM [DBO].[CommonDocumentDetails] WITH(NOLOCK) 
							   WHERE ReferenceId = @ReferenceId;

						 -- Attachment
						 INSERT INTO [DBO].[Attachment] (ModuleId,ReferenceId,MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,
														 UpdatedDate,IsActive,IsDeleted)
									 SELECT @VPModuleID,@ReadyToPayDetailsId,MasterCompanyId,CreatedBy,CreatedDate,UpdatedBy,
														 UpdatedDate,IsActive,IsDeleted
							   FROM [DBO].[Attachment] WITH(NOLOCK) 
							   WHERE AttachmentId = @AttachmentId;

						SET @ChildAttachmentId = SCOPE_IDENTITY();

						-- AttachmentDetails
						INSERT INTO #tmpAttachmentDetails (AttachmentDetailId,AttachmentId) 
													SELECT AttachmentDetailId,AttachmentId
									FROM [DBO].[AttachmentDetails] ATD WITH(NOLOCK)
									WHERE ATD.AttachmentId = @AttachmentId;

						SELECT  @ChildMasterLoopID = MAX(ChildID) FROM #tmpAttachmentDetails;
					 
						WHILE(@ChildMasterLoopID > 0)
						BEGIN
							 SELECT @AttachmentDetailId = AttachmentDetailId FROM #tmpAttachmentDetails WITH(NOLOCK) WHERE [ChildID] = @ChildMasterLoopID;

							 INSERT INTO [DBO].[AttachmentDetails] (AttachmentId,FileName,Description,Link,FileFormat,FileSize,
															FileType,CreatedDate,UpdatedDate,CreatedBy,UpdatedBy,IsActive,
															IsDeleted,Name,Memo,TypeId) 
													SELECT @ChildAttachmentId,FileName,Description,Link,FileFormat,FileSize,
															FileType,CreatedDate,UpdatedDate,CreatedBy,UpdatedBy,IsActive,
															IsDeleted,Name,Memo,TypeId
									FROM [DBO].[AttachmentDetails] ATD WITH(NOLOCK)
									WHERE ATD.AttachmentDetailId = @AttachmentDetailId;
						
							SET @ChildMasterLoopID = @ChildMasterLoopID -1;
						END

						--Update AttachmentId
						UPDATE [DBO].[CommonDocumentDetails] SET AttachmentId = @ChildAttachmentId WHERE CommonDocumentDetailId = @CommonDocumentDetailId;
					 END
					 
					SET @MasterLoopID = @MasterLoopID - 1;
				END
			END

	END TRY      
	BEGIN CATCH        
	IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateVandorPayemntDocDetails'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ReadyToPayId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END