
/*************************************************************           
 ** File:   [USP_ILS_ADDSendILSRFQ]           
 ** Author:  Rajesh Gami
 ** Description: This stored procedure is used to add ISL RFQ data into our database
 ** Purpose:         
 ** Date:   08/Feb/2024      
          
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------    ---------		--------------------------------          
    1   08/Feb/2024    Rajesh Gami    Created
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_ILS_ADDSendILSRFQ]
	@tbl_ILSRFQPartType ILSRFQPartType READONLY,
	@ThirdPartyRFQId BIGINT =NULL,
	@RFQId varchar(50) = NULL,
	@PortalRFQId varchar(60) = NULL,
	@Name VARCHAR(50) = NULL,
	@TypeId int = NULL,
	@IntegrationPortalId int = NULL,
	@StatusId int = NULL,
	@PriorityId int= NULL,
	@Priority VARCHAR(50) = NULL,
	@RequestedQty int= NULL,
	@QuoteWithinDays INT = NULL,
	@DeliverByDate DATETIME = NULL,
	@PreparedBy VARCHAR(50) = NULL,
	@AttachmentId BIGINT = NULL,
	@DeliverToAddress VARCHAR(MAX) = NULL,
	@BuyerComment VARCHAR(MAX) = NULL,
	@MasterCompanyId INT,
	@CreatedBy VARCHAR(200)
AS
BEGIN
	  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	  BEGIN TRANSACTION
			DECLARE @LatestThirdPartyRFQId bigint, @LatestILSRFQDetailId bigint,@ILSRFQDetailId bigint;	
			DECLARE @TypeName varchar(50) = (SELECT TOP 1 [Description] FROM DBO.IntegrationRFQType WITH(NOLOCK) WHERE IntegrationRFQTypeId = @TypeId);
			DECLARE @StatusName varchar(50) = (SELECT TOP 1 [Description] FROM DBO.IntegrationRFQStatus WITH(NOLOCK) WHERE IntegrationRFQStatusId = @StatusId)
			DECLARE @IntegrationPortal varchar(50) = (SELECT TOP 1 [Description] FROM DBO.IntegrationPortal WITH(NOLOCK) WHERE IntegrationPortalId = @IntegrationPortalId)
			SET @Priority = (SELECT TOP 1 [Description] FROM DBO.[Priority] WITH(NOLOCK) WHERE PriorityId = @PriorityId);


			IF(@ThirdPartyRFQId >0)
			BEGIN
				UPDATE [dbo].[ThirdPartyRFQ] SET [PortalRFQId] = UPPER(@PortalRFQId), Name = @Name,[IntegrationRFQStatusId] = @StatusId,[Status] = @StatusName
												 ,[UpdatedDate] = GETUTCDATE(),[UpdatedBy] = @CreatedBy WHERE ThirdPartyRFQId = @ThirdPartyRFQId
				UPDATE [dbo].[ILSRFQDetail] SET  [PriorityId] = @PriorityId, Priority = @Priority, QuoteWithinDays = @QuoteWithinDays, DeliverByDate = @DeliverByDate
												 ,PreparedBy = @PreparedBy ,DeliverToAddress = @DeliverToAddress, BuyerComment = @BuyerComment, UpdatedBy = @CreatedBy, UpdatedDate = GETUTCDATE()
												 WHERE ThirdPartyRFQId = @ThirdPartyRFQId
				set @ILSRFQDetailId = (SELECT TOP 1 ILSRFQDetailId FROM [dbo].[ILSRFQDetail] WHERE ThirdPartyRFQId = @ThirdPartyRFQId)
				UPDATE part set
						part.RequestedQty=uType.RequestedQty,
						part.UpdatedBy=@CreatedBy,
						part.UpdatedDate = GETUTCDATE(),
						part.IsEmail=  uType.IsEmail, part.IsFax = uType.IsFax
						FROM [dbo].[ILSRFQPart] part
						INNER JOIN @tbl_ILSRFQPartType uType
						ON part.ILSRFQPartId = uType.ILSRFQPartId
						WHERE part.ILSRFQPartId = uType.ILSRFQPartId AND  ISNULL(uType.ILSRFQPartId,0)  >0

			   /**** Insert Into the ISL RFQ Part Table If not inserted****/
				   INSERT INTO [dbo].[ILSRFQPart]
				   ([ILSRFQDetailId],[PartNumber],[AltPartNumber],[Exchange],[Description],[Qty],[RequestedQty],[Condition],[IsEmail],[IsFax]
				   ,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsDeleted],[IsActive])
				   SELECT @ILSRFQDetailId,PartNumber,AltPartNumber,Exchange,Description,Qty,RequestedQty,Condition,IsEmail,IsFax
				   ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE() ,0 ,1	  
				   FROM @tbl_ILSRFQPartType WHERE  ISNULL(ILSRFQPartId,0) = 0
			END
			ELSE
			BEGIN
				INSERT INTO [dbo].[ThirdPartyRFQ]
				   ([RFQId] ,[PortalRFQId],[Name],[IntegrationRFQTypeId],[TypeName],[IntegrationPortalId],[IntegrationPortal],[IntegrationRFQStatusId]
				   ,[Status],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsDeleted],[IsActive])
					VALUES
				   (UPPER(@RFQId),UPPER(@PortalRFQId),@Name,@TypeId,@TypeName,@IntegrationPortalId,@IntegrationPortal,@StatusId
				   ,@StatusName,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),0,1)

				   SET @LatestThirdPartyRFQId = SCOPE_IDENTITY();
				   /**** Insert data into the ILS RFQ Detail table *****/
				   INSERT INTO [dbo].[ILSRFQDetail]
					   ([ThirdPartyRFQId],[PriorityId],[Priority],[RequestedQty],[QuoteWithinDays],[DeliverByDate],[PreparedBy],[AttachmentId],[DeliverToAddress] ,[BuyerComment]
					   ,[MasterCompanyId] ,[CreatedBy] ,[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,[IsDeleted]  ,[IsActive])
				   VALUES
					   (@LatestThirdPartyRFQId,@PriorityId,@Priority,@RequestedQty,@QuoteWithinDays ,@DeliverByDate ,@PreparedBy ,@AttachmentId ,@DeliverToAddress ,@BuyerComment
					   ,@MasterCompanyId ,@CreatedBy ,@CreatedBy ,GETUTCDATE() ,GETUTCDATE() ,0 ,1)
			
				   SET @LatestILSRFQDetailId = SCOPE_IDENTITY();


				   /**** Insert Into the ISL RFQ Part Table ****/
				   INSERT INTO [dbo].[ILSRFQPart]
				   ([ILSRFQDetailId],[PartNumber],[AltPartNumber],[Exchange],[Description],[Qty],[RequestedQty],[Condition],[IsEmail],[IsFax]
				   ,[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsDeleted],[IsActive])
				   SELECT @LatestILSRFQDetailId,PartNumber,AltPartNumber,Exchange,Description,Qty,RequestedQty,Condition,IsEmail,IsFax
				   ,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE() ,0 ,1	  
				   FROM @tbl_ILSRFQPartType
			END
			

	  COMMIT  TRANSACTION
    END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_ILS_ADDSendILSRFQ' 
            , @ProcedureParameters VARCHAR(3000) = '@RFQId = ''' + CAST(ISNULL(@RFQId, '') as varchar(100)) + ''',
														@PortalRFQId = ' + ISNULL(@PortalRFQId,'') + ', 
														@Name = ' + ISNULL(@Name,'') + ', 
														@TypeId = ' + ISNULL(@TypeId,'') + ', 
														@IntegrationPortalId = ' + ISNULL(@IntegrationPortalId,'') + ', 
														@StatusId = ' + ISNULL(@StatusId,'') + ', 
														@Priority = ' + ISNULL(@Priority,'') + ', 
														@QuoteWithinDays = ' + ISNULL(@QuoteWithinDays,'') + ', 
														@DeliverByDate = ' + ISNULL(@DeliverByDate,'') + ', 
														@PreparedBy = ' + ISNULL(@PreparedBy,'') + ', 
														@AttachmentId = ' + ISNULL(@AttachmentId,'') + ', 
														@DeliverToAddress = ' + ISNULL(@DeliverToAddress,'') + ', 
														@BuyerComment = ' + ISNULL(@BuyerComment,'') + ', 
														@MasterCompanyId = ' + ISNULL(@MasterCompanyId,'') + ', 
														@CreatedBy = ' + ISNULL(@CreatedBy,'') + ''
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